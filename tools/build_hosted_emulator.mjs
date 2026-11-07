#!/usr/bin/env node
// Builds .website-hosted/tennisbuddee/ for quentinengineering.com/tennisbuddee:
//   /tennisbuddee            info page (website/index.html) with the overview video
//   /tennisbuddee/paper      white paper (docs/WHITE_PAPER.html)
//   /tennisbuddee/emulator   emulator (website/emulator.html) wired to the hosted model
import {cp, mkdir, readFile, rm, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const site = path.resolve(fileURLToPath(new URL('../website/', import.meta.url)));
const out = path.resolve(fileURLToPath(new URL('../.website-hosted/', import.meta.url)));
const dest = path.join(out, 'tennisbuddee');
const VIDEO = 'wqH2P8v8PkI';
const ORIGIN = 'https://quentinengineering.com/tennisbuddee';

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
  'const ENGINE={label:"Lemonade · local server",name:"Lemonade",about:"Lemonade runs on this computer and",api:"/api/muse",warm:null};',
  'const ENGINE={label:"Modal · hosted model",name:"the racket model",about:"The racket model is hosted on Modal and",api:"api/muse",warm:"api/warm"};',
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
  'Its Racket agent is a small tool-calling model hosted on Modal; it reads the replay through tools, and every number it quotes comes from those tool results.', 'demo note');
info = swap(info, '<h3>Meta Muse Spark</h3><p>Muse Spark uses your shots', '<h3>Racket agent</h3><p>A small tool-calling model uses your shots', 'agent card');
info = swap(info, '<a class="btn alt" href="https://testflight.apple.com/join/137F7kvd">Get the iPhone beta</a>', '', 'iPhone beta link');
info = swap(info, 'Open <strong>Muse', 'Open <strong>Racket agent', 'first session');
info = swap(info, 'Live, Score, Muse, Insights', 'Live, Score, Racket agent, Insights', 'five tabs');
info = swap(info, '<a href="#features">Features</a>', '<a href="#features">Features</a><a href="#video">Video</a><a href="paper">Paper</a>', 'nav');
info = swap(info, '</style>', `.video { padding-block: 72px; background: var(--paper); }
.video h2 { font-family: var(--display); font-weight: 800; letter-spacing: -0.03em; font-size: clamp(32px, 5vw, 56px); line-height: 1; margin: 8px 0 24px; }
.video .frame { position: relative; aspect-ratio: 16 / 9; border-radius: 18px; overflow: hidden; background: var(--ink); max-width: 960px; }
.video iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
.video p { color: var(--muted); max-width: 60ch; }
</style>`, 'style');
info = swap(info, '<main>', `<main>
<section class="video" id="video" aria-labelledby="video-title"><div class="wrap">
  <p class="label">Overview</p>
  <h2 id="video-title">See it in action.</h2>
  <div class="frame"><iframe src="https://www.youtube-nocookie.com/embed/${VIDEO}" title="Tennis Buddee overview video" loading="lazy" allow="accelerometer; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div>
  <p>Also on <a href="https://youtu.be/${VIDEO}">YouTube</a>. Read the <a href="paper">white paper</a> or <a href="emulator">try the emulator</a>.</p>
</div></section>
`, 'main');
await writeFile(path.join(dest, 'index.html'), info);

await cp(path.resolve(fileURLToPath(new URL('../docs/WHITE_PAPER.html', import.meta.url))), path.join(dest, 'paper.html'));

console.log(`Built ${out}\n  ${ORIGIN}            <- index.html\n  ${ORIGIN}/paper      <- docs/WHITE_PAPER.html
  ${ORIGIN}/emulator   <- emulator.html`);
