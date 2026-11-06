import assert from 'node:assert/strict';
import http from 'node:http';
import worker from '../website/api/muse-worker.js';

let requests=0;
const mock=http.createServer(async(req,res)=>{
  let raw='';for await(const chunk of req)raw+=chunk;
  const body=JSON.parse(raw);requests++;
  assert.equal(req.url,'/v1/chat/completions');
  assert.equal(body.model,'fixture-model');assert.equal(body.enable_thinking,false);
  if(requests===1){
    assert.ok(body.tools.some(t=>t.function.name==='simulate_change'));
    res.end(JSON.stringify({choices:[{message:{role:'assistant',content:null,tool_calls:[
      {id:'test-call',type:'function',function:{name:'query_shots',arguments:'{"type":"forehand"}'}}
    ]}}]}));
  }else{
    const result=JSON.parse(body.messages.find(m=>m.tool_call_id==='test-call').content);
    assert.equal(result.count,1);
    res.end(JSON.stringify({choices:[{message:{role:'assistant',content:'Your replay has 1 forehand.'}}]}));
  }
});
await new Promise(resolve=>mock.listen(0,'127.0.0.1',resolve));
try{
  const response=await worker.fetch(new Request('http://localhost:8765/api/muse',{
    method:'POST',headers:{Origin:'http://localhost:8765','Content-Type':'application/json'},
    body:JSON.stringify({question:'How many forehands?',context:{shots:[{stroke:'forehand',parameters:{swing:60},estimates:{dist:1}}]}})
  }),{LEMONADE_MODEL:'fixture-model',LEMONADE_BASE_URL:`http://127.0.0.1:${mock.address().port}/v1`});
  assert.equal(response.status,200);const result=await response.json();
  assert.equal(result.answer,'Your replay has 1 forehand.');
  assert.ok(result.tools.includes('query_shots'));assert.equal(requests,2);
  console.log('Local agent tool loop passed (two loopback requests, real tool dispatch).');
}finally{mock.close();}
