#!/usr/bin/env node
// Builds .website-hosted/tennisbuddy/ for quentinengineering.com/tennisbuddy:
//   /tennisbuddy            info page (website/index.html)
//   /tennisbuddy/emulator   emulator (website/emulator.html) wired to the Fireworks-hosted model
import {cp, mkdir, readFile, rm, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const site = path.resolve(fileURLToPath(new URL('../website/', import.meta.url)));
const out = path.resolve(fileURLToPath(new URL('../.website-hosted/', import.meta.url)));
const dest = path.join(out, 'tennisbuddy');
const ORIGIN = 'https://quentinengineering.com/tennisbuddy';

function swap(text, from, to, label) {
  if (!text.includes(from)) throw new Error(`build: expected text not found (${label}); the page changed`);
  return text.split(from).join(to);
}

await rm(out, {recursive: true, force: true});
await mkdir(dest, {recursive: true});
for (const item of ['emulator', 'img', 'emulator_session.json', 'emulator_sessions.json'])
  await cp(path.join(site, item), path.join(dest, item), {recursive: true});

let emulator = await readFile(path.join(site, 'emulator.html'), 'utf8');
emulator = swap(emulator,
  'const ENGINE={label:"Lemonade · local server",name:"Lemonade",about:"Lemonade runs on this computer and",api:"/api/muse"};',
  'const ENGINE={label:"Fireworks AI · hosted model",name:"the racket model",about:"The racket model is hosted on Fireworks AI and",api:"api/muse"};',
  'ENGINE');
emulator = swap(emulator, '<a href="/emulator">Tennis Buddee</a>', '<a href="./">Tennis Buddee</a>', 'brand link');
emulator = swap(emulator, '<title>Tennis Buddee — iPhone app emulator</title>',
  `<title>Tennis Buddee — iPhone app emulator</title>\n<link rel="canonical" href="${ORIGIN}/emulator">`, 'title');
await writeFile(path.join(dest, 'emulator.html'), emulator);

let info = await readFile(path.join(site, 'index.html'), 'utf8');
info = swap(info, 'href="emulator.html"', 'href="emulator"', 'emulator links');
info = swap(info, '<meta property="og:image" content="img/reveal_serve.jpg">',
  `<meta property="og:image" content="${ORIGIN}/img/reveal_serve.jpg">\n<meta property="og:url" content="${ORIGIN}">\n<link rel="canonical" href="${ORIGIN}">`, 'og:image');
info = swap(info, 'Its Muse features use an offline demo engine. The native app connects to Muse Spark.',
  'Its Racket agent is a small tool-calling model hosted on Fireworks AI; it reads the replay through tools, and every number it quotes comes from those tool results.', 'demo note');
await writeFile(path.join(dest, 'index.html'), info);

console.log(`Built ${out}\n  ${ORIGIN}            <- index.html\n  ${ORIGIN}/emulator   <- emulator.html`);
