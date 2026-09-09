const { spawn } = require('child_process');
const srv = spawn(process.execPath, ['server.js'], { cwd: __dirname, stdio: 'pipe' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  for (let i = 0; i < 30; i++) {
    await sleep(500);
    try { const r = await fetch('http://localhost:3000/api/health'); if (r.ok) break; } catch {}
  }
  for (const p of ['google', 'apple', 'github', 'nope']) {
    const r = await fetch('http://localhost:3000/api/auth/' + p);
    const j = await r.json().catch(() => ({}));
    console.log('SSO', p, r.status, JSON.stringify(j));
  }
  srv.kill(); process.exit(0);
})().catch(e => { console.error('FAIL', e.message); srv.kill(); process.exit(1); });
