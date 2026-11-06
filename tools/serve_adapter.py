"""Serve a trained PEFT adapter on CUDA for the unchanged agent evaluator.

This is desktop Transformers inference, not the iPhone runtime. Binds loopback only.
"""
import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from pathlib import Path
import re
import time
import uuid


def assistant_message(text):
    calls=[]
    for match in re.finditer(r'<tool_call>\s*(.*?)\s*</tool_call>',text,re.S):
        value=json.loads(match.group(1))
        if not isinstance(value,dict) or not isinstance(value.get('name'),str) or not isinstance(value.get('arguments'),dict):
            raise ValueError('Malformed native Qwen tool call')
        calls.append({'id':'call_'+uuid.uuid4().hex,'type':'function',
                      'function':{'name':value['name'],'arguments':json.dumps(value['arguments'])}})
    remainder=re.sub(r'<tool_call>.*?</tool_call>','',text,flags=re.S).strip()
    if '<tool_call>' in remainder or '</tool_call>' in remainder:
        raise ValueError('Incomplete native Qwen tool call')
    message={'role':'assistant','content':remainder or None}
    if calls:message['tool_calls']=calls
    if not calls and not remainder:raise ValueError('Empty model response')
    return message


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--adapter',type=Path,required=True)
    p.add_argument('--port',type=int,default=8001)
    p.add_argument('--model-id',default='tennis-buddee-qwen2.5-1.5b-step300')
    a=p.parse_args()
    from train_ondevice import template_messages
    import torch
    from peft import PeftModel
    from transformers import AutoModelForCausalLM,AutoTokenizer,BitsAndBytesConfig
    if not torch.cuda.is_available():p.error('This validation server requires CUDA')
    config=json.loads((a.adapter/'adapter_config.json').read_text())
    weights=a.adapter/'adapter_model.safetensors'
    checksum=hashlib.file_digest(weights.open('rb'),'sha256').hexdigest()
    tokenizer=AutoTokenizer.from_pretrained(a.adapter,trust_remote_code=False)
    quantization=BitsAndBytesConfig(load_in_4bit=True,bnb_4bit_quant_type='nf4',
        bnb_4bit_use_double_quant=True,bnb_4bit_compute_dtype=torch.float16)
    base=AutoModelForCausalLM.from_pretrained(config['base_model_name_or_path'],
        quantization_config=quantization,device_map={'':0},dtype=torch.float16,
        trust_remote_code=False,attn_implementation='sdpa')
    model=PeftModel.from_pretrained(base,a.adapter,is_trainable=False).eval()
    model.config.use_cache=True
    eos=model.generation_config.eos_token_id
    eos=set(eos if isinstance(eos,list) else [eos])

    class Handler(BaseHTTPRequestHandler):
        def respond(self,status,data):
            raw=json.dumps(data).encode();self.send_response(status)
            self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(raw)))
            self.end_headers();self.wfile.write(raw)

        def do_GET(self):
            if self.path!='/v1/models':return self.respond(404,{'error':'Unknown route'})
            self.respond(200,{'object':'list','data':[{'id':a.model_id,'object':'model',
                'adapter_sha256':checksum,'runtime':'Transformers CUDA NF4 + PEFT, greedy decoding'}]})

        def do_POST(self):
            if self.path!='/v1/chat/completions':return self.respond(404,{'error':'Unknown route'})
            try:
                length=int(self.headers.get('Content-Length','0'))
                if not 0<length<=4_000_000:return self.respond(413,{'error':'Invalid body size'})
                body=json.loads(self.rfile.read(length))
                if body.get('model')!=a.model_id:return self.respond(400,{'error':'Unknown model ID'})
                limit=int(body.get('max_completion_tokens',4096))
                if not 1<=limit<=4096:return self.respond(400,{'error':'Invalid completion limit'})
                prompt=tokenizer.apply_chat_template(template_messages(body['messages']),
                    tools=body.get('tools') or [],tokenize=False,add_generation_prompt=True)
                inputs=tokenizer(prompt,return_tensors='pt').to('cuda')
                count=inputs['input_ids'].shape[1]
                if count+limit>model.config.max_position_embeddings:
                    return self.respond(400,{'error':'Context limit exceeded; no truncation performed'})
                started=time.perf_counter()
                with torch.inference_mode():
                    output=model.generate(**inputs,max_new_tokens=limit,max_time=75,do_sample=False,
                        pad_token_id=tokenizer.eos_token_id,use_cache=True)
                generated=output[0,count:]
                if not len(generated) or int(generated[-1]) not in eos:
                    return self.respond(502,{'error':'Completion stopped before end of turn (token or time limit)'})
                message=assistant_message(tokenizer.decode(generated,skip_special_tokens=True))
                print(json.dumps({'event':'completion','input_tokens':count,'output_tokens':len(generated),
                                  'seconds':time.perf_counter()-started,'tool_calls':len(message.get('tool_calls',[]))}),flush=True)
                self.respond(200,{'model':a.model_id,'choices':[{'index':0,'message':message,
                    'finish_reason':'tool_calls' if message.get('tool_calls') else 'stop'}],
                    'usage':{'prompt_tokens':count,'completion_tokens':len(generated),'total_tokens':count+len(generated)}})
            except Exception as error:
                print(type(error).__name__+': '+str(error),flush=True)
                self.respond(502,{'error':type(error).__name__+': '+str(error)[:200]})

    print(json.dumps({'event':'ready','port':a.port,'model':a.model_id,'adapter_sha256':checksum,
                      'gpu':torch.cuda.get_device_name(0),'decoding':'greedy'}),flush=True)
    HTTPServer(('127.0.0.1',a.port),Handler).serve_forever()


if __name__=='__main__':main()
