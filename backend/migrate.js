// One-command schema apply:  DATABASE_URL=... node backend/migrate.js
// Local:  node backend/migrate.js   (uses dev forge DB)
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
(async () => {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  const client = new Client({ connectionString: process.env.DATABASE_URL || 'postgres://forge:forge-local-dev@localhost:5432/forge' });
  await client.connect();
  await client.query(sql);
  console.log('schema ok');
  await client.end();
})().catch(e => { console.error('migrate failed:', e.message); process.exit(1); });
