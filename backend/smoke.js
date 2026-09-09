// Smoke test: boots server.js, hits health/register/login/me, shuts down.
const { spawn } = require('child_process');
const srv = spawn(process.execPath, ['server.js'], { cwd: __dirname, stdio: 'pipe' });
let out = '';
srv.stdout.on('data', d => { out += d; });
srv.stderr.on('data', d => { out += d; });
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function req(path, opts) {
  const r = await fetch('http://localhost:3000' + path, opts);
  const j = await r.json().catch(() => ({}));
  return { status: r.status, j };
}
(async () => {
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try { const h = await req('/api/health'); if (h.status === 200) break; } catch {}
  }
  const email = 'test' + Date.now() + '@forge.local';
  const reg = await req('/api/register', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'Test', email, password: 'secret123' }) });
  console.log('REGISTER', reg.status, JSON.stringify(reg.j.user || reg.j));
  const login = await req('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'secret123' }) });
  console.log('LOGIN', login.status, login.j.token ? 'token-ok' : JSON.stringify(login.j));
  const me = await req('/api/me', { headers: { Authorization: 'Bearer ' + (login.j.token || '') } });
  console.log('ME', me.status, JSON.stringify(me.j.user || me.j));
  const bad = await req('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'wrong' }) });
  console.log('BADLOGIN', bad.status, JSON.stringify(bad.j));
  srv.kill();
  process.exit(reg.status === 200 && login.status === 200 && me.status === 200 && bad.status === 401 ? 0 : 1);
})().catch(e => { console.error('SMOKE-FAIL', e.message); console.error('CHILD-OUT:', out.slice(-2000)); srv.kill(); process.exit(1); });
