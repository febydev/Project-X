/**
 * Mira AI proxy — Cloudflare Worker.
 *
 * Holds the Gemini API key (as a secret) so it NEVER ships inside the app.
 * The Flutter app POSTs the conversation here; this worker adds Mira's
 * persona, calls Gemini, and returns a single reply.
 *
 * Deploy: see server/README.md
 * Secret required: GEMINI_API_KEY  (wrangler secret put GEMINI_API_KEY)
 */

const MODEL = "gemini-2.0-flash";

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
    if (!env.GEMINI_API_KEY) {
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
    const messages = Array.isArray(payload.messages) ? payload.messages : [];

    const system =
      PERSONA +
      (mode === "calm" ? CALM_ADDON : "") +
      `\nCONTEXT: The child is named ${baby.name || "the baby"}, about ${
        baby.ageMonths ?? "?"
      } months old.`;

    // Map Mira's history to Gemini's format. Gemini requires the first turn to
    // be from the user, so we drop any leading model messages.
    const contents = [];
    for (const m of messages) {
      const role = m.role === "model" ? "model" : "user";
      if (contents.length === 0 && role === "model") continue;
      contents.push({ role, parts: [{ text: String(m.text || "") }] });
    }
    if (contents.length === 0) {
      return json({ error: "No message." }, 400);
    }

    const body = {
      system_instruction: { parts: [{ text: system }] },
      contents,
      generationConfig: {
        temperature: 0.8,
        topP: 0.95,
        maxOutputTokens: 320,
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
      ],
    };

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${env.GEMINI_API_KEY}`;

    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (res.status === 429) {
        return json({ error: "Busy line, try again shortly." }, 429);
      }
      if (!res.ok) {
        return json({ error: `Upstream error (${res.status}).` }, 502);
      }

      const data = await res.json();
      const reply =
        data?.candidates?.[0]?.content?.parts?.map((p) => p.text).join("").trim();

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
