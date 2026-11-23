/**
 * PCM WAYANAD PORTAL - ZERO-FEE DIRECT UPI & PAYMENT COMPONENT (< 90 lines)
 */

window.PortalUpiComponent = {
  currentDue: 0,
  vpa: 'pcmwayanad@okaxis',
  payeeName: 'PCM WAYANAD',

  renderMount() {
    return `
      <div class="card qr-card-center glass-card" style="border: 1px solid rgba(245, 158, 11, 0.3); border-radius: 18px; padding: 20px; background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(12px); box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
        <div class="card-head-pill head-qr" style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; flex-wrap: wrap; gap: 8px;">
          <span style="font-weight: 900; letter-spacing: 0.5px; color: #f59e0b; font-size: 13px;">⚡ ZERO-FEE DIRECT UPI & BANK TRANSFER</span>
          <span style="background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.4); color: #10b981; font-size: 10px; font-weight: 800; padding: 3px 8px; border-radius: 20px;">0% GATEWAY DEDUCTION</span>
        </div>

        <div style="text-align: center; margin-bottom: 12px;">
          <div style="font-size: 12px; color: #94a3b8; font-weight: 500;">Active Balance Due / ബാക്കി തുക</div>
          <div id="upiDueAmountDisplay" style="font-size: 24px; font-weight: 900; color: #fbbf24; font-family: 'Outfit', sans-serif;">₹0.00</div>
        </div>

        <div class="qr-wrap" style="display: flex; justify-content: center; margin: 12px 0;">
          <div style="padding: 10px; background: #ffffff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); display: inline-block;">
            <img id="upiQrImg" class="qr-img" src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=upi://pay?pa=pcmwayanad@okaxis%26pn=PCM%20WAYANAD%26am=0.00%26cu=INR" alt="Google Pay Business UPI QR Code" width="170" height="170" style="display: block; border-radius: 8px;">
          </div>
        </div>

        <div style="display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin: 14px 0;">
          <a id="gpayDirectBtn" href="upi://pay?pa=pcmwayanad@okaxis&pn=PCM%20WAYANAD&cu=INR" class="pay-btn" style="flex: 1; min-width: 140px; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 6px; padding: 10px 14px; background: #0f172a; border: 1px solid rgba(245, 158, 11, 0.4); border-radius: 10px; color: #fbbf24; font-size: 12px; font-weight: 700; transition: all 0.2s;">
            <span>⚡ Open Google Pay</span>
          </a>
          <a id="upiIntentBtn" href="upi://pay?pa=pcmwayanad@okaxis&pn=PCM%20WAYANAD&cu=INR" class="pay-btn" style="flex: 1; min-width: 140px; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 6px; padding: 10px 14px; background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.4); border-radius: 10px; color: #34d399; font-size: 12px; font-weight: 700; transition: all 0.2s;">
            <span>📱 PhonePe / Any UPI</span>
          </a>
        </div>

        <div style="margin-top: 12px; padding: 10px; background: rgba(15, 23, 42, 0.6); border-radius: 10px; border: 1px solid rgba(255,255,255,0.05); font-size: 11px; color: #94a3b8; text-align: center;">
          <span>Official VPA: </span><strong style="color: #f8fafc; font-family: monospace;">pcmwayanad@okaxis</strong>
          <span style="display: block; margin-top: 4px; font-size: 10px; color: #64748b;">Direct account settlement ensures 100% of your payment is credited without 2% merchant gateway commissions.</span>
        </div>
      </div>
    `;
  },

  updateAmount(dueAmount) {
    const dueVal = Number(dueAmount || 0);
    this.currentDue = dueVal;

    const displayEl = document.getElementById('upiDueAmountDisplay');
    if (displayEl && window.formatInr) {
      displayEl.innerText = window.formatInr(dueVal);
    }

    const qrImg = document.getElementById('upiQrImg');
    const amStr = dueVal > 0 ? dueVal.toFixed(2) : '0.00';
    const uri = `upi://pay?pa=${this.vpa}&pn=${encodeURIComponent(this.payeeName)}&am=${amStr}&cu=INR`;

    if (qrImg) {
      qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(uri)}`;
    }

    const gpayBtn = document.getElementById('gpayDirectBtn');
    if (gpayBtn) gpayBtn.href = uri;

    const upiBtn = document.getElementById('upiIntentBtn');
    if (upiBtn) upiBtn.href = uri;
  }
};
