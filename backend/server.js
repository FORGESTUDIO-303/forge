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

app.post('/api/register', async (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password) return res.status(400).json({ error: 'Name, email and password required' });
  if (String(password).length < 6) return res.status(400).json({ error: 'Password must be 6+ characters' });
  if (await db.findByEmail(email)) return res.status(409).json({ error: 'Email already registered, log in instead' });
  const passHash = await bcrypt.hash(String(password), 10);
  const user = await db.createUser({ name: String(name).slice(0, 60), email, passHash });
  res.json({ token: sign(user), user: db.publicUser(user) });
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body || {};
  const user = email && await db.findByEmail(email);
  if (!user || !(await bcrypt.compare(String(password || ''), user.passHash)))
    return res.status(401).json({ error: 'Wrong email or password' });
  res.json({ token: sign(user), user: db.publicUser(user) });
});

app.get('/api/me', auth, async (req, res) => {
  const user = await db.findByEmail(req.user.email);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ user: db.publicUser(user) });
});

app.get('/api/health', (req, res) => res.json({ ok: true, time: new Date().toISOString() }));

app.listen(PORT, () => console.log('FORGE backend on http://localhost:' + PORT));
