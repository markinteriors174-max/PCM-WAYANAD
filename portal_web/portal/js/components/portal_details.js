/**
 * PCM WAYANAD PORTAL - CLIENT & BILLING DETAILS COMPONENT (< 60 lines)
 */

window.PortalDetailsComponent = {
  renderMount() {
    return `
      <div class="card">
        <div class="card-head-pill head-details">
          <span>👤 CLIENT & BILLING DETAILS</span>
          <span class="badge-verified-blue">VERIFIED</span>
        </div>
        <div class="detail-grid">
          <div class="detail-item">
            <div class="detail-label">Customer Type</div>
            <div class="detail-val" id="valCustomerType">Direct Customer</div>
          </div>
          <div class="detail-item">
            <div class="detail-label">GST Registered (B2B)</div>
            <div class="detail-val">
              <span id="valGstStatus" class="gst-tag gst-no">Individual (Non-GST)</span>
            </div>
          </div>
          <div class="detail-item detail-item-full">
            <div class="detail-label">Official Email for Invoices</div>
            <div class="detail-val" id="valEmail">Not provided (Updates sent via WhatsApp)</div>
          </div>
        </div>
      </div>
    `;
  },

  syncGst(row) {
    const hasField = row.gstin_enabled !== undefined || row.gst_registered !== undefined || Boolean(row.gstin);
    if (!hasField) return;

    const isGst = Boolean(row.gstin_enabled || row.gst_registered || row.gstin?.toString().trim());
    const el = document.getElementById('valGstStatus');
    if (!el) return;

    el.className = `gst-tag ${isGst ? 'gst-yes' : 'gst-no'}`;
    el.innerText = isGst ? `GST Registered (${row.gstin || 'B2B'})` : 'Individual (Non-GST)';
  },

  sync(row) {
    if (!row) return;
    if (row.customer_type) {
      const ct = document.getElementById('valCustomerType');
      if (ct) ct.innerText = row.customer_type;
    }
    this.syncGst(row);
    if (row.email?.toString().trim()) {
      const em = document.getElementById('valEmail');
      if (em) em.innerText = row.email;
    }
  }
};
