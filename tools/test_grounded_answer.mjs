import assert from 'node:assert/strict';
import {renderGroundedAnswer as render} from '../website/api/grounded-answer.js';
const results=new Map([['digest',{count:60,nested:{speed:127.5},missing:null,flag:true,items:[3]}]]);
assert.equal(render([{text:'Your replay has '},{tool_call_id:'digest',path:'/count'},{text:' shots.'}],results),'Your replay has 60 shots.');
assert.equal(render([{tool_call_id:'digest',path:'/nested/speed'}],results),'127.5');
assert.equal(render([{tool_call_id:'digest',path:'/items/0'}],results),'3');
for(const parts of [ [{text:'60 shots'}],[{text:'sixty shots'}],[{text:'６０ shots'}],
  [{tool_call_id:'invented',path:'/count'}],[{tool_call_id:'digest',path:'/missing'}],
  [{tool_call_id:'digest',path:'/flag'}],[{tool_call_id:'digest',path:'/__proto__'}],
  [{tool_call_id:'digest',path:'/absent'}],[{text:'safe',extra:4}] ])assert.throws(()=>render(parts,results));
assert.equal(results.get('digest').count,60);
console.log('Grounded renderer: exact references pass; invented numbers and invalid references fail closed.');
