// Under-development gate: casual-visitor lock, not hacker-proof.
// Anyone with devtools can bypass — real protection is unpublishing.
// Change CODE and tell your testers. Clear site data to re-lock.
(function () {
  var CODE = 'FORGE2026';
  var KEY = 'forge_gate_ok';
  var ok = false;
  try { ok = localStorage.getItem(KEY) === '1'; } catch (e) {}
  document.documentElement.classList.add(ok ? 'gate-open' : 'gate-lock');
  if (ok) return;
  window.addEventListener('DOMContentLoaded', function () {
    var ov = document.createElement('div');
    ov.id = 'gate';
    ov.innerHTML =
      '<div class="gate-card">' +
      '<p class="kicker gold">UNDER DEVELOPMENT</p>' +
      '<h1>Forge is still in the workshop</h1>' +
      '<p class="sub">This preview is closed until launch. Enter your invite code.</p>' +
      '<form id="gateForm"><input id="gateCode" placeholder="Invite code" autocomplete="off">' +
      '<button class="btn primary block" type="submit">Enter</button></form>' +
      '<p class="msg" id="gateMsg" role="status"></p>' +
      '<p class="fine">Built by Souhail (FORGESTUDIO-303) with Muse Spark.</p>' +
      '</div>';
    document.body.appendChild(ov);
    document.getElementById('gateForm').addEventListener('submit', function (e) {
      e.preventDefault();
      var v = document.getElementById('gateCode').value.trim();
      if (v === CODE) {
        try { localStorage.setItem(KEY, '1'); } catch (err) {}
        document.documentElement.classList.remove('gate-lock');
        document.documentElement.classList.add('gate-open');
        ov.remove();
      } else {
        document.getElementById('gateMsg').textContent = 'Wrong code — ask Souhail for an invite.';
      }
    });
  });
})();
