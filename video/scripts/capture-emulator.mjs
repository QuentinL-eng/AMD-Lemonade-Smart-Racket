// Records the live tennisbuddy.net/emulator with headless Chrome over the DevTools protocol: real clicks, real Muse calls.
//   node capture-emulator.mjs <chrome> <outdir>
// Writes frames/NNNNN.jpg, frames.json (timestamps) and log.json (when each step happened, and what Muse answered).
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';

const [chrome, out] = process.argv.slice(2);
mkdirSync(`${out}/frames`, { recursive: true });
const proc = spawn(chrome, ['--headless', '--remote-debugging-port=9334', `--user-data-dir=${out}/profile`, '--window-size=1920,1200',
  '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let target;
for (let i = 0; i < 40 && !target; i++) {
  await sleep(500);
  try { target = (await (await fetch('http://127.0.0.1:9334/json')).json()).find((t) => t.type === 'page'); } catch {}
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
  const e = { step, t: Date.now() };
  if (extra) e.extra = extra;
  log.push(e);
  writeFileSync(`${out}/log.json`, JSON.stringify(log, null, 1));
  writeFileSync(`${out}/frames.json`, JSON.stringify(frames));
  console.log(((e.t - t0) / 1000).toFixed(1), step, extra ? String(extra).slice(0, 700) : '');
};
const click = (sel) => js(`(()=>{const e=document.querySelector(${JSON.stringify(sel)});if(!e)return 'missing';e.click();return 'ok';})()`);
const until = async (expr, ms) => { const end = Date.now() + ms; while (Date.now() < end) { if (await js(expr)) return true; await sleep(500); } return false; };
const phoneText = () => js(`document.querySelector('#view,.screen,.phone')?.innerText?.replace(/\\s+/g,' ').slice(0,900) ?? ''`);

await send('Page.enable');
await send('Runtime.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1200, deviceScaleFactor: 1, mobile: false });
await send('Page.navigate', { url: 'https://tennisbuddy.net/emulator' });
await sleep(6000);
await js(`document.documentElement.style.zoom='1.5';window.dispatchEvent(new Event('resize'))`);
await sleep(2000);
await send('Page.startScreencast', { format: 'jpeg', quality: 90, everyNthFrame: 1, maxWidth: 1920, maxHeight: 1200 });
await mark('ready');
await sleep(1500);
await mark('start session', await click('[data-act="session"]'));
await sleep(24000);
await mark('live played', await js(`window.__emu.S.shown + ' shots shown'`));
await js(`window.__emu.skipToEnd()`);
await sleep(800);
await mark('skipped to end');
await js(`window.__emu.setTab('muse')`);
await sleep(2500);
await mark('muse tab', await phoneText());
await mark('findfilm', await click('[data-act="findfilm"]'));
const film = await until(`!!window.__emu.S.film`, 200000);
await sleep(3000);
await mark('film result', film + ' ' + JSON.stringify(await js(`(()=>{const f=window.__emu.S.film;return f&&{title:f.title,cue:f.cue,d:f.d};})()`)));
await mark('openwi', await click('[data-act="openwi"]'));
await sleep(11000);
await mark('whatif shown', await phoneText());
const scrollTo = (text) => js(`(()=>{const el=[...document.querySelectorAll('*')].filter(e=>e.children.length<3&&e.innerText&&e.innerText.includes(${JSON.stringify(text)})).pop();if(!el)return 'missing';let c=el.parentElement;while(c&&!(c.scrollHeight>c.clientHeight+4&&/auto|scroll/.test(getComputedStyle(c).overflowY)))c=c.parentElement;if(!c)return 'noscroll';const a=el.getBoundingClientRect().top-c.getBoundingClientRect().top+c.scrollTop-120;c.scrollTo({top:a,behavior:'smooth'});return 'ok '+c.className;})()`);

await mark('back', await click('[data-act="back"]'));
await sleep(1500);
await mark('drill', await click('[data-act="drill"]'));
const drill = await until(`!!window.__emu.S.drill`, 200000);
await sleep(2500);
await mark('drill result', drill + ' ' + JSON.stringify(await js(`window.__emu.S.drill`)));
await mark('rundrill', await click('[data-act="rundrill"]'));
await sleep(3000);
await mark('ask', await click('[data-act="ask"]'));
const asked = await until(`(()=>{const c=window.__emu.S.chat;return c.length&&c[c.length-1].a&&!/^Asking/i.test(c[c.length-1].a);})()`, 200000);
await sleep(4000);
await mark('ask result', asked + ' ' + JSON.stringify(await js(`window.__emu.S.chat`)));
await send('Page.stopScreencast');
await mark('done', n + ' frames');
writeFileSync(`${out}/frames.json`, JSON.stringify(frames));
ws.close();
proc.kill();
process.exit(0);
