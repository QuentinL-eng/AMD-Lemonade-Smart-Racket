// Renders the Demo's pieces as separate files, for cutting in an outside editor (CapCut, Premiere, Resolve):
//   out/clips/NN-<scene>.mp4        each CGI scene, with its sound effects
//   out/clips/overlay-<id>.mov      each entry's overlays, ProRes 4444 with transparency
//
//   npm run clips                   everything
//   npm run clips -- evidence       only ids containing "evidence"
import { bundle } from '@remotion/bundler';
import { renderMedia, selectComposition } from '@remotion/renderer';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { demo } from '../src/config/timeline.ts';

const only = process.argv[2];
const serveUrl = await bundle({ entryPoint: resolve('src/index.ts') });
mkdirSync('out/clips', { recursive: true });

const render = async (id, output, options) => {
  if (only && !id.includes(only)) return;
  const composition = await selectComposition({ serveUrl, id });
  await renderMedia({ serveUrl, composition, outputLocation: resolve(output), concurrency: 4, chromiumOptions: { gl: 'angle' }, timeoutInMilliseconds: 120_000, ...options });
  console.log(output);
};

for (const [i, e] of demo.entries()) {
  const n = String(i + 1).padStart(2, '0');
  const id = e.scene ?? e.footage;
  if (e.scene) await render(`scene-${id}`, `out/clips/${n}-${id}.mp4`, { codec: 'h264', crf: 18 });
  if (e.overlays) await render(`overlay-${id}`, `out/clips/overlay-${n}-${id}.mov`, { codec: 'prores', proResProfile: '4444', imageFormat: 'png', pixelFormat: 'yuva444p10le' });
}
