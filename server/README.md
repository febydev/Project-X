# Mira AI proxy (Cloudflare Worker)

This tiny worker is the only "backend" Mira has. It holds your Gemini API key so
it never ships inside the app, and it gives Mira her voice (the persona in
`worker.js`). It runs free on Cloudflare's free Workers plan — **no credit card**.

## What you'll need (all free)

1. A **Google AI Studio** account → a free **Gemini API key**
   - Go to https://aistudio.google.com/apikey and create a key.
2. A **Cloudflare** account (free, no card).
3. Node.js installed *on whatever machine you deploy from* — or use the Cloudflare
   dashboard's web editor (no install needed, see Option B).

> You don't need Node on your phone or for the app — only to push the worker once.
> If you don't want to install anything, use **Option B** (web dashboard).

## Option A — deploy with Wrangler (CLI)

```bash
npm install -g wrangler
wrangler login
cd server
wrangler secret put GEMINI_API_KEY   # paste your Gemini key when prompted
wrangler deploy
```

Wrangler prints a URL like `https://mira-proxy.<your-subdomain>.workers.dev`.

## Option B — deploy with the Cloudflare dashboard (no install)

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Create Worker**.
2. Name it `mira-proxy`, click **Deploy**, then **Edit code**.
3. Delete the sample code, paste the entire contents of `worker.js`, click **Deploy**.
4. Go to the worker's **Settings → Variables → Add variable**:
   - Name: `GEMINI_API_KEY`
   - Value: your Gemini key
   - Click **Encrypt**, then **Save**.
5. Copy the worker URL shown at the top (e.g. `https://mira-proxy.<you>.workers.dev`).

## Connect the app

Open Mira → **Settings → Mira AI → AI connection** and paste the worker URL.
That's it — the chat and Calm Mode are now live.

## Cost & limits

- Cloudflare Workers free tier: 100,000 requests/day.
- Gemini free tier has generous per-minute limits — plenty for early users.
- Mira gates AI chat behind Premium and caps free users, so you stay inside
  the free limits. When you grow, raise limits or move to a paid model by
  changing `MODEL` and your key — the app doesn't change.
