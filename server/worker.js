/**
 * Mira AI proxy — Cloudflare Worker.
 *
 * Holds the API key (as a secret) so it NEVER ships inside the app.
 * The Flutter app POSTs the conversation here; this worker adds Mira's
 * persona, calls the model via OpenRouter, and returns a single reply.
 *
 * Why OpenRouter: it works from Cloudflare (unlike calling Google's Gemini
 * directly, which blocks Cloudflare's server regions), needs no credit card,
 * and gives one key for many free models (DeepSeek, Llama, Gemini, etc).
 *
 * Deploy: see server/README.md
 * Secret required: OPENROUTER_API_KEY  (get one free at https://openrouter.ai/keys)
 */

// Free OpenRouter models (IDs ending in :free cost $0). The worker tries these
// in order and uses the first that responds — so if one pool is busy, Mira
// still answers instead of failing. Override with a "model" field or MODEL env.
const MODELS = [
  "openai/gpt-oss-120b:free",
  "meta-llama/llama-3.3-70b-instruct:free",
  "qwen/qwen3-next-80b-a3b-instruct:free",
  "openai/gpt-oss-20b:free",
];

const ENDPOINT = "https://openrouter.ai/api/v1/chat/completions";

// Mira's voice. This is the anti-generic guardrail — short, warm, human,
// never the "It's important to remember..." filler that makes AI feel canned.
const PERSONA = `
You are Mira, a calm parenting companion for parents of children aged 0-3.
Your voice: warm, grounded, professional, never preachy. Like a wise friend who
happens to know child development — not a textbook, not a chatbot.

HARD RULES:
- Keep replies SHORT: 2-4 sentences, or up to 4 tiny steps. A tired parent reads in one glance.
- Lead by validating the feeling in one line ("That sounds exhausting." / "Totally normal to worry about this.").
- Then give ONE concrete, doable thing to try right now. Not a list of ten.
- Plain words. No jargon. No lectures. No "it's important to note", no "as an AI", no bullet-point essays.
- Be specific to the child's age when it helps.
- Ground advice in mainstream child-development thinking (responsive parenting, age-appropriate expectations, emotional co-regulation) WITHOUT citing studies or sounding academic.
- Warm, real, a little gentle humor is okay. Never robotic.

SAFETY:
- You are NOT a doctor. For anything about fevers, breathing, injuries, rashes, weight,
  medication, dehydration, or "is my baby sick" — give brief reassurance if appropriate,
  then clearly say to contact their pediatrician or emergency services. Do not diagnose.
- If a parent sounds like they might harm themselves or the child, gently and briefly
  urge them to reach out to a real person or a crisis line right now.
`;

const CALM_ADDON = `
CALM MODE: The meltdown is happening RIGHT NOW. Be ultra-brief and directive.
Speak in the present tense, like a calm voice in their ear. One short instruction at a time.
Start with the parent's own breathing. No theory at all.
`;

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders() });
    }
    if (request.method !== "POST") {
      return json({ error: "POST only" }, 405);
    }
    if (!env.OPENROUTER_API_KEY) {
      return json({ error: "Server not configured (missing key)." }, 500);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: "Bad request." }, 400);
    }

    const baby = payload.baby || {};
    const mode = payload.mode === "calm" ? "calm" : "chat";
    const history = Array.isArray(payload.messages) ? payload.messages : [];
    const ctx = typeof payload.context === "string" ? payload.context : "";

    const system =
      PERSONA +
      (mode === "calm" ? CALM_ADDON : "") +
      `\nCONTEXT: The child is named ${baby.name || "the baby"}, about ${
        baby.ageMonths ?? "?"
      } months old.` +
      (ctx
        ? `\nWHAT'S HAPPENING WITH THIS BABY (from the parent's own logs): ${ctx}\n` +
          `Use these real details to make your answer specific to THIS baby — reference their actual day when relevant. Never invent data you weren't given.`
        : "");

    // Build OpenAI-style messages: system first, then the conversation.
    const messages = [{ role: "system", content: system }];
    for (const m of history) {
      const role = m.role === "model" ? "assistant" : "user";
      messages.push({ role, content: String(m.text || "") });
    }
    if (messages.length === 1) {
      return json({ error: "No message." }, 400);
    }

    const candidates = payload.model
      ? [payload.model]
      : env.MODEL
      ? [env.MODEL, ...MODELS]
      : MODELS;

    let lastDetail = "";
    let lastStatus = 502;

    for (const model of candidates) {
      const body = {
        model,
        messages,
        temperature: 0.8,
        max_tokens: 320,
      };

      try {
        const res = await fetch(ENDPOINT, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://mira.app",
            "X-Title": "Mira",
          },
          body: JSON.stringify(body),
        });

        if (!res.ok) {
          let detail = "";
          try {
            detail = await res.text();
          } catch (_) {}
          lastDetail = detail.slice(0, 600);
          lastStatus = res.status;
          // Busy or unavailable — try the next model in the chain.
          continue;
        }

        const data = await res.json();
        const reply = data?.choices?.[0]?.message?.content?.trim();
        if (reply) return json({ reply });
        // Empty reply — try the next model.
        lastStatus = 502;
        lastDetail = "empty reply";
      } catch (_) {
        lastStatus = 502;
        lastDetail = "fetch failed";
      }
    }

    return json(
      { error: `Upstream ${lastStatus}`, detail: lastDetail },
      lastStatus === 429 ? 429 : 502
    );
  },
};
