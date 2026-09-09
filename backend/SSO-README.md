# FORGE SSO — Google / GitHub / Apple setup guide

Status: buttons in the login modal + `GET /api/auth/:provider` stubs exist.
They return 501 until the steps below are done. Email login works regardless.

## 0. What you need (November, internet required)

- A public backend URL (Render/Fly/Railway). SSO does NOT work from
  `localhost` alone for real users — providers only redirect to registered URLs.
- One OAuth app per provider. Keep dev + prod redirect URLs registered:
  - dev:  `http://localhost:3000/api/auth/<provider>/callback`
  - prod:  `https://YOUR-BACKEND/api/auth/<provider>/callback`

## 1. Google (easiest, do first)

1. Go to `console.cloud.google.com` → APIs & Services → Credentials.
2. Create Credentials → OAuth client ID → Web application.
3. Authorized redirect URIs: add dev + prod callback URLs above.
4. Copy Client ID + Client Secret into `.env`:
   `GOOGLE_CLIENT_ID=...` / `GOOGLE_CLIENT_SECRET=...`

## 2. GitHub (easy)

1. GitHub → Settings → Developer settings → OAuth Apps → New OAuth App.
2. Homepage URL: your Netlify site. Authorization callback URL: dev URL first,
   add prod URL later (GitHub allows one — use prod, override locally if needed).
3. Copy Client ID + Client Secret into `.env`:
   `GITHUB_CLIENT_ID=...` / `GITHUB_CLIENT_SECRET=...`

## 3. Apple (hardest, optional — needs paid Apple Developer $99/yr)

1. `developer.apple.com/account` → Certificates, Identifiers & Profiles.
2. Create Services ID (e.g. `com.forge.web`), enable Sign in with Apple,
   set return URL to your callback(s).
3. Create a Sign in with Apple private key → Key ID; note Team ID.
4. `client_secret` is a JWT you sign yourself (ES256, 6-month max lifetime,
   rotate before expiry). Store in `.env`:
   `APPLE_CLIENT_ID=` (Services ID) / `APPLE_TEAM_ID=` / `APPLE_KEY_ID=`
   plus the private key file (never commit it).

## 4. Database migration (run once, local PG now / hosted PG later)

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_id TEXT;
ALTER TABLE users ALTER COLUMN pass_hash DROP NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS users_provider_uid ON users (provider, provider_id)
  WHERE provider <> 'email';
```

## 5. Backend wiring (replaces the 501 stubs in server.js)

1. `npm i openid-client` (Google + Apple are OIDC; GitHub uses plain OAuth2).
2. `GET /api/auth/:provider` → build authorize URL, redirect user there.
3. `GET /api/auth/:provider/callback` → exchange code for tokens, verify ID
   token (check `iss`/`aud`/expiry!), read profile (email, name).
4. Find-or-create: `SELECT * FROM users WHERE provider=$1 AND provider_id=$2`,
   else INSERT with `pass_hash = NULL`. Sign our JWT, redirect to
   `/?token=<jwt>`; frontend (auth.js) stores it like a normal login.

## 6. Test checklist

- [ ] `/api/auth/google` redirects to Google (not 501)
- [ ] Callback creates user row with `provider='google'`
- [ ] Same Google account twice = same user (no duplicates)
- [ ] Email users unaffected; wrong-password still 401
- [ ] Prod callback URLs registered before going live

## 7. Security notes

- Never commit `.env` or Apple keys (`.dockerignore` already excludes `.env`).
- Verify ID-token signature + audience on every callback.
- Keep JWT_SECRET long/random in production (current value is dev-only).
