-- FORGE schema: users + plans (email + OAuth). Idempotent — safe to re-run.
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  email TEXT UNIQUE NOT NULL,
  pass_hash TEXT,
  provider TEXT NOT NULL DEFAULT 'email',
  provider_id TEXT,
  plan TEXT NOT NULL DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS pass_hash TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'email';
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free';
CREATE UNIQUE INDEX IF NOT EXISTS users_provider_uid ON users (provider, provider_id)
  WHERE provider <> 'email';
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_plan_check') THEN
    ALTER TABLE users ADD CONSTRAINT users_plan_check CHECK (plan IN ('free','pro','unlimited'));
  END IF;
END $$;
