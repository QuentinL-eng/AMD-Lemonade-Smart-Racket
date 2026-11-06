// Run: node examples/grounded-numeric-answer.mjs
// This is an illustrative tool result, not a measured tennis session.
import {renderGroundedAnswer} from '../website/api/grounded-answer.js';
const tools = new Map([['session_context',{count:60}]]);
const modelSelection = [{text:'Your replay contains '},
  {tool_call_id:'session_context',path:'/count'},{text:' shots.'}];
console.log(renderGroundedAnswer(modelSelection,tools));
try {renderGroundedAnswer([{text:'Your replay contains 99 shots.'}],tools);}
catch(error){console.log('Blocked unsupported numeric prose:',error.message);}
