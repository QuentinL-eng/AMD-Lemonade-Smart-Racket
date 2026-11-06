#!/usr/bin/env node
// One command for judges: offline checks, a Lemonade probe with exact fix-it commands, then the emulator.
//   node tools/judge-demo.mjs            # checks, then serve http://localhost:8765/emulator
//   node tools/judge-demo.mjs --check    # checks and probe only, do not start the server
// Node 20+, no packages. Lemonade is optional: without it the emulator still opens, only the agent is offline.
import {spawn, spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const model = process.env.LEMONADE_MODEL || 'Qwen3-1.7B-GGUF';
const base = process.env.LEMONADE_BASE_URL || 'http://127.0.0.1:8000/api/v1';
const port = process.env.EMULATOR_PORT || '8765';

const checks = spawnSync(process.execPath, ['tools/judge-check.mjs', '--offline'], {cwd: root, stdio: 'inherit'});
if (checks.status !== 0) {
  console.error('\nOffline checks failed; not starting the demo.');
  process.exit(checks.status || 1);
}

try {
  const headers = process.env.LEMONADE_API_KEY ? {Authorization: 'Bearer ' + process.env.LEMONADE_API_KEY} : {};
  const response = await fetch(base + '/models', {headers, signal: AbortSignal.timeout(4000)});
  if (!response.ok) throw Error('HTTP ' + response.status);
  const ids = (await response.json()).data?.map(m => m.id) ?? [];
  if (ids.includes(model)) console.log(`\nLemonade reachable at ${base}; model ${model} is downloaded.`);
  else console.log(`\nLemonade is reachable but ${model} is not downloaded. Run:\n  lemonade pull ${model}\n  lemonade load ${model} --ctx-size 8192`);
} catch (error) {
  console.log(`\nLemonade not reachable at ${base} (${error.message}). The emulator will still open; the agent will report offline.\nInstall: https://lemonade-server.ai/docs/guide/install/ then:\n  lemonade pull ${model}\n  lemonade load ${model} --ctx-size 8192`);
}

if (process.argv.includes('--check')) process.exit(0);
console.log(`\nStarting the emulator. Open http://localhost:${port}/emulator, press Start Session, skip to the end, open Racket agent. Ctrl+C to stop.\n`);
const server = spawn(process.execPath, ['tools/emulator-server.mjs'], {cwd: root, stdio: 'inherit', env: process.env});
server.on('exit', code => process.exit(code ?? 0));
process.on('SIGINT', () => server.kill('SIGINT'));
