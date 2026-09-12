// Google (OIDC) + GitHub (OAuth2) login. Single-segment routes only —
// this deployment's edge router 404s nested paths like /api/auth/x.
// Needs client IDs (see .env.example); without IDs routes return 501 JSON
// and the login page keeps email working.
const { Issuer } = require('openid-client');
const db = require('./db');

const SITE_URL = (process.env.SITE_URL || 'http://localhost:3000').replace(/\/$/, '');
const API_URL = (process.env.API_URL || 'http://localhost:3000').replace(/\/$/, '');

function redirect(path, params) {
  const q = new URLSearchParams(params).toString();
  return `${SITE_URL}${path}?${q}`;
}

const googleOk = () => !!(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
const githubOk = () => !!(process.env.GITHUB_CLIENT_ID && process.env.GITHUB_CLIENT_SECRET);

let googleClient = null;
async function getGoogle() {
  if (!googleClient) {
    const issuer = await Issuer.discover('https://accounts.google.com');
    googleClient = new issuer.Client({
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      redirect_uris: [`${API_URL}/api/oauth-google-callback`],
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
  app.get('/api/oauth-google', async (req, res) => {
    if (!googleOk()) {
      return res.status(501).json({ error: 'google login activates once its OAuth app is registered (email works now).' });
    }
    try {
      const client = await getGoogle();
      return res.redirect(client.authorizationUrl({ scope: 'openid email profile' }));
    } catch (e) {
      return res.status(500).json({ error: 'SSO start failed, try again.' });
    }
  });

  app.get('/api/oauth-google-callback', async (req, res) => {
    try {
      const client = await getGoogle();
      const params = client.callbackParams(req);
      const set = await client.callback(
        `${API_URL}/api/oauth-google-callback`,
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
    } catch (e) {
      console.error('oauth google:', e.message);
      return res.redirect(redirect('/login.html', { error: 'google login failed, try again.' }));
    }
  });

  app.get('/api/oauth-github', (req, res) => {
    if (!githubOk()) {
      return res.status(501).json({ error: 'github login activates once its OAuth app is registered (email works now).' });
    }
    const q = new URLSearchParams({
      client_id: process.env.GITHUB_CLIENT_ID,
      redirect_uri: `${API_URL}/api/oauth-github-callback`,
      scope: 'read:user user:email',
    });
    return res.redirect(`https://github.com/login/oauth/authorize?${q}`);
  });

  app.get('/api/oauth-github-callback', async (req, res) => {
    try {
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
    } catch (e) {
      console.error('oauth github:', e.message);
      return res.redirect(redirect('/login.html', { error: 'github login failed, try again.' }));
    }
  });
}

module.exports = { setupOAuth };
