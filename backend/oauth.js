// Google (OIDC) + GitHub (OAuth2) login. Needs client IDs (see README section
// "Go public" + provider dashboards). Without IDs, routes return 501 JSON and
// the login page keeps email working.
const { Issuer } = require('openid-client');
const db = require('./db');

const SITE_URL = (process.env.SITE_URL || 'http://localhost:3000').replace(/\/$/, '');
const PROVIDERS = ['google', 'github'];

function configured(p) {
  if (p === 'google') return !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
  if (p === 'github') return !!(process.env.GITHUB_CLIENT_ID && process.env.GITHUB_CLIENT_SECRET);
  return false;
}

function redirect(path, params) {
  const q = new URLSearchParams(params).toString();
  return `${SITE_URL}${path}?${q}`;
}

let googleClient = null;
async function getGoogle() {
  if (!googleClient) {
    const issuer = await Issuer.discover('https://accounts.google.com');
    googleClient = new issuer.Client({
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      redirect_uris: [`${process.env.API_URL || 'http://localhost:3000'}/api/auth/google/callback`],
      response_types: ['code'],
    });
  }
  return googleClient;
}

async function finish(req, res, sign, { provider, providerId, email, name }) {
  if (!email) return res.redirect(redirect('/login.html', { error: `No email from ${provider}` }));
  let user = await db.findByProvider(provider, String(providerId));
  if (!user) {
    const taken = await db.findByEmail(email);
    if (taken) {
      return res.redirect(redirect('/login.html', {
        error: 'Email already registered — log in with your password once, then use SSO.',
      }));
    }
    user = await db.createUser({
      name: String(name || email.split('@')[0]).slice(0, 60),
      email,
      passHash: null,
      provider,
      providerId: String(providerId),
    });
  }
  return res.redirect(redirect('/login.html', { token: sign(user) }));
}

function setupOAuth(app, sign) {
  app.get('/api/auth/:provider', async (req, res) => {
    const p = String(req.params.provider || '').toLowerCase();
    if (!PROVIDERS.includes(p)) return res.status(404).json({ error: 'Unknown provider' });
    if (!configured(p)) {
      return res.status(501).json({
        error: `${p} login activates once its OAuth app is registered (email works now).`,
      });
    }
    try {
      if (p === 'google') {
        const client = await getGoogle();
        return res.redirect(client.authorizationUrl({ scope: 'openid email profile' }));
      }
      const q = new URLSearchParams({
        client_id: process.env.GITHUB_CLIENT_ID,
        redirect_uri: `${process.env.API_URL || 'http://localhost:3000'}/api/auth/github/callback`,
        scope: 'read:user user:email',
      });
      return res.redirect(`https://github.com/login/oauth/authorize?${q}`);
    } catch (e) {
      return res.status(500).json({ error: 'SSO start failed, try again.' });
    }
  });

  app.get('/api/auth/:provider/callback', async (req, res) => {
    const p = String(req.params.provider || '').toLowerCase();
    try {
      if (p === 'google') {
        const client = await getGoogle();
        const params = client.callbackParams(req);
        const set = await client.callback(
          `${process.env.API_URL || 'http://localhost:3000'}/api/auth/google/callback`,
          params,
          { state: params.state }
        );
        const claims = set.claims();
        if (!claims.email_verified) {
          return res.redirect(redirect('/login.html', { error: 'Google email not verified.' }));
        }
        return finish(req, res, sign, {
          provider: 'google', providerId: claims.sub, email: claims.email, name: claims.name,
        });
      }
      if (p === 'github') {
        const { code } = req.query;
        if (!code) return res.redirect(redirect('/login.html', { error: 'GitHub login cancelled.' }));
        const tr = await fetch('https://github.com/login/oauth/access_token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify({
            client_id: process.env.GITHUB_CLIENT_ID,
            client_secret: process.env.GITHUB_CLIENT_SECRET,
            code,
          }),
        }).then(r => r.json());
        if (!tr.access_token) {
          return res.redirect(redirect('/login.html', { error: 'GitHub token exchange failed.' }));
        }
        const h = { Authorization: `Bearer ${tr.access_token}`, Accept: 'application/vnd.github+json' };
        const me = await fetch('https://api.github.com/user', { headers: h }).then(r => r.json());
        let email = me.email;
        if (!email) {
          const emails = await fetch('https://api.github.com/user/emails', { headers: h }).then(r => r.json());
          const primary = (emails || []).find(e => e.primary && e.verified) || (emails || []).find(e => e.verified);
          email = primary && primary.email;
        }
        return finish(req, res, sign, {
          provider: 'github', providerId: me.id, email, name: me.name || me.login,
        });
      }
      return res.status(404).json({ error: 'Unknown provider' });
    } catch (e) {
      console.error(`oauth ${p}:`, e.message);
      return res.redirect(redirect('/login.html', { error: `${p} login failed, try again.` }));
    }
  });
}

module.exports = { setupOAuth, configured };
