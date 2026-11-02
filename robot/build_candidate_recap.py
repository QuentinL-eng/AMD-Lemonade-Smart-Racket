"""Generate a tool-space simulation, candidate SPEL+ paths and a labelled recap.
No C8 inverse kinematics or dynamics are simulated here; RC+ validation is separate.
"""
from pathlib import Path
import json, math, csv
import numpy as np
from scipy.spatial.transform import Rotation as R, Slerp
import cv2
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'generated'; OUT.mkdir(exist_ok=True)
SWEETSPOT_OFFSET_M=.5
DT=.01
CENTER=np.array([.60,0,.70])
# Right-handed racket axes: tip +Y, across +Z, face +X in world.
BASE=np.column_stack(([0,1,0],[0,0,1],[1,0,0]))
F2H=np.eye(4); F2H[:3,:3]=np.column_stack(([0,1,0],[1,0,0],[0,0,-1])); F2H[:3,3]=[0,-.05,0]
# Image interpretation: the green side is opposite the zero-pose arm extension,
# taken here as robot -Y. This sign needs confirmation in the RC+ top view.
ROBOT_TO_WORLD=R.from_euler('z',90,degrees=True).as_matrix()
def rot(axis,a): return R.from_rotvec(np.eye(3)[axis]*math.radians(a)).as_matrix()
def pose(p=CENTER,r=BASE): return (np.array(p,dtype=float).copy(),np.array(r).copy())
def blend(a,b,s):
 q=Slerp([0,1],R.from_matrix([a[1],b[1]]))([s]).as_matrix()[0]
 return a[0]*(1-s)+b[0]*s,q

def build(spec):
 id=spec['path_id']; typ=spec['shot_type']; speed=.15 if id.endswith('slow') else .30 if id.endswith('medium') else .50
 if typ in ['volley','tap_test']: speed=.10
 keys=[(0,pose()),(1,pose()),(1.15,pose(r=BASE@rot(0,4))),(1.30,pose()),(2.30,pose())]
 # Sync command events are ideal-plan events, not actual controller timestamps.
 start=2.30; contact=None; offset={'x':0,'y':0}; peak_bound=None
 def add(d,p): keys.append((keys[-1][0]+d,p))
 if typ=='static_pose':
  if 'tip_up' in id: rr=np.column_stack(([0,0,1],[0,-1,0],[1,0,0]))
  elif 'face_up' in id: rr=np.eye(3)
  elif 'face_down' in id: rr=np.diag([1,-1,-1])
  elif 'tilt_x' in id: rr=BASE@rot(0,45)
  else: rr=BASE@rot(1,45)
  add(2,pose(r=rr)); add(3,pose(r=rr)); add(2,pose())
 elif typ=='tap_test':
  # External compliant pad, approached with the SENSOR, distinct side normals.
  if 'after_swing' in id:
   add(1,pose(CENTER+[0,-.10,0],BASE@rot(2,-10))); add(1,pose()); add(.5,pose())
  count=int(id.split('_')[2]); side=1 if '_wide_' in id else 2
  direction=BASE[:,side]; step=.004*direction
  for _ in range(count): add(.12,pose(CENTER+step)); add(.12,pose()); add(.16,pose())
  add(1,pose())
 elif typ=='volley':
  if id.endswith('tip'): offset['y']=10
  if id.endswith('throat'): offset['y']=-10
  if id.endswith('left'): offset['x']=-8
  if id.endswith('right'): offset['x']=8
  # Ball stays fixed: translate sweetspot by negative contact offset in racket frame.
  delta=BASE@np.array([offset['y']/100,offset['x']/100,0])
  add(1,pose(CENTER+[-.06,0,0]-delta)); add(.6,pose(CENTER-delta)); contact=keys[-1][0]-start
  add(.6,pose(CENTER+[.06,0,0]-delta)); add(1,pose())
 else:
  overhead=typ in ['serve_like','high_forehand']; rr=BASE
  if overhead: rr=np.column_stack(([0,0,1],[0,-1,0],[1,0,0]))
  sign=-1 if 'backhand' in id else 1
  axis=1 if overhead else 2
  amplitude=18 if not overhead else 15
  c=CENTER+([0,0,.25] if overhead else np.zeros(3))
  a=pose(c+[0,-sign*.12,0],rr@rot(axis,-amplitude))
  b=pose(c,rr); e=pose(c+[0,sign*.12,0],rr@rot(axis,amplitude))
  add(1.5,a)
  duration=max(.5,.24/speed)
  add(duration/2,b)
  if spec['intended_contact']: contact=keys[-1][0]-start
  add(duration/2,e)
  if typ=='abrupt_stop':
   add(.15, e)
   if id.endswith('reverse'): add(duration,a)
  add(1.5,pose())
  # Single-axis wrist catalog percentage bound; not an achieved prediction.
  peak_bound=720*.20 if axis==2 else 450*.20
 add(1,pose())
 times=np.arange(0,keys[-1][0]+DT/2,DT); pp=[]; rr=[]; segment=0
 for t in times:
  while segment<len(keys)-2 and t>keys[segment+1][0]: segment+=1
  ta,pa=keys[segment]; tb,pb=keys[segment+1]
  u=np.clip((t-ta)/(tb-ta),0,1); s=u*u*(3-2*u)
  p,q=blend(pa,pb,s); pp.append(p); rr.append(q)
 pp=np.array(pp); rr=np.array(rr)
 # Check the complete racket proxy (handle to tip, both head edges), not only TCP.
 local=np.array([[-.50,0,0],[-.36,0,0],[-.18,-.15,0],[-.18,.15,0],[.18,-.15,0],[.18,.15,0]])
 swept=pp[:,None,:]+np.einsum('nij,kj->nki',rr,local)
 margin=float(swept[:,:,0].min()); assert margin>=0, (id,margin)
 v=float(np.linalg.norm(np.diff(pp,axis=0),axis=1).max()/DT)
 omega=float(np.max(R.from_matrix(np.einsum('nji,njk->nik',rr[:-1],rr[1:])).magnitude())/DT*180/math.pi)
 spec.update(target_tcp_speed_mps=round(v,4),expected_peak_deg_s=round(omega,2),target_face_angle_deg=None,target_swing_path_deg=None,planned_contact_time_s=contact,planned_contact_offset_cm=offset,handedness='right',reps=10 if spec['intended_contact'] else 3)
 spec['simulation']={'source':'ideal_tool_space_plan','rcplus_validated':False,'min_racket_x_m':margin,'path_start_s':start,'duration_s':float(times[-1]),'wrist_catalog_bound_at_20pct_deg_s':peak_bound,'contact_physics':False}
 spec['notes']='Ideal tool-space candidate. Pose interpolation and timing are not RC+ execution. No joint or torque feasibility claimed.'
 return keys,times,pp,rr,spec

def export(spec,keys,times,pp,rr):
 path=OUT/(spec['path_id']+'_rep01_E35E_SIMULATED.csv')
 with path.open('w',newline='') as f:
  w=csv.writer(f); w.writerow(['time_s','tcp_x_m','tcp_y_m','tcp_z_m','qw','qx','qy','qz','source'])
  quats=R.from_matrix(rr).as_quat()
  for t,p,q in zip(times,pp,quats): w.writerow([f'{t:.4f}',*p,q[3],*q[:3],'ideal_tool_space_plan'])
 # Desired racket frame already defined by TLSet orientation; convert to robot base.
 lines=[f'Function {spec["path_id"]}', '    Speed 20','    Accel 20, 20',f'    SpeedS {max(20,int(spec["target_tcp_speed_mps"]*1000))}','    AccelS 200, 200']
 previous=keys[0]
 for point_index,(t,(p,q)) in enumerate(keys[1:],100):
  pb=ROBOT_TO_WORLD.T@p*1000; rb=ROBOT_TO_WORLD.T@q
  u,v,w=R.from_matrix(rb).as_euler('ZYX',degrees=True)
  # Move timing is controller-dependent; ideal key times go into comments.
  stationary=np.allclose(p,previous[1][0]) and np.allclose(q,previous[1][1])
  if stationary:
   lines += [f'    Wait {t-previous[0]:.3f}']
  else:
   lines += [f"    ' Ideal elapsed {t:.3f} s; verify achieved timing in RC+.",f'    Move XY({pb[0]:.3f}, {pb[1]:.3f}, {pb[2]:.3f}, {u:.3f}, {v:.3f}, {w:.3f})']
  previous=(t,(p,q))
 lines+=['Fend','']
 return '\n'.join(lines)

def render(allruns):
 fontfile='C:/Windows/Fonts/arial.ttf'
 font=ImageFont.truetype(fontfile,23); small=ImageFont.truetype(fontfile,17)
 writer=cv2.VideoWriter(str(OUT/'day_one_candidate_recap.mp4'),cv2.VideoWriter_fourcc(*'mp4v'),24,(1280,720))
 chapters=[]; frame=0
 def project(p):
  p=np.asarray(p); return np.column_stack((600+290*(p[...,1]-.60*p[...,0]),600-280*p[...,2]-100*p[...,0])).astype(int)
 for keys,times,pp,rr,spec in allruns:
  chapters.append({'path_id':spec['path_id'],'video_start_s':frame/24})
  # Each path shown at 2x; static 3-second hold retained in model and labelled.
  for idx in range(0,len(times),8):
   im=Image.new('RGB',(1280,720),'#101a29');d=ImageDraw.Draw(im)
   def poly(points,fill): d.polygon([tuple(x) for x in project(points)],fill=fill)
   poly([[0,-1,0],[1.4,-1,0],[1.4,1,0],[0,1,0]],'#123c31')
   poly([[-.6,-1,0],[0,-1,0],[0,1,0],[-.6,1,0]],'#5a2634')
   def line(points,color,width=2):d.line([tuple(x) for x in project(points)],fill=color,width=width)
   for x in np.arange(-.6,1.41,.2):line([[x,-1,0],[x,1,0]],'#35505b',1)
   for y in np.arange(-1,1.01,.2):line([[-.6,y,0],[1.4,y,0]],'#35505b',1)
   line([[0,-1,0],[0,1,0]],'#ff596c',4)
   line(pp[::8],'#2e8497',2); line(pp[:idx+1:3],'#69e5eb',4)
   p,q=pp[idx],rr[idx]
   def world(a): return p+np.asarray(a)@q.T
   theta=np.linspace(0,2*np.pi,65)
   hoop=world(np.column_stack((.18*np.cos(theta),.145*np.sin(theta),theta*0)))
   line(hoop,'#e3edf5',5);line(world([[-.50,0,0],[-.22,0,0]]),'#f3c76b',9)
   line(world([[-.22,0,0],[-.12,-.105,0]]),'#97a9bf',3);line(world([[-.22,0,0],[-.12,.105,0]]),'#97a9bf',3)
   for y in np.arange(-.12,.13,.03):
    dx=.18*np.sqrt(max(0,1-(y/.145)**2));line(world([[-dx,y,0],[dx,y,0]]),'#658098',1)
   for a,col in enumerate(['#ff9a65','#8df0b8','#8db4ff']):line([p,p+q[:,a]*.12],col,3)
   if spec['intended_contact']:
    offset=spec['planned_contact_offset_cm']; contact=CENTER.copy();
    if spec['shot_type'] in ['serve_like','high_forehand']:contact[2]+=.25
    pt=project([contact])[0];d.ellipse([pt[0]-7,pt[1]-7,pt[0]+7,pt[1]+7],fill='#d5ef43')
   if spec['shot_type']=='tap_test':
    h=world([[-.50,0,0]])[0]; pt=project([h])[0];d.rectangle([pt[0]+8,pt[1]-16,pt[0]+20,pt[1]+16],fill='#b7a1e8')
   d.text((32,22),'TENNIS BUDDY / DAY ONE MOTION STUDY',font=font,fill='white')
   d.text((32,60),'TOOL-SPACE CANDIDATE ANIMATION - NOT RC+ EXECUTION',font=small,fill='#ffc776')
   d.text((32,100),spec['path_id'],font=font,fill='#69e5eb')
   phase='sync / 1 s holds + racket-x twitch' if times[idx]<2.3 else 'path / pause / return'
   d.text((32,136),f'{phase}   t = {times[idx]:.2f} s',font=small,fill='white')
   d.text((885,110),f'TCP peak {spec["target_tcp_speed_mps"]:.2f} m/s',font=small,fill='white')
   d.text((885,140),f'Angular peak {spec["expected_peak_deg_s"]:.1f} deg/s',font=small,fill='white')
   d.text((885,170),f'Reps planned: {spec["reps"]}',font=small,fill='white')
   d.text((885,200),f'Contact intended: {spec["intended_contact"]}',font=small,fill='white')
   d.text((885,230),str(spec['planned_contact_offset_cm'])+' cm',font=small,fill='white')
   d.text((32,650),'Green: world x >= 0 | Red: world x < 0 | All racket proxy samples checked',font=small,fill='#a6debe')
   d.text((32,678),'No C8 joint feasibility, collision, contact-force or actual-encoder validation in this animation.',font=small,fill='#b1bdcd')
   writer.write(cv2.cvtColor(np.array(im),cv2.COLOR_RGB2BGR));frame+=1
 writer.release();(OUT/'chapters.json').write_text(json.dumps(chapters,indent=2))

if __name__=='__main__':
 specs=json.loads((ROOT/'paths.json').read_text()); runs=[build(s) for s in specs]
 sources=[]
 for keys,times,pp,rr,spec in runs:sources.append(export(spec,keys,times,pp,rr))
 (OUT/'candidate_paths.prg').write_text("' GENERATED CANDIDATES: not compiled, no RC+ validation, Tool 1 must be defined.\n"+'\n'.join(sources))
 (OUT/'paths.simulated.json').write_text(json.dumps([r[-1] for r in runs],indent=2))
 (OUT/'frames.json').write_text(json.dumps({'flange_to_handle_assumed':F2H.tolist(),'sweetspot_offset_m':SWEETSPOT_OFFSET_M,'world_x':'toward net; robot -Y assumed from green side image','world_z':'up','safe_half_plane':'world x >= 0','source':'provisional tool-space planning assumptions'},indent=2))
 render(runs)
 print('Generated',len(runs),'paths and recap')
