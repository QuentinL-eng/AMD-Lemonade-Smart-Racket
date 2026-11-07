// Cloudflare Worker for quentinengineering.com/tennisbuddee.
// Static pages are served by the assets binding; only /tennisbuddee/api/* reaches this code. It maps the
// AGENT_* settings onto what the shared agent (../api/muse-worker.js) understands. The model runs on Modal
// (vLLM, tools/modal_serve.py), which scales to zero, so /api/warm starts it while a visitor browses.
import museWorker from '../api/muse-worker.js';

const BASE = '/tennisbuddee';
const LIMIT = 20, WINDOW_MS = 60000; // per client per minute, best effort per isolate
const seen = new Map();

function limited(client, now) {
  const recent = (seen.get(client) || []).filter(t => now - t < WINDOW_MS);
  if (recent.length >= LIMIT) return true;
  recent.push(now); seen.set(client, recent);
  if (seen.size > 5000) for (const [k, v] of seen) if (!v.some(t => now - t < WINDOW_MS)) seen.delete(k);
  return false;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const isAgent = url.pathname === BASE + '/api/muse', isWarm = url.pathname === BASE + '/api/warm';
    if (!isAgent && !isWarm) return env.ASSETS.fetch(request);
    const json = (data, status) => Response.json(data, {status, headers: {'Cache-Control': 'no-store'}});
    if (!env.AGENT_API_KEY || !env.AGENT_MODEL || !env.AGENT_BASE_URL) return json({error: 'The racket agent is not configured yet.'}, 503);
    if (limited(request.headers.get('CF-Connecting-IP') || 'unknown', Date.now())) return json({error: 'Too many requests. Please wait a minute.'}, 429);

    if (isWarm) {
      if (request.method !== 'POST' || request.headers.get('Origin') !== url.origin) return json({error: 'Not allowed'}, 403);
      ctx.waitUntil(fetch(env.AGENT_BASE_URL.replace(/\/v1\/?$/, '') + '/health', {signal: AbortSignal.timeout(120000)}).catch(() => {}));
      return json({warming: true}, 202);
    }
    return museWorker.fetch(new Request(new URL('/api/muse', url), request), {
      ASSETS: env.ASSETS,
      UPSTREAM_STYLE: 'hosted',
      ENGINE_LABEL: 'Modal · hosted model',
      LEMONADE_MODEL: env.AGENT_MODEL,
      LEMONADE_BASE_URL: env.AGENT_BASE_URL,
      LEMONADE_API_KEY: env.AGENT_API_KEY,
      SORT_REQUEST_KEYS: env.SORT_TOOL_KEYS || 'false',
    });
  },
};
