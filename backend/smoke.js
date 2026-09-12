// Smoke test: boots server.js, hits health/register/login/me/rename/passwd/contact, shuts down.
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
  const ch = await req('/api/challenge');
  console.log('CHALLENGE', ch.status, ch.j.a !== undefined ? 'ok' : JSON.stringify(ch.j));
  const email = 'test' + Date.now() + '@forge.local';
  const regBody = { name: 'Test', email, password: 'secret123' };
  if (ch.status === 200) Object.assign(regBody, { a: ch.j.a, b: ch.j.b, nonce: ch.j.nonce, sig: ch.j.sig, answer: ch.j.a + ch.j.b });
  const reg = await req('/api/register', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(regBody) });
  console.log('REGISTER', reg.status, JSON.stringify(reg.j.user || reg.j));
  const badHuman = await req('/api/register', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'Bot', email: 'bot' + Date.now() + '@x.io', password: 'secret123' }) });
  console.log('NOROBOT', badHuman.status, JSON.stringify(badHuman.j));
  const login = await req('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'secret123' }) });
  console.log('LOGIN', login.status, login.j.token ? 'token-ok' : JSON.stringify(login.j));
  const authH = { 'Content-Type': 'application/json', Authorization: 'Bearer ' + (login.j.token || '') };
  const me = await req('/api/me', { headers: authH });
  console.log('ME', me.status, JSON.stringify(me.j.user || me.j));
  const ren = await req('/api/me', { method: 'PATCH', headers: authH, body: JSON.stringify({ name: 'Tester' }) });
  console.log('RENAME', ren.status, JSON.stringify(ren.j.user || ren.j));
  const pw = await req('/api/change-password', { method: 'POST', headers: authH, body: JSON.stringify({ current: 'secret123', next: 'newpass456' }) });
  console.log('PASSWD', pw.status, JSON.stringify(pw.j));
  const login2 = await req('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'newpass456' }) });
  console.log('LOGIN2', login2.status, login2.j.token ? 'token-ok' : JSON.stringify(login2.j));
  const bad = await req('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: 'wrong' }) });
  console.log('BADLOGIN', bad.status, JSON.stringify(bad.j));
  const contact = await req('/api/contact', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'T', email: 't@x.io', message: 'hello bot' }) });
  console.log('CONTACT', contact.status, contact.j.reply ? 'bot-replied' : JSON.stringify(contact.j));
  const sso = await req('/api/auth/google', {});
  console.log('SSO501', sso.status, JSON.stringify(sso.j));
  srv.kill();
  const pass = reg.status === 200 && badHuman.status === 400 && login.status === 200 && me.status === 200 &&
    ren.status === 200 && pw.status === 200 && login2.status === 200 && bad.status === 401 &&
    contact.status === 200 && sso.status === 501;
  process.exit(pass ? 0 : 1);
})().catch(e => { console.error('SMOKE-FAIL', e.message); console.error('CHILD-OUT:', out.slice(-2000)); srv.kill(); process.exit(1); });
