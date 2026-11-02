from pathlib import Path
import sys,json,warnings
import numpy as np
from scipy.spatial.transform import Rotation as R
sys.path.insert(0,str(Path(__file__).parent))
import build_candidate_recap as b
ROOT=Path(__file__).parent
specs=json.loads((ROOT/'paths.json').read_text())
branches=['',' /B',' /L',' /L /B',' /F',' /B /F',' /L /F',' /L /B /F']
source=["' Native RC+ simulation project. No physical robot connection.", 'Function main','    tb_probe','Fend','', 'Function tb_tool','    Robot 1','    TLSet 1, XY(0, 450, 0, 90, 0, 180)','    TLSet 2, XY(0, -50, 0, 90, 0, 180)','    Tool 1','    Power Low','    Speed 20','    Accel 20, 20','    SpeedS 150','    AccelS 200, 200','Fend','', 'Function tb_probe','    Integer bad, iFile','    tb_tool','    iFile = FreeFile', '    WOpen "tb_reach.txt" As #iFile','    bad = 0']
points=[]
for spec in specs:
 keys,*_=b.build(spec)
 for t,(p,q) in keys:
  pb=b.ROBOT_TO_WORLD.T@p*1000; rb=b.ROBOT_TO_WORLD.T@q
  with warnings.catch_warnings():
   warnings.simplefilter('ignore'); u,v,w=R.from_matrix(rb).as_euler('ZYX',degrees=True)
  xy=f'XY({pb[0]:.4f}, {pb[1]:.4f}, {pb[2]:.4f}, {u:.4f}, {v:.4f}, {w:.4f})'
  key=tuple(np.round(np.r_[pb,[u,v,w]],4))
  if any(x[0]==key for x in points):continue
  idx=100+len(points); points.append((key,idx,xy,spec['path_id'],t))
  source.append(f'    P{idx} = {xy}')
  flags=', '.join(f'TargetOK(P{idx}{branch})' for branch in branches)
  source.append(f'    Print #iFile, "{idx} {spec["path_id"]}", {flags}')
source += ['    Close #iFile',f'    Print "Reach report written: {len(points)} unique poses, 8 branches"','Fend']
text='\r\n'.join(source)+'\r\n'
(ROOT/'rcplus').mkdir(exist_ok=True)
(ROOT/'rcplus'/'Main.prg').write_bytes(text.encode())
(ROOT/'rcplus'/'points.json').write_text(json.dumps(points,indent=2))
Path('D:/EpsonRC70/Projects/TennisBuddyDayOne_20261029/Main.prg').write_bytes(text.encode())
print('Native reach probe:',len(points),'unique poses')
