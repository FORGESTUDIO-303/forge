// FORGE site logic — offline, no deps. Drop builds into A:\apps\ to activate buttons.
(function () {
  document.getElementById('yr').textContent = '© ' + new Date().getFullYear();

  // Search + filter flagship cards
  var search = document.getElementById('search');
  var chips = Array.prototype.slice.call(document.querySelectorAll('.chip'));
  var cards = Array.prototype.slice.call(document.querySelectorAll('#appGrid .card'));
  var active = 'all';
  function apply() {
    var q = (search.value || '').toLowerCase().trim();
    cards.forEach(function (c) {
      var okCat = active === 'all' || c.dataset.cat === active;
      var okQ = !q || (c.dataset.name + ' ' + c.textContent.toLowerCase()).indexOf(q) > -1;
      c.style.display = okCat && okQ ? '' : 'none';
    });
  }
  search.addEventListener('input', apply);
  chips.forEach(function (ch) {
    ch.addEventListener('click', function () {
      chips.forEach(function (x) { x.classList.remove('on'); });
      ch.classList.add('on'); active = ch.dataset.f; apply();
    });
  });

  // Download buttons: maps keys -> expected files under A:\apps\
  var FILES = {
    'omnilauncher-windows': 'apps/OmniLauncher-Windows/omnilauncher.exe',
    'omnilauncher-android': 'apps/OmniLauncher-Android.apk',
    'omnilauncher-web': 'apps/omnilauncher-web/index.html',
    'forge-windows': 'apps/ForgeControl-Windows/forge_control.exe',
    'forge-android': 'apps/ForgeControl-Android.apk',
    'forge-web': 'apps/forgecontrol-web/index.html',
    'pulse-windows': 'apps/PulseLink-Windows.exe',
    'pulse-web': 'apps/pulselink-web/index.html',
    'boost-windows': 'apps/BoostEngine-Windows.exe',
    'boost-android': 'apps/BoostEngine-Android.apk',
    'lumina-windows': 'apps/LuminaStudio-Windows.exe',
    'lumina-web': 'apps/lumina-web/index.html',
    'streamforge-windows': 'apps/StreamForge-Windows.exe',
    'streamforge-linux': 'apps/StreamForge-Linux.AppImage'
  };
  var msg = document.getElementById('dlMsg');
  function tryDownload(key) {
    var rel = FILES[key];
    if (!rel) { msg.textContent = 'Unknown build: ' + key; return; }
    // Probe file; file:// fetch may fail in some browsers -> fall back to direct link
    fetch(rel, { method: 'HEAD' }).then(function (r) {
      if (r.ok) { window.location.href = rel; msg.textContent = ''; }
      else { msg.textContent = '⏳ ' + key + ' build not published yet — drop it in A:\\' + rel.replace(/\//g, '\\') + ' to activate.'; }
    }).catch(function () {
      msg.textContent = '⏳ ' + key + ' — place the build at A:\\' + rel.replace(/\//g, '\\') + ' (November milestone). Trying direct link…';
      window.location.href = rel;
    });
  }
  document.querySelectorAll('[data-dl]').forEach(function (b) {
    b.addEventListener('click', function (e) {
      if (b.tagName === 'BUTTON') { e.preventDefault(); tryDownload(b.dataset.dl); }
      else { e.preventDefault(); tryDownload(b.dataset.dl); }
    });
  });

  // Pricing: reflect live plans + start checkout (Stripe opens in November).
  var planMsg = document.getElementById('planMsg');
  function apiBase() {
    return (window.FORGE_API_URL || 'http://localhost:3000/api');
  }
  document.querySelectorAll('[data-plan-btn]').forEach(function (b) {
    b.addEventListener('click', function () {
      var plan = b.dataset.planBtn;
      var token = null;
      try { token = localStorage.getItem('forge_token'); } catch (e) {}
      if (plan === 'free' || !token) { window.location.href = 'login.html'; return; }
      planMsg.textContent = 'Contacting checkout…';
      fetch(apiBase() + '/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
        body: JSON.stringify({ plan: plan })
      }).then(function (r) { return r.json().then(function (j) { return { ok: r.ok, j: j }; }); }).then(function (x) {
        planMsg.textContent = x.ok ? 'Upgraded.' : ('⚠ ' + (x.j.error || 'Checkout unavailable'));
      }).catch(function () { planMsg.textContent = '⚠ Cannot reach the account server.'; });
    });
  });
})();
