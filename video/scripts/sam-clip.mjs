// Cuts the real clip and the real SAM 3.1 boxes behind the samTrack scene. Uses only the cache from
// ml/stroke_system (no API call, no cost). Each source frame becomes one video frame (240 fps -> about 8x slow).
//   npm run sam            candidate 24
//   npm run sam -- 18      any candidate in ml/stroke_system/artifacts/sam-contact-review
// Needs the local recording in data/Tennis Camera/ (not in git). Without it, only the boxes are written.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const candidate = Number(process.argv[2] ?? 24);
const pad = String(candidate).padStart(2, '0');
const root = resolve('..');
const cache = resolve(root, 'ml/stroke_system/artifacts/sam-contact-review');
const events = resolve(root, 'ml/stroke_system/evidence/tenniscamera-1005-reviewed-events.csv');
const source = resolve(root, 'data/Tennis Camera/10-29-26-1005/video.mov');
const FFMPEG = process.env.FFMPEG ?? 'ffmpeg';
// ffmpeg's frame numbers run ahead of the cache's on this recording. Measured on candidate 24 by matching the
// ball box to the yellow ball in each frame: 1 px median error at this offset, 34 px with none.
const ALIGN_FRAMES = 12;

const load = (prompt) => JSON.parse(readFileSync(resolve(cache, `candidate-${pad}-${prompt}.json`), 'utf8'));
const racket = load('racket');
const ball = existsSync(resolve(cache, `candidate-${pad}-ball.json`)) ? load('ball') : null;

// [x1, y1, x2, y2, confidence] for the most confident box in a frame, or null.
const best = (o) => {
  if (!o?.boxes?.length) return null;
  const b = o.boxes.reduce((a, c) => (c[5] > a[5] ? c : a));
  return [b[1], b[2], b[3], b[4], Math.round(b[5] * 100) / 100];
};
const row = readFileSync(events, 'utf8').split('\n').map((l) => l.split(',')).find((c) => Number(c[1]) === candidate);
const contactFrame = row ? Number(row[2]) : null;

const start = racket.start_frame;
const n = racket.observations.length;
const track = {
  model: racket.model,
  candidate,
  width: racket.width,
  height: racket.height,
  startFrame: start,
  contactIndex: contactFrame === null ? null : contactFrame - start,
  racket: racket.observations.map(best),
  ball: ball ? ball.observations.map(best) : [],
};
mkdirSync('src/config/generated', { recursive: true });
writeFileSync('src/config/generated/samTrack.json', `${JSON.stringify(track)}\n`);
console.log(`candidate ${candidate}: frames ${start}..${start + n - 1}, contact index ${track.contactIndex}`);

if (!existsSync(source)) { console.warn(`missing ${source}: wrote the boxes, skipped the clip`); process.exit(0); }
const out = resolve('public/footage/sam-clip.mp4');
const r = spawnSync(FFMPEG, ['-y', '-v', 'error', '-i', source, '-vf',
  `select='between(n,${start - ALIGN_FRAMES},${start - ALIGN_FRAMES + n - 1})',setpts=N/30/TB,scale=1920:1080,format=yuv420p`,
  '-fps_mode', 'cfr', '-r', '30', '-an', '-c:v', 'libx264', '-crf', '18', '-preset', 'fast', out], { stdio: 'inherit' });
if (r.status !== 0) process.exit(r.status ?? 1);
console.log(out);
