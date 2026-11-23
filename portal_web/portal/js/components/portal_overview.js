/**
 * PCM WAYANAD PORTAL - CLIENT OVERVIEW COMPONENT (< 75 lines)
 */

window.PortalOverviewComponent = {
  renderMount() {
    return `
      <div class="card">
        <div class="profile-row">
          <div class="avatar-wrap">
            <div class="avatar">👤</div>
            <div>
              <div class="client-title" id="valClientName">CLIENT PORTAL</div>
              <div class="site-badge-txt" id="valSiteId">site: PCM-MS-003</div>
              <div class="loc-txt" id="valLoc">📍 Wayanad</div>
            </div>
          </div>
          <span class="badge-stage" id="valStage">PLANNING</span>
        </div>
        <div class="pin-box">
          <span class="pin-lbl">🔑 CLIENT SITE PIN</span>
          <span class="pin-val" id="valPin">0003</span>
        </div>
        <div class="actions-grid">
          <a id="btnCall" href="tel:9383406185" class="btn-action btn-call">📞 CALL</a>
          <a id="btnWa" href="https://wa.me/919383406185" target="_blank" rel="noopener noreferrer" class="btn-action btn-wa">💬 WHATSAPP</a>
          <a id="btnMap" href="https://maps.google.com" target="_blank" rel="noopener noreferrer" class="btn-action btn-map">🗺️ MAPS</a>
        </div>
      </div>
    `;
  },

  updateStage(stage) {
    if (!stage) return;
    const b = document.getElementById('valStage');
    if (!b) return;
    b.textContent = stage.toUpperCase();
    b.className = 'badge-stage';
    if (stage.toLowerCase().includes('progress')) b.classList.add('badge-stage-progress');
    else if (stage.toLowerCase().includes('complete')) b.classList.add('badge-stage-complete');
  },

  updateContacts(phone) {
    if (!phone) return;
    const clean = phone.replace(/\D/g, '');
    const btnCall = document.getElementById('btnCall');
    const btnWa = document.getElementById('btnWa');
    if (btnCall) btnCall.href = `tel:${clean}`;
    if (btnWa) {
      const waNum = clean.startsWith('91') ? clean : `91${clean}`;
      btnWa.href = `https://wa.me/${waNum}`;
    }
  },

  sync(row) {
    if (!row) return;
    if (row.client_name) document.getElementById('valClientName').innerText = row.client_name.toUpperCase();
    if (row.site_id) document.getElementById('valSiteId').innerText = 'site: ' + row.site_id.toUpperCase();
    if (row.site_pin) document.getElementById('valPin').innerText = row.site_pin;
    if (row.location || row.site_location) document.getElementById('valLoc').innerText = '📍 ' + (row.location || row.site_location);

    this.updateStage(row.project_stage || row.stage);
    this.updateContacts(row.client_phone);
  }
};
