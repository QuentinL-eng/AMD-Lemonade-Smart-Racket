// Offline checks require Node 20+, no packages, model, racket or Apple device.
import {readFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
if(Number(process.versions.node.split('.')[0])<20)throw Error('Node 20+ required');
for(const file of ['website/emulator.html','website/emulator_sessions.json',
  'website/emulator/TennisRacket.glb','website/emulator/three.module.min.js',
  'website/emulator/GLTFLoader.js','website/emulator/BufferGeometryUtils.js'])
  await readFile(new URL('../'+file,import.meta.url));
for(const file of ['tools/test_grounded_answer.mjs','tools/test_emulator_agent.mjs']){
  const result=spawnSync(process.execPath,[file],{cwd:root,stdio:'inherit'});
  if(result.status!==0)process.exit(result.status||1);
}
console.log('Judge assets and local agent contract checks passed.');
if(!process.argv.includes('--offline')){
  const base=process.env.LEMONADE_BASE_URL||'http://127.0.0.1:8000/api/v1';
  const headers=process.env.LEMONADE_API_KEY?{Authorization:'Bearer '+process.env.LEMONADE_API_KEY}:{};
  const response=await fetch(base+'/models',{headers,signal:AbortSignal.timeout(5000)});
  if(!response.ok)throw Error('Lemonade model list failed: HTTP '+response.status);
  const data=await response.json();if(!Array.isArray(data.data))throw Error('Invalid model list');
  console.log('Lemonade reachable; downloaded model IDs:',data.data.map(x=>x.id).join(', ')||'(none)');
}
