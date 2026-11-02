// Renders several frames of one composition from a single bundle (much faster than one
// `remotion still` per frame).  node scripts/stills.mjs RobotHype 129 150 171 [--scale 0.5]
import { bundle } from '@remotion/bundler';
import { renderStill, selectComposition } from '@remotion/renderer';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const scaleAt = args.indexOf('--scale');
const scale = scaleAt >= 0 ? Number(args.splice(scaleAt, 2)[1]) : 0.5;
const [id, ...frames] = args;
const serveUrl = await bundle({ entryPoint: resolve('src/index.ts') });
const composition = await selectComposition({ serveUrl, id });
mkdirSync('out/review', { recursive: true });
for (const frame of frames.map(Number)) {
  const output = resolve(`out/review/${id}-${frame}.jpg`);
  await renderStill({ serveUrl, composition, frame, output, imageFormat: 'jpeg', jpegQuality: 85, scale, timeoutInMilliseconds: 120_000 });
  console.log(output);
}
