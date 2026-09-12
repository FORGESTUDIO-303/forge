// PostgreSQL data layer. Users live in the `forge` database (local PG 18 now,
// hosted Postgres in November via DATABASE_URL) — nothing stays in files.
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://forge:forge-local-dev@localhost:5432/forge'
});
pool.on('error', err => console.error('PG pool error:', err.message));

function rowToUser(r) {
  if (!r) return null;
  return { id: r.id, name: r.name, email: r.email, passHash: r.pass_hash, provider: r.provider, providerId: r.provider_id, plan: r.plan, createdAt: r.created_at };
}
async function findByEmail(email) {
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [String(email).toLowerCase()]);
  return rowToUser(rows[0]);
}
async function findByProvider(provider, providerId) {
  const { rows } = await pool.query(
    'SELECT * FROM users WHERE provider = $1 AND provider_id = $2',
    [provider, providerId]
  );
  return rowToUser(rows[0]);
}
async function createUser({ name, email, passHash, provider, providerId }) {
  const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  const { rows } = await pool.query(
    'INSERT INTO users (id, name, email, pass_hash, provider, provider_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
    [id, name, String(email).toLowerCase(), passHash, provider || 'email', providerId || null]
  );
  return rowToUser(rows[0]);
}
async function setPlan(userId, plan) {
  const { rows } = await pool.query(
    "UPDATE users SET plan = $1 WHERE id = $2 RETURNING *",
    [plan, userId]
  );
  return rowToUser(rows[0]);
}
async function updateName(userId, name) {
  const { rows } = await pool.query(
    'UPDATE users SET name = $1 WHERE id = $2 RETURNING *',
    [name, userId]
  );
  return rowToUser(rows[0]);
}
async function setPassHash(userId, passHash) {
  const { rows } = await pool.query(
    'UPDATE users SET pass_hash = $1 WHERE id = $2 RETURNING *',
    [passHash, userId]
  );
  return rowToUser(rows[0]);
}
function publicUser(u) { return { id: u.id, name: u.name, email: u.email, provider: u.provider, plan: u.plan, createdAt: u.createdAt }; }
module.exports = { findByEmail, findByProvider, createUser, setPlan, updateName, setPassHash, publicUser, query: (t, p) => pool.query(t, p) };
