// Auth: talks to backend at http://localhost:3000/api (run: node A:\backend\server.js)
(function () {
  // Public backend: Pages injects it via window.FORGE_API_URL (see README);
  // falls back to localhost for pendrive dev.
  var API = window.FORGE_API_URL || 'http://localhost:3000/api';
  var key = 'forge_token';
  var loginBtn = document.getElementById('loginBtn');
  var userChip = document.getElementById('userChip');
  var modal = document.getElementById('authModal');
  var msg = document.getElementById('authMsg');
  var tabL = document.getElementById('tabLogin');
  var tabR = document.getElementById('tabRegister');
  var nameRow = document.getElementById('nameRow');
  var mode = 'login';
  var chal = null;
  function loadChallenge() {
    fetch(API + '/challenge').then(function (r) { return r.json(); }).then(function (j) {
      chal = j;
      document.getElementById('humanQ').textContent = j.a + ' + ' + j.b;
    }).catch(function () { chal = null; });
  }

  function token() { return localStorage.getItem(key); }
  function setToken(t) { t ? localStorage.setItem(key, t) : localStorage.removeItem(key); }
  function show(u) {
    loginBtn.style.display = 'none';
    userChip.style.display = '';
    userChip.innerHTML = '<a href="profile.html">👤 ' + escapeHtml(u.name || u.email) + '</a> <button id="logoutBtn" title="Log out">✕</button>';
    document.getElementById('logoutBtn').onclick = function () { setToken(null); hide(); };
  }
  function hide() { loginBtn.style.display = ''; userChip.style.display = 'none'; userChip.innerHTML = ''; }
  function escapeHtml(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function setMode(m) {
    mode = m; msg.textContent = '';
    tabL.classList.toggle('on', m === 'login');
    tabR.classList.toggle('on', m === 'register');
    nameRow.style.display = m === 'register' ? '' : 'none';
    document.getElementById('humanRow').style.display = m === 'register' ? '' : 'none';
    if (m === 'register') loadChallenge();
    document.getElementById('authGo').textContent = m === 'register' ? 'Create account' : 'Log in';
  }
  function open() { modal.classList.add('open'); modal.setAttribute('aria-hidden', 'false'); setMode(token() ? 'login' : mode); document.getElementById('authEmail').focus(); }
  function close() { modal.classList.remove('open'); modal.setAttribute('aria-hidden', 'true'); msg.textContent = ''; loginBtn.focus(); }
  loginBtn.onclick = open;
  document.getElementById('authClose').onclick = close;
  modal.addEventListener('click', function (e) { if (e.target === modal) close(); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && modal.classList.contains('open')) close(); });
  tabL.onclick = function () { setMode('login'); };
  tabR.onclick = function () { setMode('register'); };

  document.getElementById('authForm').addEventListener('submit', function (e) {
    e.preventDefault();
    var name = document.getElementById('authName').value.trim();
    var email = document.getElementById('authEmail').value.trim();
    var pass = document.getElementById('authPass').value;
    msg.textContent = '…';
    var body = mode === 'register'
      ? { name: name, email: email, password: pass,
          a: chal && chal.a, b: chal && chal.b, nonce: chal && chal.nonce,
          sig: chal && chal.sig, answer: Number(document.getElementById('humanA').value) }
      : { email: email, password: pass };
    fetch(API + (mode === 'register' ? '/register' : '/login'), {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); }).then(function (x) {
      if (!x.ok) { msg.textContent = '⚠ ' + (x.j.error || 'Failed — is the backend running? (node A:\\backend\\server.js)'); if (mode === 'register') loadChallenge(); return; }
      setToken(x.j.token); show(x.j.user); close();
    }).catch(function () { msg.textContent = '⚠ Backend offline — start it: node A:\\backend\\server.js'; });
  });

  // Restore session
  var t = token();
  if (t) fetch(API + '/me', { headers: { Authorization: 'Bearer ' + t } })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (j) { if (j && j.user) show(j.user); else setToken(null); })
    .catch(function () {});
})();
