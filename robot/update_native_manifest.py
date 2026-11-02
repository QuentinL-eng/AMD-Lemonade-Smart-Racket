"""Describe the native paths; keep command bounds distinct from measured peaks."""
from pathlib import Path
import json
import math
import numpy as np

root = Path(__file__).resolve().parent
paths = json.loads((root/'paths.json').read_text())
results_path = root/'recordings/native/summary.json'
results = {r['path_id']:r for r in json.loads(results_path.read_text())} if results_path.exists() else {}
offsets = {'volley_center':(0,0), 'volley_tip':(0,10), 'volley_throat':(0,-10),
           'volley_left':(-8,0), 'volley_right':(8,0)}
for p in paths:
    name,typ=p['path_id'],p['shot_type']
    pct = 5 if name.endswith('slow') else 15 if name.endswith('medium') else 35
    low_pct = 1 if name.endswith('slow') else 3 if name.endswith('medium') else 6
    static=typ=='static_pose'; tap=typ=='tap_test'; volley=typ=='volley'
    wrist=name.startswith('wrist_only_')
    overhead=typ in ('serve_like','high_forehand')
    arm=not (static or tap or volley or wrist)
    target=0 if static else .02 if tap else .1 if volley else (.15 if name.endswith('slow') else .4 if name.endswith('medium') else 1.0)
    arc_length=.15*2*math.atan2(.12,.09) if overhead else .1625*2*math.atan2(.15,.0625)
    bound=720*pct/100 if wrist else (40 if overhead else 24)/arc_length*target if arm else 0
    if wrist:target=math.radians(bound)*.45
    p.update(handedness='right',
             target_tcp_speed_mps=round(target,6),
             expected_peak_deg_s=bound,
             target_face_angle_deg=180 if not static else None,
             target_swing_path_deg=0 if volley or arm else None,
             planned_contact_offset_cm=dict(zip(('x','y'),offsets.get(name,(0,0)))) if p['intended_contact'] else None)
    # Angle conventions are explicit. Nonplanar wrist arcs do not have a single
    # constant swing-path angle; do not invent one scalar for the whole arc.
    p['reps'] = 1 if static else 10 if typ in ('volley','forehand','backhand') else 3
    if tap and p['intended_contact']:
        p['planned_contact_offset_cm']={'x':0 if 'wide' in name else 1.7,'y':-50}
    p['notes'] = ('Native RC+ virtual path. ' +
        ('Hold named orientation for 3 s; speed is zero during the hold. Transfers and sync are separate. ' if static else
         'Wide = face-normal pad direction; narrow = across-face pad direction. Simulated approach only; impact force is not modelled. ' if tap else
         'Fixed ball robot XYZ=(0,-500,500) mm; vary TCP to put ball at the stated racket-face offset. ' if volley else
         'J1–J5 fixed during an isolated 40 degree J6 sweep. ' if wrist else
         'Whole-arm Arc3 backswing, forward drive through the fixed contact point, follow-through and recovery. Racket orientation changes with the arm motion. ') +
        'Manifest speed targets describe tb_recap_stepup in the virtual controller; the ordinary runner remains Power Low. Angular bounds exclude transfers and sync. ' +
        ('No contact; expected app hit label is false. ' if not p['intended_contact'] and not static else '') +
        ('Tip up through the centre; 8 rad/s crossing remains outside this low-speed profile. ' if typ in ('serve_like','high_forehand') else '') +
        'Face angle is signed yaw of the face normal from world +x, viewed from +z. Swing-path angle is elevation above the horizontal at nominal contact; null means undefined or not constant.')
    p['sim_stepup_joint_pct'] = pct if wrist else None
    p['sim_stepup_angular_bound_deg_s'] = None if p['sim_stepup_joint_pct'] is None else 7.2*p['sim_stepup_joint_pct']
    p['expected_peak_scope'] = 'Primary path only. J6 bound = 720 deg/s * commanded percentage for wrist tests; Cartesian arcs use orientation change / arc length * target TCP speed.'
    p['c8_wrist_catalog_deg_s']={'J4':450,'J5':450,'J6':720}
    p['conservative_J6_bound_deg_s']=7.2*low_pct if wrist else None
    if arm:
        p['primary_motion']='coordinated whole-arm Arc3'
        p['conservative_tcp_target_mps']=target*.25
        p['right_hand_mapping']='forehand=P853/P854/P855; backhand=P850/P851/P852; corrected from user RC+ observation'
    if name in results:
        r=results[name]
        p['observed_virtual_peak_deg_s_including_transfers']=r['peak_orientation_deg_s']
        p['observed_virtual_tcp_peak_mps_including_transfers']=r['peak_tcp_speed_mps']
        p['virtual_log_file']=r['file']
        if 'primary_arc_peak_tcp_mps' in r:
            p['observed_primary_tcp_peak_mps']=r['primary_arc_peak_tcp_mps']
            p['observed_primary_peak_deg_s']=r['primary_arc_peak_deg_s']
    p['planned_contact_time_s'] = None
    if p['intended_contact'] and name in results:
        ev={e['event']:e['time_s'] for e in results[name]['events']}
        key='planned_contact_pose' if volley else 'tap_1_pose' if tap else None
        if key and key in ev and 'path_start_command' in ev:
            p['planned_contact_time_s']=ev[key]-ev['path_start_command']
        elif typ in ('forehand','backhand','serve_like','high_forehand') and 'path_start_command' in ev:
            file=root/'recordings/native'/results[name]['file']
            a=np.loadtxt(file,delimiter=',',skiprows=1)
            ball=np.array([.65,-.18,1.05] if typ=='serve_like' else [.60,-.18,.95] if typ=='high_forehand' else [.5,0,.5])
            eligible=np.where((a[:,0]>=ev.get('forward_arc_start',ev['path_start_command'])) & (a[:,0]<=ev.get('follow_through_end',a[-1,0])))[0]
            if len(eligible):
                i=eligible[np.argmin(np.linalg.norm(a[eligible,7:10]-ball,axis=1))]
                p['planned_contact_time_s']=float(a[i,0]-ev['path_start_command'])
                p['virtual_nominal_contact_miss_m']=float(np.linalg.norm(a[i,7:10]-ball))
        if p['planned_contact_time_s'] is not None:
            p['notes']+=' Contact time is the virtual nominal contact-pose time from the step-up reference run, not detected impact.'
            p['planned_timing_reference']='tb_recap_stepup, E35E, virtual controller'
(root/'paths.json').write_text(json.dumps(paths,indent=2)+'\n')
print('Updated',len(paths),'native path entries')
