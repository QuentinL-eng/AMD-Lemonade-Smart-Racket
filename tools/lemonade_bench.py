"""Small reproducible endpoint latency probe; not an agent quality benchmark."""
import argparse
import datetime
import json
import math
import os
from pathlib import Path
import statistics
import time
import urllib.request

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--base',default=os.environ.get('LEMONADE_BASE_URL','http://127.0.0.1:8000/api/v1'))
p.add_argument('--model',required=True)
p.add_argument('--requests',type=int,default=5)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
if a.requests<1:p.error('--requests must be positive')
headers={'Content-Type':'application/json'}
if os.environ.get('LEMONADE_API_KEY'):headers['Authorization']='Bearer '+os.environ['LEMONADE_API_KEY']
body=json.dumps({'model':a.model,'enable_thinking':False,'temperature':0,'max_completion_tokens':64,
                 'messages':[{'role':'user','content':'Reply with the word ready.'}]}).encode()
runs=[]
for i in range(a.requests+1):
    start=time.perf_counter()
    try:
        req=urllib.request.Request(a.base.rstrip('/')+'/chat/completions',data=body,headers=headers)
        with urllib.request.urlopen(req,timeout=180) as response:d=json.load(response)
        row={'warmup':i==0,'elapsed_seconds':time.perf_counter()-start,'usage':d.get('usage'),
             'timings':d.get('timings'),'finish_reason':d['choices'][0].get('finish_reason'),
             'answer':d['choices'][0]['message'].get('content'),'error':None}
    except Exception as e:row={'warmup':i==0,'elapsed_seconds':time.perf_counter()-start,'error':str(e)}
    runs.append(row);print(json.dumps(row),flush=True)
values=sorted(r['elapsed_seconds'] for r in runs[1:] if not r['error'])
report={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'model':a.model,
        'measurement':'Total endpoint response latency, including network transport; one excluded warmup.',
        'requested':a.requests,'successful':len(values),'errors':a.requests-len(values),
        'median_seconds':statistics.median(values) if values else None,
        'p95_nearest_rank_seconds':values[math.ceil(.95*len(values))-1] if values else None,'runs':runs}
a.output.parent.mkdir(parents=True,exist_ok=True)
a.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Wrote',a.output)
