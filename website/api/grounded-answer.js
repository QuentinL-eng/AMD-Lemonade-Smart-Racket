// Numeric output is resolved from tool results, never copied from model prose.
export const presentAnswerSchema = {type:'function',function:{name:'present_answer',
  description:'Finish the chat answer. Put prose in text parts; insert every numeric fact with a tool result reference. No numbers or number words in prose.',
  parameters:{type:'object',additionalProperties:false,required:['parts'],properties:{parts:{type:'array',minItems:1,maxItems:20,items:{oneOf:[
    {type:'object',additionalProperties:false,required:['text'],properties:{text:{type:'string',maxLength:400}}},
    {type:'object',additionalProperties:false,required:['tool_call_id','path'],properties:{tool_call_id:{type:'string'},path:{type:'string',description:'JSON Pointer to a numeric value, e.g. /count'}}}
  ]}}}}}};

const numericProse = /\p{N}|\b(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|million|billion|half|quarter)\b/iu;
export function renderGroundedAnswer(parts, results) {
  if(!Array.isArray(parts)||!parts.length||parts.length>20)throw Error('Answer needs bounded parts.');
  let length=0;
  return parts.map(part=>{
    if(!part||typeof part!=='object'||Array.isArray(part))throw Error('Invalid answer part.');
    if(Object.keys(part).length===1&&typeof part.text==='string'){
      length+=part.text.length;
      if(length>1200||numericProse.test(part.text))throw Error('Put numeric claims in tool references, not prose.');
      return part.text;
    }
    if(Object.keys(part).length!==2||typeof part.tool_call_id!=='string'||typeof part.path!=='string')throw Error('Invalid tool reference.');
    if(!results.has(part.tool_call_id)||!part.path.startsWith('/'))throw Error('Unknown tool result reference.');
    let value=results.get(part.tool_call_id);
    for(const token of part.path.slice(1).split('/')){
      const key=token.replace(/~1/g,'/').replace(/~0/g,'~');
      if(!value||typeof value!=='object'||!Object.hasOwn(value,key))throw Error('Tool result path does not exist.');
      value=value[key];
    }
    if(typeof value!=='number'||!Number.isFinite(value))throw Error('Reference must point to a finite numeric tool value.');
    return String(value);
  }).join('');
}
