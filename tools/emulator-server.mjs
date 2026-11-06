#!/usr/bin/env node
// Same-origin static server and agent proxy. No packages or cloud account required.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import worker from '../website/api/muse-worker.js';

const root = path.resolve(fileURLToPath(new URL('../website/', import.meta.url)));
const port = Number(process.env.EMULATOR_PORT || 8765);
const types = {'.html':'text/html', '.js':'text/javascript', '.mjs':'text/javascript',
  '.json':'application/json', '.css':'text/css', '.png':'image/png', '.jpg':'image/jpeg',
  '.svg':'image/svg+xml', '.glb':'model/gltf-binary', '.webp':'image/webp', '.woff2':'font/woff2'};
const env = {
  LEMONADE_MODEL: process.env.LEMONADE_MODEL || 'Qwen3-1.7B-GGUF',
  LEMONADE_BASE_URL: process.env.LEMONADE_BASE_URL || 'http://127.0.0.1:8000/api/v1',
  LEMONADE_API_KEY: process.env.LEMONADE_API_KEY,
  ASSETS: {async fetch(request) {
    let pathname = decodeURIComponent(new URL(request.url).pathname);
    if (pathname === '/' || pathname === '/emulator') pathname = '/emulator.html';
    const target = path.resolve(root, '.' + pathname);
    if (!target.startsWith(root + path.sep) && target !== root) return new Response('Forbidden', {status:403});
    try { return new Response(await readFile(target), {headers:{'Content-Type':types[path.extname(target)] || 'application/octet-stream'}}); }
    catch { return new Response('Not found', {status:404}); }
  }}
};

http.createServer(async (req, res) => {
  try {
    if (!['GET','HEAD','POST'].includes(req.method)) {res.writeHead(405);res.end();return;}
    const origin = `http://${req.headers.host}`;
    if (![ `localhost:${port}`, `127.0.0.1:${port}` ].includes(req.headers.host)) {res.writeHead(403);res.end();return;}
    const chunks=[]; let size=0;
    for await (const chunk of req) {size+=chunk.length;if(size>600000){res.writeHead(413);res.end();return;}chunks.push(chunk);}
    const request = new Request(new URL(req.url, origin), {method:req.method,headers:req.headers,
      ...(['GET','HEAD'].includes(req.method)?{}:{body:Buffer.concat(chunks)})});
    const response = await worker.fetch(request, env);
    res.writeHead(response.status,Object.fromEntries(response.headers));
    res.end(req.method==='HEAD'?undefined:Buffer.from(await response.arrayBuffer()));
  } catch (error) {console.error(error.message);res.writeHead(500);res.end('Local emulator request failed');}
}).listen(port,'127.0.0.1',()=>console.log(`Emulator: http://localhost:${port}/emulator\nLemonade: ${env.LEMONADE_BASE_URL}\nModel: ${env.LEMONADE_MODEL}`));
