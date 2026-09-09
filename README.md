# ◈ FORGE — Game Library, Hardware Control & Studio Apps

Offline-first premium apps for PC, phone and web. One codebase vision,
zero ads, zero trackers.

**Live site:** `https://FORGESTUDIO-303.github.io/forge/` (GitHub Pages, `/docs`)

## Flagship apps

| App | What it is |
|---|---|
| OmniLauncher | Universal game library — grid + list, playtime tracking, real launching on desktop |
| Forge Control | System & hardware suite — monitoring, fan curves, RGB, profiles |
| Pulse Link | Peripheral control center — layered RGB, macros, DPI |
| Boost Engine | Game optimizer — one-click boost, cleanup, network tools |
| Lumina Studio | High-end RGB studio — zones, audio-reactive, effect creator |
| StreamForge | Streaming & recording suite — scenes, mixer, transitions |

Plus creator tools (Clip/Soundboard/Wallpaper studios, Mod Manager, Save Syncer)
and game concepts (Neon Rogue, Card Battler Legends, Idle Empire, Rhythm Combat).

## Repo layout

```
docs/        static site (GitHub Pages) — HTML/CSS/JS/SVG, no build step
backend/   Node + Express auth API (JWT + bcrypt) on PostgreSQL 18
apps/      published builds (.exe/.apk/web) — download buttons light up automatically
Dockerfile container for hosted backend · netlify.toml static-host config
```

## Run it locally

```bash
# database (PostgreSQL 18): createdb forge + psql -d forge -f backend/schema.sql
cd backend && npm install && node server.js
# → http://localhost:3000 (site + API)
```

Default dev DB role: `forge` / `forge-local-dev` @ `localhost:5432/forge`
(see `backend/.env.example`). Test: `node backend/smoke.js`.

## Go public (Render + hosted Postgres, free tiers)

1. Render → New → Blueprint → repo `FORGESTUDIO-303/forge` (uses `render.yaml`:
   `forge-backend` web service + `forge-db` database).
2. After deploy: `DATABASE_URL="..." node backend/migrate.js` (one-time schema).
3. Copy the backend URL, e.g. `https://forge-backend.onrender.com`.
4. In `docs/index.html`, uncomment the `FORGE_API_URL` line with that URL
   (+ `/api`), commit + push. GitHub Pages rebuilds; login on the public
   link now hits your hosted backend + DB.

## Roadmap

- [x] Website + email login on PostgreSQL
- [ ] Public backend + hosted Postgres (login/SSO live on the link)
- [ ] OmniLauncher MVP, then the suite one app at a time
- [ ] Published builds in `apps/`

Built offline-first, on a 15GB pendrive.
