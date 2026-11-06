// Records the local emulator with headless Chrome: real clicks, real answers from the model Lemonade has loaded.
//   LEMONADE_MODEL=<id> EMULATOR_PORT=8766 node tools/emulator-server.mjs      (first, from the repo root)
//   node video/scripts/capture-lemonade.mjs <chrome> <outdir> <port> ["question" ...]
// Writes frames/NNNNN.jpg, frames.json (timestamps) and log.json (when each step happened, and every answer verbatim).
// Nothing on the phone screen is edited afterwards: scripts/cut-lemonade.py only crops to the phone and cuts the waits.
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';

const [chrome, out, port, ...questions] = process.argv.slice(2);
mkdirSync(`${out}/frames`, { recursive: true });
const proc = spawn(chrome, ['--headless', '--remote-debugging-port=9335', `--user-data-dir=${out}/profile`, '--window-size=1920,1200',
  '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let target;
for (let i = 0; i < 40 && !target; i++) {
  await sleep(500);
  try { target = (await (await fetch('http://127.0.0.1:9335/json')).json()).find((t) => t.type === 'page'); } catch {}
}
if (!target) { proc.kill(); throw new Error('no chrome'); }
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => { ws.onopen = r; });
let id = 0, n = 0;
const waiting = new Map();
const frames = [];
const send = (method, params = {}) => new Promise((r) => { const k = ++id; waiting.set(k, r); ws.send(JSON.stringify({ id: k, method, params })); });
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id) { waiting.get(d.id)?.(d.result ?? d); waiting.delete(d.id); return; }
  if (d.method === 'Page.screencastFrame') {
    const name = String(n++).padStart(5, '0');
    writeFileSync(`${out}/frames/${name}.jpg`, Buffer.from(d.params.data, 'base64'));
    frames.push({ name, t: Date.now() });
    send('Page.screencastFrameAck', { sessionId: d.params.sessionId });
  }
};
const js = async (expression) => (await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true })).result?.value;
const t0 = Date.now();
const log = [];
const mark = async (step, extra) => {
  const e = { step, t: Date.now(), at: (Date.now() - t0) / 1000 };
  if (extra !== undefined) e.extra = extra;
  log.push(e);
  writeFileSync(`${out}/log.json`, JSON.stringify(log, null, 1));
  writeFileSync(`${out}/frames.json`, JSON.stringify(frames));
  console.log(e.at.toFixed(1), step, extra === undefined ? '' : JSON.stringify(extra).slice(0, 900));
};
const click = (sel) => js(`(()=>{const e=document.querySelector(${JSON.stringify(sel)});if(!e)return 'missing';e.click();return 'ok';})()`);
const until = async (expr, ms) => { const end = Date.now() + ms; while (Date.now() < end) { if (await js(expr)) return true; await sleep(400); } return false; };
const toBottom = () => js(`(()=>{const c=document.getElementById('v-other');if(c)c.scrollTo({top:c.scrollHeight,behavior:'smooth'});return !!c;})()`);

await send('Page.enable');
await send('Runtime.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1200, deviceScaleFactor: 2, mobile: false });
await send('Page.navigate', { url: `http://localhost:${port}/emulator` });
await sleep(6000);
await js(`document.documentElement.style.zoom='1.5';window.dispatchEvent(new Event('resize'))`);
await sleep(2000);
await send('Page.startScreencast', { format: 'jpeg', quality: 92, everyNthFrame: 1, maxWidth: 3840, maxHeight: 2400 });
await mark('ready');
await sleep(1200);
await mark('start session', await click('[data-act="session"]'));
await sleep(20000);
await mark('live played', await js(`window.__emu.S.shown + ' shots shown'`));
await js(`window.__emu.skipToEnd()`);
await sleep(800);
await js(`window.__emu.setTab('muse')`);
await sleep(2500);
await mark('agent tab', await js(`document.getElementById('v-other')?.innerText?.replace(/\\s+/g,' ').slice(0,500)`));
await sleep(1500);
for (const q of questions) {
  if (q === '@film') { // Code tests the changes with the simulator; the model writes the title, cue and reason.
    await js(`document.getElementById('v-other')?.scrollTo({top:0,behavior:'smooth'})`);
    await sleep(800);
    await mark('findfilm', await click('[data-act="findfilm"]'));
    const ok = await until(`!!window.__emu.S.film`, 200000);
    await sleep(3500);
    await mark('film result', { ok, film: await js(`(()=>{const f=window.__emu.S.film;return f&&{title:f.title,cue:f.cue,why:f.why,d:f.d,rawKeys:Object.keys(f)};})()`), screen: await js(`document.getElementById('v-other')?.innerText?.replace(/\s+/g,' ').slice(0,500)`) });
    continue;
  }
  if (q === '@whatif') {
    await mark('openwi', await click('[data-act="openwi"]'));
    await sleep(11000);
    await mark('whatif shown', await js(`document.getElementById('v-other')?.innerText?.replace(/\s+/g,' ').slice(0,600)`));
    await mark('back', await click('[data-act="back"]'));
    await sleep(1500);
    continue;
  }
  if (q === '@drill') {
    await js(`document.getElementById('v-other')?.scrollTo({top:0,behavior:'smooth'})`);
    await sleep(600);
    await mark('drill', await click('[data-act="drill"]'));
    const ok = await until(`!!window.__emu.S.drill`, 200000);
    await sleep(3500);
    await mark('drill result', { ok, drill: await js(`window.__emu.S.drill`), screen: await js(`document.getElementById('v-other')?.innerText?.replace(/\s+/g,' ').slice(0,500)`) });
    continue;
  }
  await js(`(()=>{const c=document.getElementById('v-other');if(c)c.scrollTo({top:c.scrollHeight,behavior:'smooth'});})()`);
  await sleep(600);
  // Typed one letter at a time, through the real input.
  for (let i = 1; i <= q.length; i += 2) {
    await js(`(()=>{const e=document.getElementById('q');if(!e)return;e.value=${JSON.stringify(q)}.slice(0,${i});e.dispatchEvent(new Event('input',{bubbles:true}));})()`);
    await sleep(45);
  }
  await js(`(()=>{const e=document.getElementById('q');if(e){e.value=${JSON.stringify(q)};e.dispatchEvent(new Event('input',{bubbles:true}));}})()`);
  await sleep(500);
  const before = await js(`window.__emu.S.chat.length`);
  await mark('asked', { q, send: await click('[data-act="send"]') });
  const ok = await until(`(()=>{const c=window.__emu.S.chat;return c.length>${before}&&c[c.length-1].a&&!/^Asking/i.test(c[c.length-1].a);})()`, 200000);
  await sleep(300);
  await toBottom();
  await sleep(4000);
  await mark('answered', { ok, chat: await js(`window.__emu.S.chat[window.__emu.S.chat.length-1]`) });
}
await send('Page.stopScreencast');
await mark('done', n + ' frames');
writeFileSync(`${out}/frames.json`, JSON.stringify(frames));
ws.close();
proc.kill();
process.exit(0);
