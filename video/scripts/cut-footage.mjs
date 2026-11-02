// Cuts the filmed sessions in marketing/Videos into the short clips the X cuts play.
// Prefixes: rh- RobotHype (robot arm, 2026-10-29), bt- BuildLog, ev- EverySwing, hw- Possessed.
// Each clip comes out 30 fps, SDR, square pixels and already at its playback speed:
//   - Sony MAH*.MP4 are 1440x1080 anamorphic (SAR 4:3) -> scaled to 1920x1080
//   - iPhone IMG_*.MOV are 4K60 HLG HDR, mostly portrait -> tone-mapped to SDR; `y` picks the
//     16:9 slice of a portrait frame (0 = top, 1 = bottom); `portrait: true` keeps it 1080x1920
//   - speed < 1 is slow motion (60 fps sources keep every frame at 0.5), > 1 is a timelapse
//   - zoom: [cx, cy, z] crops in z times around (cx, cy) (fractions of the frame), for players
//     who are small in a wide shot (the indoor WSU session)
//
//   FFMPEG=path/to/ffmpeg node scripts/cut-footage.mjs [--src ../marketing/Videos] [name-or-prefix ...]
// Needs an ffmpeg with zscale (the imageio-ffmpeg and gyan.dev builds have it).
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const srcAt = args.indexOf('--src');
const SRC = resolve(srcAt >= 0 ? args.splice(srcAt, 2)[1] : '../marketing/Videos');
const OUT = resolve('public/footage');
const FFMPEG = process.env.FFMPEG ?? 'ffmpeg';

// name -> source clip, in point (s), length of SOURCE used (s), options
export const CUTS = {
  // ===== RobotHype =====
  // hook: one word per beat
  'rh-epson': { src: 'MAH08221.MP4', from: 0.0, dur: 1.0 },
  'rh-rim': { src: 'MAH08222.MP4', from: 0.1, dur: 1.0 },
  'rh-swingin': { src: 'MAH08224.MP4', from: 1.1, dur: 1.2, speed: 1.2 },
  'rh-arm': { src: 'MAH08230.MP4', from: 24.2, dur: 1.4, speed: 1.4 },
  // real arm, before the CGI twin wipes over it
  'rh-reveal': { src: 'MAH08221.MP4', from: 12.3, dur: 3.2 },
  // what the racket measures: one cut per beat
  'rh-strings': { src: 'MAH08223.MP4', from: 0.2, dur: 0.7 },
  'rh-throat': { src: 'IMG_4692.MOV', from: 3.0, dur: 0.7, y: 0.55 },
  'rh-face': { src: 'MAH08225.MP4', from: 4.4, dur: 0.7 },
  'rh-over': { src: 'MAH08230.MP4', from: 19.6, dur: 0.7 },
  'rh-pod': { src: 'IMG_4690.MOV', from: 1.5, dur: 0.7, y: 0.75 },
  'rh-low': { src: 'MAH08223.MP4', from: 4.0, dur: 0.7 },
  'rh-pan': { src: 'IMG_4693.MOV', from: 0.3, dur: 0.7, y: 0.5 },
  'rh-past': { src: 'MAH08221.MP4', from: 1.8, dur: 1.9, speed: 1.3 },
  // into the handle
  'rh-handle': { src: 'MAH08221.MP4', from: 10.9, dur: 1.3, speed: 0.75 },
  // robot swings / racket records (portrait panel)
  'rh-panel': { src: 'IMG_4690.MOV', from: 0.6, dur: 5.2, portrait: true },
  // the test matrix wall (3x3 tiles)
  'rh-t1': { src: 'MAH08219.MP4', from: 70, dur: 44, speed: 8, size: [640, 360] },
  'rh-t2': { src: 'MAH08220.MP4', from: 0, dur: 44, speed: 8, size: [640, 360] },
  'rh-t3': { src: 'MAH08225.MP4', from: 6.9, dur: 5.5, size: [640, 360] },
  'rh-t4': { src: 'MAH08230.MP4', from: 4.9, dur: 5.5, size: [640, 360] },
  'rh-t5': { src: 'IMG_4691.MOV', from: 2.2, dur: 2.75, speed: 0.5, size: [640, 360] },
  'rh-t6': { src: 'MAH08230.MP4', from: 14.7, dur: 5.5, size: [640, 360] },
  'rh-t7': { src: 'MAH08219.MP4', from: 116, dur: 11, speed: 2, size: [640, 360] },
  'rh-t8': { src: 'MAH08231.MP4', from: 0, dur: 2.75, speed: 0.5, size: [640, 360] },
  'rh-t9': { src: 'MAH08221.MP4', from: 4.1, dur: 5.5, size: [640, 360] },
  // finale: looking down the throat at the arm
  'rh-pov': { src: 'IMG_4692.MOV', from: 4.6, dur: 2.6, speed: 0.6, portrait: true },

  // ===== BuildLog: the bench (Oct 26-28), the robot, the court (Oct 17) =====
  'bt-smoke': { src: 'MAH08213.MP4', from: 40.0, dur: 2.2 }, // iron on the board, smoke rising
  'bt-bench': { src: 'MAH08210.MP4', from: 5.0, dur: 2.2 },
  'bt-solder': { src: 'MAH08213.MP4', from: 58.5, dur: 1.2 },
  'bt-solder2': { src: 'MAH08213.MP4', from: 23.0, dur: 1.2 },
  'bt-pcb': { src: 'MAH08214.MP4', from: 5.0, dur: 1.2 }, // board going into the printed pod
  'bt-pod': { src: 'MAH08214.MP4', from: 33.6, dur: 0.8 }, // the pod's octagonal end, face on
  'bt-code': { src: 'MAH08211.MP4', from: 264, dur: 1.2 },
  'bt-code2': { src: 'MAH08211.MP4', from: 330, dur: 1.2 },
  'bt-cad': { src: 'MAH08208.MP4', from: 0.3, dur: 1.5 }, // the desk, CAD of the test rig on the monitor
  'bt-wired': { src: 'MAH08211.MP4', from: 27, dur: 0.7 },
  'bt-wired2': { src: 'MAH08211.MP4', from: 82, dur: 0.7 },
  'bt-room': { src: 'MAH08212.MP4', from: 5.0, dur: 0.7 },
  'bt-room2': { src: 'MAH08212.MP4', from: 24.0, dur: 0.7 },
  'bt-gate': { src: 'MAH08203.MP4', from: 3.4, dur: 2.2 },
  'bt-gate2': { src: 'MAH08203.MP4', from: 5.6, dur: 1.5 }, // carries on from bt-gate: push to the racket
  // indoor session (Oct 28): four hits, one per beat
  'bt-in1': { src: 'MAH08218.MP4', from: 29.9, dur: 0.6, zoom: [0.35, 0.48, 1.5] },
  'bt-in2': { src: 'MAH08218.MP4', from: 33.2, dur: 0.6, zoom: [0.7, 0.6, 1.5] },
  'bt-in3': { src: 'MAH08218.MP4', from: 38.8, dur: 0.6, zoom: [0.47, 0.62, 1.6] },
  'bt-in4': { src: 'MAH08217.MP4', from: 59.6, dur: 0.6, zoom: [0.85, 0.48, 2.0] },

  // ===== EverySwing: on court (Oct 17) =====
  'ev-toss': { src: 'MAH08198.MP4', from: 0.0, dur: 1.7 },
  'ev-toss2': { src: 'MAH08198.MP4', from: 3.3, dur: 1.4 },
  'ev-serve': { src: 'MAH08198.MP4', from: 4.7, dur: 1.4 },
  'ev-1': { src: 'MAH08218.MP4', from: 25.4, dur: 0.9, zoom: [0.62, 0.55, 1.5] },
  'ev-2': { src: 'MAH08218.MP4', from: 28.6, dur: 0.9, zoom: [0.42, 0.5, 1.35] },
  'ev-3': { src: 'MAH08194.MP4', from: 6.8, dur: 0.9 },
  'ev-4': { src: 'MAH08199.MP4', from: 8.0, dur: 0.9 },
  'ev-5': { src: 'MAH08217.MP4', from: 45.1, dur: 0.9, zoom: [0.78, 0.45, 1.8] },
  'ev-6': { src: 'MAH08218.MP4', from: 26.6, dur: 0.9, zoom: [0.5, 0.55, 1.5] },
  'ev-7': { src: 'MAH08193.MP4', from: 7.0, dur: 0.9 },
  'ev-8': { src: 'MAH08217.MP4', from: 30.5, dur: 0.9, zoom: [0.5, 0.5, 1.1] }, // the whole hall playing
  'ev-9': { src: 'MAH08218.MP4', from: 37.4, dur: 0.8, zoom: [0.36, 0.5, 1.5] },
  'ev-10': { src: 'MAH08217.MP4', from: 36.6, dur: 0.8, zoom: [0.62, 0.55, 1.6] },
  'ev-11': { src: 'MAH08218.MP4', from: 15.8, dur: 0.8, zoom: [0.55, 0.6, 1.3] },
  'ev-12': { src: 'MAH08218.MP4', from: 31.0, dur: 0.8, zoom: [0.5, 0.48, 1.35] },
  'ev-phone': { src: 'MAH08200.MP4', from: 11.4, dur: 2.6 }, // the app on the phone, racket in the other hand
  'ev-check': { src: 'MAH08201.MP4', from: 9.6, dur: 2.6 },
  'ev-sky': { src: 'MAH08197.MP4', from: 0.0, dur: 2.6 },
  'ev-sky2': { src: 'MAH08197.MP4', from: 2.3, dur: 2.6 },
  'ev-net': { src: 'MAH08204.MP4', from: 4.3, dur: 1.8 },

  // ===== Possessed (Halloween) =====
  'hw-net': { src: 'MAH08206.MP4', from: 0.0, dur: 2.4 },
  'hw-creep': { src: 'MAH08205.MP4', from: 2.0, dur: 2.4 },
  'hw-grip': { src: 'MAH08204.MP4', from: 2.4, dur: 1.3 },
  // the indoor session was in costume: the swings, with the onlookers (and a yellow onesie)
  'hw-sw1': { src: 'MAH08218.MP4', from: 3.6, dur: 1.3, zoom: [0.38, 0.48, 1.7] },
  'hw-sw2': { src: 'MAH08218.MP4', from: 12.6, dur: 1.3, zoom: [0.33, 0.45, 1.6] },
  'hw-sw3': { src: 'MAH08218.MP4', from: 8.0, dur: 1.3, zoom: [0.45, 0.45, 1.7] },
  'hw-xray': { src: 'MAH08204.MP4', from: 0.0, dur: 1.3 },
  'hw-robot1': { src: 'MAH08221.MP4', from: 12.3, dur: 1.3 },
  'hw-robot2': { src: 'MAH08224.MP4', from: 1.0, dur: 1.3 },
  'hw-robot3': { src: 'MAH08230.MP4', from: 19.4, dur: 1.3 },
  'hw-robot4': { src: 'MAH08223.MP4', from: 4.0, dur: 1.3 },
  'hw-lineup': { src: 'MAH08218.MP4', from: 22.0, dur: 2.4, zoom: [0.33, 0.45, 1.5] },
  'hw-lunge': { src: 'MAH08217.MP4', from: 89.4, dur: 2.4, zoom: [0.6, 0.5, 1.4] },
  'hw-ball': { src: 'MAH08196.MP4', from: 12.8, dur: 1.5 },
};

// Stills of the real location that sit behind the CGI, so the room carries on when the shot
// turns into CAD. name -> source clip, time (s)
export const STILLS = {
  'rh-plate-handle': { src: 'MAH08221.MP4', at: 11.4 },
  'rh-plate-lab': { src: 'MAH08221.MP4', at: 15.4 },
  'bt-plate-bench': { src: 'MAH08214.MP4', at: 20.0 },
  'ev-plate-court': { src: 'MAH08199.MP4', at: 14.4 },
  'hw-plate-net': { src: 'MAH08204.MP4', at: 6.5 },
};

const HDR = 'zscale=t=linear:npl=203:tin=arib-std-b67:min=bt2020nc:pin=bt2020,format=gbrpf32le,zscale=p=bt709,tonemap=hable:desat=0:peak=4,zscale=t=bt709:m=bt709:r=tv';

const filter = (c) => {
  const [w, h] = c.portrait ? [1080, 1920] : c.size ?? [1920, 1080];
  const f = [];
  if (c.src.endsWith('.MOV')) f.push(HDR);
  f.push('scale=iw*sar:ih,setsar=1'); // anamorphic -> square pixels
  // cover w x h; `y` places the crop window on tall sources
  f.push(`scale=${w}:${h}:force_original_aspect_ratio=increase`);
  f.push(`crop=${w}:${h}:(iw-${w})/2:(ih-${h})*${c.y ?? 0.5}`);
  if (c.zoom) {
    const [cx, cy, z] = c.zoom, cw = Math.round(w / z / 2) * 2, ch = Math.round(h / z / 2) * 2;
    const x = Math.round(Math.min(w - cw, Math.max(0, w * cx - cw / 2))), y = Math.round(Math.min(h - ch, Math.max(0, h * cy - ch / 2)));
    f.push(`crop=${cw}:${ch}:${x}:${y}`, `scale=${w}:${h}:flags=lanczos`);
  }
  if (c.speed && c.speed !== 1) f.push(`setpts=PTS/${c.speed}`);
  f.push('fps=30', 'format=yuv420p');
  return f.join(',');
};

mkdirSync(OUT, { recursive: true });
const only = args.filter((a) => !a.startsWith('--'));
const wanted = (name) => !only.length || only.some((o) => name === o || (o.endsWith('-') && name.startsWith(o)));
for (const [name, c] of Object.entries(CUTS)) {
  if (!wanted(name)) continue;
  const input = resolve(SRC, c.src);
  if (!existsSync(input)) { console.warn(`skip ${name}: missing ${input}`); continue; }
  const r = spawnSync(FFMPEG, [
    '-hide_banner', '-loglevel', 'error', '-y', '-ss', String(c.from), '-t', String(c.dur), '-i', input,
    '-vf', filter(c), '-an', '-c:v', 'libx264', '-crf', '16', '-preset', 'medium', '-movflags', '+faststart',
    resolve(OUT, `${name}.mp4`),
  ], { stdio: 'inherit' });
  console.log(`${r.status === 0 ? 'ok  ' : 'FAIL'} ${name}  (${(c.dur / (c.speed ?? 1)).toFixed(2)} s)`);
}
for (const [name, c] of Object.entries(STILLS)) {
  if (!wanted(name)) continue;
  const r = spawnSync(FFMPEG, [
    '-hide_banner', '-loglevel', 'error', '-y', '-ss', String(c.at), '-i', resolve(SRC, c.src),
    '-vf', filter({ ...c, dur: 0 }), '-frames:v', '1', '-q:v', '2', resolve(OUT, `${name}.jpg`),
  ], { stdio: 'inherit' });
  console.log(`${r.status === 0 ? 'ok  ' : 'FAIL'} ${name}  (still)`);
}
