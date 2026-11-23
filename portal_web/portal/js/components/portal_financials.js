/**
 * PCM WAYANAD PORTAL - FINANCIAL STATS COMPONENT (< 60 lines)
 */

window.PortalFinancialsComponent = {
  renderMount() {
    return `
      <div class="finance-grid">
        <div class="fin-box">
          <div class="fin-lbl col-contract">TOTAL CONTRACT</div>
          <div class="fin-val col-contract" id="valContract">₹0.00</div>
        </div>
        <div class="fin-box">
          <div class="fin-lbl col-paid">PAID TO DATE</div>
          <div class="fin-val col-paid" id="valPaid">₹0.00</div>
        </div>
        <div class="fin-box">
          <div class="fin-lbl col-due">BALANCE DUE</div>
          <div class="fin-val col-due" id="valDue">₹0.00</div>
        </div>
      </div>
    `;
  },

  sync(row) {
    if (!row) return;
    const contract = Number(row.total_contract) || 0;
    const paid = Number(row.total_received ?? row.paid_amount ?? row.paid_to_date) || 0;
    const due = row.balance_due != null ? Number(row.balance_due) : Math.max(0, contract - paid);

    const elC = document.getElementById('valContract');
    const elP = document.getElementById('valPaid');
    const elD = document.getElementById('valDue');
    if (elC) elC.innerText = window.formatInr ? window.formatInr(contract) : `₹${contract.toLocaleString('en-IN')}`;
    if (elP) elP.innerText = window.formatInr ? window.formatInr(paid) : `₹${paid.toLocaleString('en-IN')}`;
    if (elD) elD.innerText = window.formatInr ? window.formatInr(due) : `₹${due.toLocaleString('en-IN')}`;
    if (window.PortalUpiComponent) window.PortalUpiComponent.updateAmount(due);
  }
};
