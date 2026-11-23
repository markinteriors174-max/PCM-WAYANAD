/**
 * PCM WAYANAD PORTAL - PROJECT DETAILS & LEDGER COMPONENT
 * Renders the full ledger layout (Total SqFt, Photos Count, Project Amount,
 * Advance Payment, Received via Logs, Labor Expenses, Net Balance Due).
 */

window.PortalLedgerComponent = {
  renderMount() {
    return `
      <div class="card p-0 overflow-hidden" id="ledgerCardSection" style="margin-top: 14px; border: 1px solid #e2e8f0; border-radius: 18px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); background: #ffffff;">
        <div class="card-head-pill pill-ledger flex items-center justify-between px-5 pt-4 pb-3 border-b border-slate-100" style="margin-bottom: 0;">
          <div class="flex items-center gap-2">
            <span style="font-size: 16px;">📋</span>
            <span style="font-size: 12px; font-weight: 900; letter-spacing: 0.8px; color: #0f172a; text-transform: uppercase;">PROJECT DETAILS & LEDGER</span>
          </div>
          <span style="font-size: 10px; font-weight: 900; background: #fef3c7; color: #92400e; padding: 3px 8px; border-radius: 999px; border: 1px solid #fde68a;">LIVE SYNCED</span>
        </div>
        
        <div class="ledger-rows-wrapper" style="display: flex; flex-direction: column;">
          <!-- Total Square Footage -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9;">
            <span style="font-size: 12px; font-weight: 700; color: #475569;">Total Square Footage</span>
            <span id="ledgerValSqFt" style="font-size: 14px; font-weight: 900; color: #0f172a; font-family: monospace;">0.00 sq.ft</span>
          </div>

          <!-- Total Photos Added -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9;">
            <span style="font-size: 12px; font-weight: 700; color: #475569;">Total Photos Added</span>
            <span id="ledgerValPhotos" style="font-size: 14px; font-weight: 900; color: #334155; font-family: monospace;">0 Photos</span>
          </div>

          <!-- Total Project Amount -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9; background: #fafafa;">
            <span style="font-size: 12px; font-weight: 800; color: #1e293b;">Total Project Amount</span>
            <span id="ledgerValContract" style="font-size: 15px; font-weight: 900; color: #0f172a; font-family: monospace;">₹0.00</span>
          </div>

          <!-- Advance Payment -->
          <div class="ledger-row" id="ledgerRowAdvance" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9;">
            <span style="font-size: 12px; font-weight: 700; color: #0369a1;">Advance Payment</span>
            <span id="ledgerValAdvance" style="font-size: 14px; font-weight: 900; color: #0284c7; font-family: monospace;">₹0.00</span>
          </div>

          <!-- Received via Logs -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9;">
            <span style="font-size: 12px; font-weight: 700; color: #0369a1;">Received via Logs</span>
            <span id="ledgerValReceivedLogs" style="font-size: 14px; font-weight: 900; color: #0284c7; font-family: monospace;">₹0.00</span>
          </div>

          <!-- Labor Expenses -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 13px 18px; border-bottom: 1px solid #f1f5f9;">
            <span style="font-size: 12px; font-weight: 700; color: #c2410c;">Labor Expenses</span>
            <span id="ledgerValLabor" style="font-size: 14px; font-weight: 900; color: #d97706; font-family: monospace;">₹0.00</span>
          </div>

          <!-- Net Balance Due -->
          <div class="ledger-row" style="display: flex; justify-content: space-between; align-items: center; padding: 15px 18px; background: #fff1f2; border-top: 2px solid #fecdd3;">
            <span style="font-size: 13px; font-weight: 900; color: #881337; text-transform: uppercase;">Net Balance Due</span>
            <span id="ledgerValDue" style="font-size: 17px; font-weight: 900; color: #e11d48; font-family: monospace;">₹0.00</span>
          </div>
        </div>
      </div>
    `;
  },

  sync(row) {
    if (!row) return;

    const ld = row.ledger_data || {};

    // 1. Total Square Footage
    let sqft = ld.total_sqft != null ? Number(ld.total_sqft) : (row.total_sqft != null ? Number(row.total_sqft) : null);
    if (sqft == null && Array.isArray(row.rooms_data) && row.rooms_data.length > 0) {
      sqft = row.rooms_data.reduce((acc, r) => acc + (Number(r.area_sqft || r.area || r.sqft) || 0), 0);
    }
    const sqftEl = document.getElementById('ledgerValSqFt');
    if (sqftEl) sqftEl.innerText = (sqft != null && sqft > 0) ? `${sqft.toFixed(2)} sq.ft` : 'Direct Execution';

    // 2. Total Photos Added
    let photosCount = ld.photos_count != null ? Number(ld.photos_count) : (row.photos_count != null ? Number(row.photos_count) : null);
    if (photosCount == null) {
      const pSet = new Set();
      if (Array.isArray(row.photos)) row.photos.forEach(p => p && (p.url || p.image_url) && pSet.add(p.url || p.image_url));
      if (Array.isArray(row.site_photos)) row.site_photos.forEach(u => u && pSet.add(u));
      if (Array.isArray(row.portfolio_gallery)) row.portfolio_gallery.forEach(u => u && pSet.add(u));
      if (Array.isArray(row.rooms_data)) {
        row.rooms_data.forEach(r => {
          if (Array.isArray(r.photos)) r.photos.forEach(u => u && pSet.add(u));
        });
      }
      photosCount = pSet.size;
    }
    const photosEl = document.getElementById('ledgerValPhotos');
    if (photosEl) photosEl.innerText = `${photosCount} Photos`;

    // 3. Total Project Amount
    const contract = Number(ld.total_project_amount ?? row.total_contract ?? row.total_amount ?? 0);
    const contractEl = document.getElementById('ledgerValContract');
    if (contractEl) contractEl.innerText = window.formatInr(contract);

    // 4. Advance Payment
    const advance = Number(ld.advance_payment ?? row.advance_payment ?? row.paid_amount ?? 0);
    const advEl = document.getElementById('ledgerValAdvance');
    const advRow = document.getElementById('ledgerRowAdvance');
    if (advEl) advEl.innerText = window.formatInr(advance);
    if (advRow) advRow.style.display = advance > 0 ? 'flex' : 'none';

    // 5. Received via Logs
    let receivedLogs = ld.received_via_logs != null ? Number(ld.received_via_logs) : (row.received_via_logs != null ? Number(row.received_via_logs) : null);
    if (receivedLogs == null && Array.isArray(row.receipts)) {
      receivedLogs = row.receipts
        .filter(r => r && r.type === 'credit' && r.category !== 'Advance Payment')
        .reduce((sum, r) => sum + (Number(r.amount) || 0), 0);
    }
    const recLogsEl = document.getElementById('ledgerValReceivedLogs');
    if (recLogsEl) recLogsEl.innerText = window.formatInr(receivedLogs || 0);

    // 6. Labor Expenses
    const labor = Number(ld.labor_expenses ?? row.labor_expenses ?? row.total_labor_cost ?? 0);
    const laborEl = document.getElementById('ledgerValLabor');
    if (laborEl) laborEl.innerText = window.formatInr(labor);

    // 7. Net Balance Due
    const totalRec = Number(ld.total_received ?? row.total_received ?? (advance + (receivedLogs || 0)));
    const due = ld.net_balance_due != null ? Number(ld.net_balance_due) : (row.balance_due != null ? Number(row.balance_due) : Math.max(0, contract - totalRec));
    const dueEl = document.getElementById('ledgerValDue');
    if (dueEl) {
      dueEl.innerText = window.formatInr(due);
      if (due <= 0) {
        dueEl.style.color = '#15803d';
        dueEl.parentElement.style.background = '#f0fdf4';
        dueEl.parentElement.style.borderTop = '2px solid #bbf7d0';
      } else {
        dueEl.style.color = '#e11d48';
        dueEl.parentElement.style.background = '#fff1f2';
        dueEl.parentElement.style.borderTop = '2px solid #fecdd3';
      }
    }
  }
};
