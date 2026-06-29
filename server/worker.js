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

// A free OpenRouter model (IDs ending in :free cost $0). Override per-request
// with a "model" field, or set a MODEL env var.
const DEFAULT_MODEL = "deepseek/deepseek-chat-v3-0324:free";

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
    const model = payload.model || env.MODEL || DEFAULT_MODEL;

    const system =
      PERSONA +
      (mode === "calm" ? CALM_ADDON : "") +
      `\nCONTEXT: The child is named ${baby.name || "the baby"}, about ${
        baby.ageMonths ?? "?"
      } months old.`;

    // Build OpenAI-style messages: system first, then the conversation.
    const messages = [{ role: "system", content: system }];
    for (const m of history) {
      const role = m.role === "model" ? "assistant" : "user";
      messages.push({ role, content: String(m.text || "") });
    }
    if (messages.length === 1) {
      return json({ error: "No message." }, 400);
    }

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
        return json(
          { error: `Upstream ${res.status}`, detail: detail.slice(0, 600) },
          res.status === 429 ? 429 : 502
        );
      }

      const data = await res.json();
      const reply = data?.choices?.[0]?.message?.content?.trim();

      if (!reply) {
        return json({
          reply:
            "I'm here with you. Could you tell me a little more about what's happening?",
        });
      }
      return json({ reply });
    } catch (_) {
      return json({ error: "Could not reach the AI." }, 502);
    }
  },
};
