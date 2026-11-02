"""Convert RC+ RealPos exports; retain timestamps and every original sample.

These are executed VIRTUAL controller observations, never physical encoder data.
No resampling, gap filling, or invented contact measurements is performed.
"""
from pathlib import Path
import argparse
import csv
import json
import shutil
import numpy as np
from scipy.spatial.transform import Rotation

FIELDS = ['time_s', *[f'j{i}_rad' for i in range(1, 7)],
          'tcp_x_m', 'tcp_y_m', 'tcp_z_m', 'qw', 'qx', 'qy', 'qz']
WORLD_FROM_ROBOT = np.array([[0., -1., 0.], [1., 0., 0.], [0., 0., 1.]])
FLANGE_FROM_HANDLE = [[0, 1, 0, 0], [1, 0, 0, -.05],
                      [0, 0, -1, 0], [0, 0, 0, 1]]


def export(source, dest):
    dest.mkdir(parents=True, exist_ok=True)
    events = {}
    ep = source / 'tb_events.csv'
    if ep.exists() and ep.stat().st_size:
        shutil.copy2(ep, dest / ep.name)
        for row in csv.DictReader(ep.open()):
            events.setdefault(row['path_id'], []).append(
                {'time_s': float(row['time_s']), 'event': row['event'], 'rep':int(row.get('rep',1))})
    reports = []
    source_program=(source/'Main.prg').read_text(errors='replace') if (source/'Main.prg').exists() else ''
    joint_source='Agl(j), unwrapped' if 'Trim$(Str$(Agl(j)))' in source_program else 'PAgl(RealPos), unwrapped'
    for path in sorted(source.glob('*_RCPLUS_RAW.csv')):
        if not path.stat().st_size:
            continue  # RC+ keeps an active file buffered until it closes.
        rows = list(csv.DictReader(path.open()))
        a = np.array([[float(r[k]) for k in rows[0]] for r in rows])
        if len(a) < 2 or not np.isfinite(a).all():
            raise ValueError(f'Invalid or incomplete data: {path}')
        t = a[:, 0]
        dt = np.diff(t)
        if (dt <= 0).any():
            raise ValueError(f'Non-increasing timestamps: {path}')
        # Epson U,V,W are rotations about Z,Y,X respectively.
        rb = Rotation.from_euler('ZYX', a[:, 10:13], degrees=True).as_matrix()
        rw = WORLD_FROM_ROBOT @ rb
        xyzw = Rotation.from_matrix(rw).as_quat()
        for i in range(1, len(xyzw)):
            if xyzw[i-1] @ xyzw[i] < 0:
                xyzw[i] *= -1
        p = a[:, 7:10] @ WORLD_FROM_ROBOT.T / 1000
        # Conservative racket proxy relative to sweet spot: handle extends to
        # x=-0.55 m; head reaches x=+0.18 m and y=+/-0.145 m, 30 mm thick.
        proxy=np.array([[x,y,z] for x in (-.55,.18) for y in (-.145,.145) for z in (-.015,.015)])
        swept=(rw @ proxy.T).transpose(0,2,1)+p[:,None,:]
        joints = np.unwrap(np.deg2rad(a[:, 1:7]), axis=0)
        output = np.column_stack((t, joints, p, xyzw[:, 3], xyzw[:, :3]))
        name = path.name.replace('_RCPLUS_RAW', '')
        with (dest / name).open('w', newline='') as f:
            w = csv.writer(f)
            w.writerow(FIELDS)
            w.writerows(output)
        raw = dest / 'raw'
        raw.mkdir(exist_ok=True)
        shutil.copy2(path, raw / path.name)
        omega = Rotation.from_matrix(rb[:-1].transpose(0, 2, 1) @ rb[1:]).magnitude() / dt
        # Virtual position values update every 2 ms while Tmr has 1 ms precision.
        # A one-sample derivative can therefore double an apparent peak. Keep
        # that raw estimate, and use a 20 ms window for the reported estimate.
        left=np.arange(len(t)-1)
        right=np.minimum(np.searchsorted(t,t[:-1]+.02),len(t)-1)
        wd=t[right]-t[left]
        speed20=np.linalg.norm(p[right]-p[left],axis=1)/wd
        omega20=Rotation.from_matrix(rb[left].transpose(0,2,1)@rb[right]).magnitude()/wd
        path_id = name.split('_rep')[0]
        repetition=int(name.split('_rep')[1].split('_')[0])
        run_events=[e for e in events.get(path_id,[]) if e['rep']==repetition]
        report = dict(path_id=path_id, file=name, source='RC+ 7.5.4A virtual controller RealPos',
                      physical_measurement=False, joint_source=joint_source,
                      sample_count=len(a), duration_s=float(t[-1]-t[0]),
                      mean_hz=float(1/np.mean(dt)), max_gap_s=float(max(dt)),
                      gaps_over_10ms=int(np.sum(dt > .0100001)),
                      peak_tcp_speed_mps=float(max(speed20)),
                      peak_orientation_deg_s=float(np.rad2deg(max(omega20))),
                      speed_estimator_window_s=.02,
                      instantaneous_tcp_difference_peak_mps=float(max(np.linalg.norm(np.diff(p, axis=0), axis=1)/dt)),
                      instantaneous_orientation_difference_peak_deg_s=float(np.rad2deg(max(omega))),
                      tcp_world_min_m=p.min(axis=0).tolist(), tcp_world_max_m=p.max(axis=0).tolist(),
                      racket_proxy_world_min_m=swept.min(axis=(0,1)).tolist(),
                      racket_proxy_world_max_m=swept.max(axis=(0,1)).tolist(),
                      racket_proxy_green_half_plane=bool(swept[:,:,0].min()>=0),
                      repetition=repetition,events=run_events,
                      timestamp_resolution_s=.001,
                      timestamp_note='Read before serial pose/joint formatting; sampling is not atomic.',
                      flange_to_handle_assumed=FLANGE_FROM_HANDLE,
                      world_from_robot= WORLD_FROM_ROBOT.tolist(),
                      swept_volume_certified=False)
        event_times={e['event']:e['time_s'] for e in run_events}
        if 'forward_arc_start' in event_times and 'follow_through_end' in event_times:
            active=(t[left]>=event_times['forward_arc_start']) & (t[right]<=event_times['follow_through_end'])
            if active.any():
                report['primary_arc_peak_tcp_mps']=float(speed20[active].max())
                report['primary_arc_peak_deg_s']=float(np.rad2deg(omega20[active].max()))
                report['primary_arc_world_x_span_m']=float(np.ptp(p[left[active],0]))
                report['primary_arc_joint_span_deg']=np.rad2deg(np.ptp(joints[left[active]],axis=0)).tolist()
        (dest / name.replace('.csv', '.json')).write_text(json.dumps(report, indent=2))
        reports.append(report)
    (dest / 'summary.json').write_text(json.dumps(reports, indent=2))
    (dest / 'flange_to_handle.json').write_text(json.dumps({
        'translation_units': 'm', 'matrix': FLANGE_FROM_HANDLE,
        'SWEETSPOT_OFFSET_M': .5, 'source': 'User-supplied 0.5 m estimate and provisional simulator mount',
        'measured': False}, indent=2))
    print(f'Exported {len(reports)} closed virtual trajectory files to {dest}')
    for r in reports:
        print(f"{r['path_id']}: {r['mean_hz']:.1f} Hz, max gap {r['max_gap_s']*1000:.1f} ms")


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('source', type=Path)
    p.add_argument('--dest', type=Path, default=Path('robot/recordings/native'))
    args = p.parse_args()
    export(args.source, args.dest)
