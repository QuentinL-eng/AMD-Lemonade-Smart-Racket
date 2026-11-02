"""Plot executed sweet-spot and conservative racket-proxy bounds, not arm clearance."""
from pathlib import Path
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.spatial.transform import Rotation

folder=Path('robot/recordings/native')
reports=json.loads((folder/'summary.json').read_text())
points=[]; proxy=[]
corners=np.array([[x,y,z] for x in (-.55,.18) for y in (-.145,.145) for z in (-.015,.015)])
for r in reports:
    a=np.loadtxt(folder/r['file'],delimiter=',',skiprows=1)[::25]
    p=a[:,7:10];q=a[:,10:14]
    rot=Rotation.from_quat(q[:,[1,2,3,0]]).as_matrix()
    points.append(p);proxy.append((rot@corners.T).transpose(0,2,1).reshape(-1,3)+np.repeat(p,8,axis=0))
p=np.concatenate(points);v=np.concatenate(proxy)
fig,axes=plt.subplots(1,2,figsize=(12,6),layout='constrained')
for ax,col,title in zip(axes,[1,2],['Top view: toward net / across court','Side view: toward net / height']):
    ax.axvspan(-.5,0,color='#e9a1a1',alpha=.6)
    ax.axvspan(0,1.5,color='#b9dfae',alpha=.55)
    ax.scatter(v[:,0],v[:,col],s=.3,c='#405274',alpha=.1,label='Assumed racket proxy')
    ax.scatter(p[:,0],p[:,col],s=.7,c='#1454a4',alpha=.4,label='Executed sweet-spot samples')
    ax.axvline(0,color='#a32121',lw=1.5)
    ax.scatter([0],[0],c='black',s=35,marker='x',label='Robot base origin')
    ax.set(xlabel='World x toward net (m)',ylabel='World '+('y across court' if col==1 else 'z up')+' (m)',title=title,xlim=(-.25,1.3))
    ax.set_aspect('equal',adjustable='datalim');ax.grid(alpha=.2)
axes[0].legend(loc='lower left',fontsize=8)
fig.suptitle('RC+ executed trajectory envelope — simulation only',fontsize=15)
fig.text(.5,.01,'Green half-plane is an interpretation of the supplied image. Proxy dimensions and mounting are assumed. Full-arm and fixture clearance are not certified.',ha='center',fontsize=8)
fig.savefig(folder/'executed_envelope.png',dpi=160)
fig.savefig(folder/'executed_envelope.svg')
print('Executed envelope plots written')
