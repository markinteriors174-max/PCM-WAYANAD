/**
 * PCM WAYANAD PORTAL - PDF QUOTATION COMPONENT (< 70 lines)
 */

window.PortalPdfComponent = {
  renderMount() {
    return `
      <div class="card" id="pdfCardSection">
        <div class="card-head-pill head-pdf flex items-center justify-between">
          <span class="font-bold">📄 OFFICIAL DETAILED QUOTATION & SPECIFICATIONS</span>
          <span class="badge-verified-pdf" id="pdfStatusBadge">VERIFIED PDF</span>
        </div>
        <div class="pdf-promo-box">
          <div class="pdf-icon-badge">📄</div>
          <div>
            <div class="pdf-promo-title" id="pdfTitle">PCM Master False Ceiling Quotation</div>
            <div class="pdf-promo-sub" id="pdfSub">Room-by-room area breakdown, rates, materials & specifications directly synced from PCM App.</div>
          </div>
        </div>
        <button class="btn-pdf-download" id="btnDownloadPdf" onclick="window.downloadProfessionalPDF()">
          📥 DOWNLOAD OFFICIAL ESTIMATE PDF
        </button>
        <button class="btn-pdf-share" onclick="window.shareWhatsAppPDF()">
          📲 SHARE OFFICIAL PDF ON WHATSAPP
        </button>
      </div>
    `;
  },

  sync(row) {
    if (!row) return;
    const url = (row.quotation_pdf_url || row.pdf_url || '').trim();
    const btn = document.getElementById('btnDownloadPdf');
    const badge = document.getElementById('pdfStatusBadge');
    if (url.length > 0) {
      if (btn) {
        btn.innerText = '📥 DOWNLOAD OFFICIAL ESTIMATE PDF (VERIFIED)';
        btn.classList.add('btn-pdf-active');
      }
      if (badge) {
        badge.innerText = '✓ PDF READY';
        badge.style.backgroundColor = '#16a34a';
      }
    }
  },

  downloadPDF() {
    const data = window.PortalState.portalData;
    const url = data && (data.quotation_pdf_url || data.pdf_url);
    if (url && url.trim().length > 0) {
      window.open(url, '_blank');
    } else {
      alert("PDF quotation is being prepared. Tap 'SAVE / SHARE PDF' in the PCM Admin App to auto-sync.");
    }
  },

  shareWhatsApp() {
    const data = window.PortalState.portalData;
    const sid = window.PortalState.currentSiteId;
    const base = window.location.origin + window.location.pathname;
    const portalUrl = `${base}?site=${sid}`;
    const url = (data && (data.quotation_pdf_url || data.pdf_url)) || portalUrl;
    const clientName = data?.client_name || 'Valued Client';
    const text = `Hello ${clientName},\n\nHere is your official PCM WAYANAD False Ceiling detailed estimate PDF for Site ${sid.toUpperCase()}:\n\n📄 Download PDF: ${url}\n\n🌐 Live Portal: ${portalUrl}`;
    window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
  }
};

window.downloadProfessionalPDF = () => window.PortalPdfComponent.downloadPDF();
window.shareWhatsAppPDF = () => window.PortalPdfComponent.shareWhatsApp();
