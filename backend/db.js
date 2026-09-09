// PostgreSQL data layer. Users live in the `forge` database (local PG 18 now,
// hosted Postgres in November via DATABASE_URL) — nothing stays in files.
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://forge:forge-local-dev@localhost:5432/forge'
});
pool.on('error', err => console.error('PG pool error:', err.message));

function rowToUser(r) {
  if (!r) return null;
  return { id: r.id, name: r.name, email: r.email, passHash: r.pass_hash, createdAt: r.created_at };
}
async function findByEmail(email) {
  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [String(email).toLowerCase()]);
  return rowToUser(rows[0]);
}
async function createUser({ name, email, passHash }) {
  const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  const { rows } = await pool.query(
    'INSERT INTO users (id, name, email, pass_hash) VALUES ($1, $2, $3, $4) RETURNING *',
    [id, name, String(email).toLowerCase(), passHash]
  );
  return rowToUser(rows[0]);
}
function publicUser(u) { return { id: u.id, name: u.name, email: u.email, createdAt: u.createdAt }; }
module.exports = { findByEmail, createUser, publicUser };
