// Copies shared assets from the app and video assets into public/ so the video always
// uses the same icon and photos as the product. Runs before studio/render.
// (Most scenes use the procedural racket in src/components/Racket.tsx. The reveal uses the app's real model.)
import { copyFileSync, mkdirSync, existsSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const pub = resolve(dirname(fileURLToPath(import.meta.url)), '..', 'public');

const assets = {
  'img/icon.png': 'apple/Shared/Assets.xcassets/AppIcon.appiconset/icon-1024.png',
  'img/court.jpg': 'video/assets/court-hires.jpg',
  'models/TennisRacket.glb': 'video/assets/TennisRacket.glb',
};

for (const [dest, src] of Object.entries(assets)) {
  const from = join(root, src);
  const to = join(pub, dest);
  if (!existsSync(from)) { console.warn(`missing ${src}`); continue; }
  if (existsSync(to) && statSync(to).mtimeMs >= statSync(from).mtimeMs) continue;
  mkdirSync(dirname(to), { recursive: true });
  copyFileSync(from, to);
  console.log(`copied ${src} -> public/${dest}`);
}

