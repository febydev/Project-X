# Mira AI proxy (Cloudflare Worker)

This tiny worker is the only "backend" Mira has. It holds your OpenRouter API key
so it never ships inside the app, and it gives Mira her voice (the persona in
`worker.js`). It runs free on Cloudflare's free Workers plan — **no credit card**.

## What you'll need (all free)

1. An **OpenRouter** account → a free **API key** (no credit card)
   - Go to https://openrouter.ai/keys and create a key.
   - OpenRouter gives one key for many free models (DeepSeek, Llama, etc.).
2. A **Cloudflare** account (free, no card).
3. Node.js installed *on whatever machine you deploy from* — or use the Cloudflare
   dashboard's web editor (no install needed, see Option B).

## Option A — deploy with Wrangler (CLI)

```bash
npm install -g wrangler
wrangler login
cd server
wrangler secret put OPENROUTER_API_KEY   # paste your OpenRouter key when prompted
wrangler deploy
```

Wrangler prints a URL like `https://mira-proxy.<your-subdomain>.workers.dev`.

## Option B — deploy with the Cloudflare dashboard (no install)

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Create Worker**.
2. Name it `mira-proxy`, click **Deploy**, then **Edit code**.
3. Delete the sample code, paste the entire contents of `worker.js`, click **Deploy**.
4. Go to the worker's **Settings → Variables → Add variable**:
   - Name: `OPENROUTER_API_KEY`
   - Value: your OpenRouter key
   - Click **Encrypt**, then **Save**.
5. Copy the worker URL shown at the top (e.g. `https://mira-proxy.<you>.workers.dev`).

## Connect the app

Open Mira → **Settings → Mira AI → AI connection** and paste the worker URL.
That's it — the chat and Calm Mode are now live.

## Cost & limits

- Cloudflare Workers free tier: 100,000 requests/day.
- OpenRouter free models (IDs ending in `:free`) cost $0 and need no credit card —
  they're rate-limited rather than charged.
- Mira gates AI chat behind Premium and caps free users, so you stay well inside
  the limits. When you grow, switch to a stronger model by changing `DEFAULT_MODEL`
  in `worker.js` (or set a `MODEL` variable) — the app doesn't change.
