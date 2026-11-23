/**
 * PCM WAYANAD PORTAL - HEADER COMPONENT (< 50 lines)
 */

window.PortalHeaderComponent = {
  renderMount() {
    return `
      <div class="header-inner">
        <div>
          <div class="logo-txt">PCM WAYANAD</div>
          <div class="live-status">
            <span class="live-dot"></span>
            <span id="syncBadge">LIVE QUOTATION & SYNC</span>
          </div>
        </div>
        <div class="header-actions">
          <button class="btn-pdf-hdr" onclick="window.downloadProfessionalPDF()">📥 PDF</button>
          <button class="btn-lock-portal" onclick="window.logout()" title="Log out">🚪 LOG OUT</button>
          <button class="btn-live-sync" onclick="location.reload()">Sync</button>
        </div>
      </div>
    `;
  }
};
