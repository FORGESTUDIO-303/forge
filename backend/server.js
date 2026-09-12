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

// --- Not-a-robot challenge: signed math question, no keys, no storage.
// GET /api/challenge -> {a,b,nonce,sig}; register must echo all + answer.
const crypto = require('crypto');
function challengeSig(a, b, nonce) {
  return crypto.createHmac('sha256', JWT_SECRET).update(`${a}+${b}:${nonce}`).digest('hex').slice(0, 32);
}
app.get('/api/challenge', (req, res) => {
  const a = 2 + Math.floor(Math.random() * 8);
  const b = 2 + Math.floor(Math.random() * 8);
  const nonce = `${Date.now()}.${Math.random().toString(36).slice(2, 8)}`;
  res.json({ a, b, nonce, sig: challengeSig(a, b, nonce) });
});
function challengeOk(body) {
  const { a, b, nonce, sig, answer } = body || {};
  if ([a, b, nonce, sig, answer].some(v => v === undefined)) return false;
  const ts = parseInt(String(nonce).split('.')[0], 10);
  if (!ts || Date.now() - ts > 10 * 60 * 1000) return false;
  if (challengeSig(Number(a), Number(b), String(nonce)) !== String(sig)) return false;
  return Number(answer) === Number(a) + Number(b);
}

// --- Contact bot: stores the message, instantly replies like a human would.
app.post('/api/contact', async (req, res) => {
  try {
    const { name, email, message } = req.body || {};
    if (!name || !email || !message) return res.status(400).json({ error: 'Name, email and message required' });
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(String(email))) return res.status(400).json({ error: 'That email looks off' });
    if (String(message).length > 2000) return res.status(400).json({ error: 'Message too long (2000 max)' });
    const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
    await db.query(
      'INSERT INTO messages (id, name, email, message) VALUES ($1, $2, $3, $4)',
      [id, String(name).slice(0, 60), String(email).slice(0, 120), String(message).slice(0, 2000)]
    );
    res.json({
      ok: true,
      reply: `Thanks ${String(name).slice(0, 60)}! 🤖 ForgeBot here — your message is saved and Souhail reads everything. Typical reply within a couple of days. Meanwhile, grab the apps and have fun!`,
    });
  } catch (e) { console.error('contact:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

app.post('/api/register', async (req, res) => {
  try {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password) return res.status(400).json({ error: 'Name, email and password required' });
  if (String(password).length < 6) return res.status(400).json({ error: 'Password must be 6+ characters' });
  if (!challengeOk(req.body)) return res.status(400).json({ error: 'Human check failed — solve the math question again' });
  if (await db.findByEmail(email)) return res.status(409).json({ error: 'Email already registered, log in instead' });
  const passHash = await bcrypt.hash(String(password), 10);
  const user = await db.createUser({ name: String(name).slice(0, 60), email, passHash });
  res.json({
    token: sign(user),
    user: db.publicUser(user),
    isNewUser: true,
    welcome: `Welcome to FORGE, ${user.name}! Your account is ready — explore the suite, grab the apps, and have fun.`,
  });
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

// Account control: rename + password change (email accounts only).
app.patch('/api/me', auth, async (req, res) => {
  try {
    const { name } = req.body || {};
    if (!name || !String(name).trim()) return res.status(400).json({ error: 'Name required' });
    const me = await db.findByEmail(req.user.email);
    if (!me) return res.status(404).json({ error: 'User not found' });
    const updated = await db.updateName(me.id, String(name).trim().slice(0, 60));
    res.json({ user: db.publicUser(updated) });
  } catch (e) { console.error('rename:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

app.post('/api/change-password', auth, async (req, res) => {
  try {
    const { current, next } = req.body || {};
    const me = await db.findByEmail(req.user.email);
    if (!me) return res.status(404).json({ error: 'User not found' });
    if (!me.passHash) return res.status(400).json({ error: 'SSO accounts have no password — log in with your provider.' });
    if (!(await bcrypt.compare(String(current || ''), me.passHash)))
      return res.status(401).json({ error: 'Current password is wrong' });
    if (!next || String(next).length < 6) return res.status(400).json({ error: 'New password must be 6+ characters' });
    await db.setPassHash(me.id, await bcrypt.hash(String(next), 10));
    res.json({ ok: true });
  } catch (e) { console.error('passwd:', e.message); return res.status(500).json({ error: 'Database unavailable, try again in a minute.' }); }
});

app.get('/api/health', (req, res) => res.json({ ok: true, time: new Date().toISOString() }));

// Local/dev: `node backend/server.js`. Serverless (Vercel): api/index.js imports app.
if (require.main === module) {
  app.listen(PORT, () => console.log('FORGE backend on http://localhost:' + PORT));
}
module.exports = app;
