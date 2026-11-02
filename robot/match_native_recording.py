"""Match executed CSV traces to the native RC+ joint playback file.

The local RC+ 7.5 C8 file was inspected: 896-byte header, 9 float32 joint
columns, and a float64 sampling interval at offset 880. Fail if this changes.
This reads an artifact; it neither controls RC+ nor generates robot motion.
"""
from pathlib import Path
import argparse
import csv
import json
import struct
import numpy as np
from scipy.signal import correlate


def match(project, dest):
    binary=(project/'DayOneNative02_01.jpos').read_bytes()
    dt=struct.unpack_from('<d',binary,880)[0]
    if binary[4:12] != b'C8-A901S' or abs(dt-.002)>1e-8 or (len(binary)-896)%36:
        raise ValueError('Unrecognized or still-open native playback format')
    joint=np.frombuffer(binary[896:],dtype='<f4').reshape(-1,9)[:,:6].astype(float)
    if not np.isfinite(joint).all() or np.abs(joint).max()>1000:
        raise ValueError('Invalid native joint data')
    ev={}
    for r in csv.DictReader((project/'tb_events.csv').open()):
        ev.setdefault(r['path_id'],{})[r['event']]=float(r['time_s'])
    specs=json.loads(Path('robot/paths.json').read_text())
    sample_dt=.01
    nq=joint[::5]
    earliest=0
    timeline=[]
    for spec in specs:
        name=spec['path_id']
        path=project/(name+'_rep01_E35E_RCPLUS_RAW.csv')
        a=np.loadtxt(path,delimiter=',',skiprows=1)
        tt=np.arange(.05,a[-1,0]-.02,sample_dt)
        template=np.column_stack([np.interp(tt,a[:,0],a[:,i]) for i in range(1,7)])
        n=len(template)
        # Every case starts after the previous case and a short home transit.
        # Bound the search so identical later air/tap arcs cannot steal a match.
        search=nq[earliest:min(len(nq),earliest+int(60/sample_dt)+n)]
        if len(search)<n:
            raise ValueError('Native recording ends before '+name)
        norm=np.r_[0,np.cumsum(np.sum(search*search,axis=1))]
        scores=norm[n:]-norm[:-n]+np.sum(template*template)
        for j in range(6):
            scores-=2*correlate(search[:,j],template[:,j],mode='valid',method='fft')
        ix=int(np.argmin(scores))+earliest
        rough=ix*sample_dt-tt[0]
        # Refine to the native 2 ms sample grid around the coarse match.
        best=None
        for offset in np.arange(rough-.014,rough+.0141,.001):
            native_index=np.rint((offset+tt)/dt).astype(int)
            if native_index.min()<0 or native_index.max()>=len(joint):continue
            diff=joint[native_index]-template
            rms=float(np.sqrt(np.mean(diff*diff)))
            if best is None or rms<best[0]:best=(rms,offset,float(np.max(abs(diff))))
        rms,offset,max_error=best
        if rms>1.0:
            raise ValueError(f'Unreliable alignment for {name}: {rms:.3f} deg RMS')
        end=offset+a[-1,0]
        earliest=max(earliest,int((end-.05)/sample_dt))
        events=ev[name]
        timeline.append(dict(path_id=name,shot_type=spec['shot_type'],
                             intended_contact=spec['intended_contact'],
                             recording_start_s=round(float(offset),4),
                             sync_command_s=round(float(offset+events['sync_command']),4),
                             path_start_s=round(float(offset+events['path_start_command']),4),
                             end_s=round(float(end),4),
                             alignment_rms_deg=rms,alignment_max_deg=max_error))
        print(name,round(float(offset),3),'RMS deg',round(rms,4))
    dest.mkdir(parents=True,exist_ok=True)
    (dest/'timeline.json').write_text(json.dumps(timeline,indent=2))
    (dest/'native_recording_metadata.json').write_text(json.dumps(dict(
        source_file='DayOneNative02_01.jpos',sample_interval_s=dt,
        sample_count=len(joint),duration_s=(len(joint)-1)*dt,
        observed_format='RC+ 7.5 C8: 896-byte header followed by 9 little-endian float32 angles per sample',
        match_method='All six executed joint traces, chronological full-path template correlation, refined at 1 ms',
        physical_measurement=False),indent=2))


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('project',type=Path)
    p.add_argument('--dest',type=Path,default=Path('robot/recordings/native'))
    args=p.parse_args();match(args.project,args.dest)
