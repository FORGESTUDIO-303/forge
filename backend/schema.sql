-- November: PostgreSQL 18 schema (replaces backend/data/users.json)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  email TEXT UNIQUE NOT NULL,
  pass_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
