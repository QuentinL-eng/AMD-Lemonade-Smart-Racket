// Muse Spark proxy: Meta's open Muse Spark, served by Baseten (OpenAI-compatible). The Baseten key lives only in
// this function's secrets (BASETEN_API_KEY); the app authenticates with the signed-in user's Supabase session.
// MUSE_MODEL defaults to meta-models/muse-spark-open-1026. MUSE_BASE_URL points at another OpenAI-compatible host;
// MUSE_REASONING_EFFORT is optional and unset by default.
import { createClient } from "npm:@supabase/supabase-js@2";

const BASE_URL = Deno.env.get("MUSE_BASE_URL") ?? "https://inference.baseten.co/v1";
const ENDPOINT = `${BASE_URL}/chat/completions`;
const MODEL = Deno.env.get("MUSE_MODEL") ?? "meta-models/muse-spark-open-1026";
const EFFORT = Deno.env.get("MUSE_REASONING_EFFORT");
const MAX_BODY_BYTES = 256 * 1024;

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) return json({ error: "too large" }, 413);
  let input: Record<string, unknown>;
  try { input = JSON.parse(raw); } catch { return json({ error: "bad json" }, 400); }
  if (!Array.isArray(input.messages)) return json({ error: "messages required" }, 400);

  const key = Deno.env.get("BASETEN_API_KEY");
  if (!key) return json({ error: "model not configured" }, 500);

  // Only forward fields the app needs, with the model and limits pinned server-side.
  const body: Record<string, unknown> = {
    model: MODEL,
    messages: input.messages,
    max_completion_tokens: Math.min(Number(input.max_completion_tokens) || 4096, 4096),
  };
  if (EFFORT) body.reasoning_effort = EFFORT;
  if (Array.isArray(input.tools) && input.tools.length > 0) {
    body.tools = input.tools;
    body.tool_choice = "auto";
  }

  const upstream = await fetch(ENDPOINT, {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(40_000),
  }).catch(() => null);
  if (!upstream) return json({ error: "upstream unreachable" }, 502);
  return new Response(upstream.body, { status: upstream.status, headers: { "Content-Type": "application/json" } });
});
