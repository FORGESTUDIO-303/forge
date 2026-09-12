const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const db = require('./db');

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'forge-dev-secret-change-in-november';
const app = express();
app.use(cors());
app.use(express.json());

// Serve published builds so /apps/<name>-web works locally too (first: wins over docs/)
app.use('/apps', express.static(path.join(__dirname, '..', 'apps')));
// Serve the site so http://localhost:3000 shows A:\docs
app.use(express.static(path.join(__dirname, '..', 'docs')));

function sign(user) { return jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' }); }
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Not logged in' });
  try { req.user = jwt.verify(token, JWT_SECRET); next(); }
  catch { return res.status(401).json({ error: 'Session expired, log in again' }); }
}

require('./oauth').setupOAuth(app, sign);

app.post('/api/register', async (req, res) => {
  try {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password) return res.status(400).json({ error: 'Name, email and password required' });
  if (String(password).length < 6) return res.status(400).json({ error: 'Password must be 6+ characters' });
  if (await db.findByEmail(email)) return res.status(409).json({ error: 'Email already registered, log in instead' });
  const passHash = await bcrypt.hash(String(password), 10);
  const user = await db.createUser({ name: String(name).slice(0, 60), email, passHash });
  res.json({ token: sign(user), user: db.publicUser(user) });
  } catch (e) { console.error('register:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

app.post('/api/login', async (req, res) => {
  try {
  const { email, password } = req.body || {};
  const user = email && await db.findByEmail(email);
  if (!user || !user.passHash || !(await bcrypt.compare(String(password || ''), user.passHash)))
    return res.status(401).json({ error: 'Wrong email or password' });
  res.json({ token: sign(user), user: db.publicUser(user) });
  } catch (e) { console.error('login:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

app.get('/api/me', auth, async (req, res) => {
  try {
  const user = await db.findByEmail(req.user.email);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ user: db.publicUser(user) });
  } catch (e) { console.error('me:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

const PLANS = [
  { id: 'free', name: 'Free', price: 0, cta: 'Current plan',
    features: ['Full library + 50 games', 'Community profiles', 'Web apps', 'Offline-first core'] },
  { id: 'pro', name: 'Pro', price: 6, cta: 'Go Pro',
    features: ['Unlimited games', 'Real hardware control (Forge)', 'RGB + macro studio', 'Priority builds', 'Cloud save sync'] },
  { id: 'unlimited', name: 'Unlimited', price: 12, cta: 'Go Unlimited',
    features: ['Everything in Pro', 'All future apps day one', 'Vote on roadmap', 'Name in credits', 'Direct support'] },
];
app.get('/api/plans', (req, res) => res.json({ plans: PLANS }));

// Paid checkout opens with Stripe in November (needs STRIPE_SECRET_KEY + webhook).
app.post('/api/checkout', auth, async (req, res) => {
  const { plan } = req.body || {};
  if (!['pro', 'unlimited'].includes(plan))
    return res.status(400).json({ error: 'Choose pro or unlimited' });
  if (!process.env.STRIPE_SECRET_KEY)
    return res.status(501).json({ error: 'Checkout opens with Stripe in November — your account stays Free until then.' });
  return res.status(501).json({ error: 'Stripe flow lands in November.' });
});

app.get('/api/health', (req, res) => res.json({ ok: true, time: new Date().toISOString() }));

// Local/dev: `node backend/server.js`. Serverless (Vercel): api/index.js imports app.
if (require.main === module) {
  app.listen(PORT, () => console.log('FORGE backend on http://localhost:' + PORT));
}
module.exports = app;
