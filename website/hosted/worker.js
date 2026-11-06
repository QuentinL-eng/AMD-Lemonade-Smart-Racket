// Cloudflare Worker for quentinengineering.com/tennisbuddy.
// Static pages are served by the assets binding; only /tennisbuddy/api/muse reaches this code. It maps the
// Fireworks secrets onto the engine settings the shared agent (../api/muse-worker.js) already understands.
import museWorker from '../api/muse-worker.js';

const BASE = '/tennisbuddy';
const LIMIT = 20, WINDOW_MS = 60000; // per client per minute, best effort per isolate
const seen = new Map();

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== BASE + '/api/muse') return env.ASSETS.fetch(request);
    const json = (data, status) => Response.json(data, {status, headers: {'Cache-Control': 'no-store'}});
    if (!env.FIREWORKS_API_KEY || !env.FIREWORKS_MODEL) return json({error: 'The racket agent is not configured yet.'}, 503);

    const client = request.headers.get('CF-Connecting-IP') || 'unknown', now = Date.now();
    const recent = (seen.get(client) || []).filter(t => now - t < WINDOW_MS);
    if (recent.length >= LIMIT) return json({error: 'Too many requests. Please wait a minute.'}, 429);
    recent.push(now); seen.set(client, recent);
    if (seen.size > 5000) for (const [k, v] of seen) if (!v.some(t => now - t < WINDOW_MS)) seen.delete(k);

    return museWorker.fetch(new Request(new URL('/api/muse', url), request), {
      ASSETS: env.ASSETS,
      UPSTREAM_STYLE: 'fireworks',
      SORT_REQUEST_KEYS: env.SORT_TOOL_KEYS || 'false',
      ENGINE_LABEL: 'Fireworks AI · hosted model',
      LEMONADE_MODEL: env.FIREWORKS_MODEL,
      LEMONADE_BASE_URL: env.FIREWORKS_BASE_URL || 'https://api.fireworks.ai/inference/v1',
      LEMONADE_API_KEY: env.FIREWORKS_API_KEY,
    });
  },
};
