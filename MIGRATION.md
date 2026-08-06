# nextupalarm.com — migration runbook

**Cost after migration: $0/year** (beyond the domain renewal you already pay Squarespace).
**Your time: ~30 min of clicking, then waiting for DNS.**

---

## Current state (verified 2026-08-05)

| | |
|---|---|
| Registrar | Squarespace Domains II — **you still own it**, expiry `2027-04-29` |
| Nameservers | `ns1.bluehost.com` / `ns2.bluehost.com` ← **Bluehost controls your DNS** |
| A record | `162.241.224.65` (Bluehost) → suspended-account page |
| MX | `mail.nextupalarm.com` → same dead Bluehost IP → **`support@nextupalarm.com` is dead** |
| HTTPS | no valid certificate |
| Old site | WordPress + Elementor. Only 3 real pages ever existed: `/`, `/privacy-policy/`, `robots.txt` |

**Why this is urgent-ish:** DNS itself is delegated to Bluehost. While the account is merely suspended it still answers; if it's fully deleted, the domain stops resolving entirely and the App Store links break harder than they already are.

**What's already broken because of it:** your App Store listing's Support URL, Developer Website, **and Privacy Policy URL** all point here — and the Privacy Policy URL **cannot be changed without shipping a new build**, which makes this a live guideline 5.1.1(i) exposure. Reviving the domain is the only available fix.

---

## The target stack

| Layer | Service | Cost | Why |
|---|---|---|---|
| Registrar | Squarespace (unchanged) | ~$20/yr, already paying | No reason to move it |
| DNS | **Cloudflare** | Free | Also unlocks free email forwarding |
| Hosting | **GitHub Pages** | Free | You already run `landonjmitchell.com` on it |
| Email | **Cloudflare Email Routing** | Free | Revives `support@nextupalarm.com` → your real inbox |

**Simpler alternative:** skip Cloudflare, use Squarespace's own DNS. One less account. But you get no free email forwarding, so `support@nextupalarm.com` stays dead — and that address is on your App Store listing.

---

## Step 1 — Publish the site (10 min)

The site is built and ready in `~/Documents/Projects/next_up/site/`. Four pages, 36 KB, no build step, no dependencies.

```
site/
├── CNAME                     nextupalarm.com
├── index.html                landing
├── privacy-policy/index.html ← EXACT path App Store Connect points at
├── faq/index.html            alarm didn't fire / no podcast / battery
├── support/index.html        email + refunds
├── 404.html                  catches dead in-app links, offers real ones
├── robots.txt
└── _style.css
```

The privacy policy and terms are **your original text, recovered verbatim** from the Wayback capture (effective date 11 July 2019 preserved). Read it before publishing — it's your legal document, not mine.

1. Create a new **public** repo — Pages needs public on the free tier. Name it e.g. `nextupalarm`.
   ```bash
   cd ~/Documents/Projects/next_up/site
   git init && git add -A && git commit -m "Next Up site"
   gh repo create landonjmitchell/nextupalarm --public --source=. --push
   ```
   (A separate repo is required: `landonjmitchell.github.io` already claims `landonjmitchell.com`, and GitHub Pages allows one custom domain per repo.)
2. Repo → **Settings → Pages** → Source: *Deploy from a branch*, branch `main`, folder `/ (root)`.
3. Wait for the green check, then confirm it serves at `https://landonjmitchell.github.io/nextupalarm/`.

*(The `CNAME` file is already in the repo, so GitHub will pick up the custom domain automatically once DNS points at it.)*

## Step 2 — Move DNS to Cloudflare (10 min + propagation)

1. Sign up at **cloudflare.com** (free plan). *Add a site* → `nextupalarm.com`.
2. Cloudflare scans existing records. **Delete the Bluehost A record** (`162.241.224.65`) and the `mail` MX records — all dead.
3. Add these records:

   | Type | Name | Content | Proxy |
   |---|---|---|---|
   | A | `@` | `185.199.108.153` | DNS only (grey cloud) |
   | A | `@` | `185.199.109.153` | DNS only |
   | A | `@` | `185.199.110.153` | DNS only |
   | A | `@` | `185.199.111.153` | DNS only |
   | CNAME | `www` | `landonjmitchell.github.io` | DNS only |

   ⚠️ **Grey cloud, not orange.** Cloudflare's proxy in front of GitHub Pages causes certificate issues. Turn proxying off for these records.

4. Cloudflare gives you two nameservers. Go to **Squarespace → Domains → nextupalarm.com → DNS → Nameservers**, switch from *Squarespace/Bluehost* to **Custom**, and enter Cloudflare's two.
5. Wait. Usually minutes; allow a few hours.
   ```bash
   dig +short nextupalarm.com NS      # → cloudflare nameservers
   dig +short nextupalarm.com A       # → the four 185.199.x IPs
   ```

## Step 3 — Turn on HTTPS (5 min, after DNS resolves)

1. Repo → **Settings → Pages** → Custom domain should already read `nextupalarm.com` (from the CNAME file). If not, enter it and save.
2. Wait for "DNS check successful."
3. Tick **Enforce HTTPS**. GitHub provisions a Let's Encrypt cert automatically — can take up to an hour. It renews itself forever.

## Step 4 — Revive support@ (5 min)

Cloudflare → **Email → Email Routing** → Get started.

1. Cloudflare adds the needed MX + TXT records for you.
2. Create a route: `support@nextupalarm.com` → your real inbox.
3. Verify the destination address (Cloudflare emails you a link).
4. Optional: catch-all → same inbox, so nothing addressed to the domain bounces.

Send yourself a test message before you call it done.

## Step 5 — Verify everything (5 min)

```bash
curl -sSI https://nextupalarm.com/ | head -1                  # 200
curl -sSI https://nextupalarm.com/privacy-policy/ | head -1    # 200  ← the important one
curl -sSI https://nextupalarm.com/faq/ | head -1               # 200
curl -sSI https://nextupalarm.com/support/ | head -1           # 200
curl -sSI http://nextupalarm.com/ | head -1                    # 301 → https
echo | openssl s_client -servername nextupalarm.com \
  -connect nextupalarm.com:443 2>/dev/null | openssl x509 -noout -dates
```

Then in a browser, open the exact Privacy Policy URL recorded in App Store Connect and confirm it loads. That's the one that cures the guideline exposure.

## Step 6 — Close out Bluehost

- Confirm the account is **cancelled and won't auto-renew** — don't get billed for a suspended host.
- Nothing needs exporting: the old site was WordPress, and its only real content (privacy policy, homepage copy) is already recovered into `site/` and `docs/site-recovery/`.

---

## Gotchas

- **Grey cloud, not orange** — the single most common cause of Cloudflare + GitHub Pages cert failures.
- **Apex needs A records**, not a CNAME. The four `185.199.x` IPs are GitHub's and are stable.
- **`privacy-policy/` must keep its exact path and trailing slash.** It's hard-coded in App Store Connect and unchangeable without a build.
- **Don't delete the repo's `CNAME` file** — GitHub resets the custom domain if you do.
- Public repo required for free Pages. Nothing sensitive is in `site/`.
- If you'd rather not create a Cloudflare account, Squarespace DNS works identically for hosting — you just lose the free email forwarding.
