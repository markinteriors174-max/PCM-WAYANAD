/**
 * PCM WAYANAD - Client Portal: Financial Summary & Statement Renderer Module (< 75 lines)
 */
(function (window) {
  'use strict';

  function renderPortalFinancials(record) {
    if (!record) return;

    const contractEl = document.getElementById('portalTotalContract');
    const paidEl = document.getElementById('portalTotalPaid');
    const dueEl = document.getElementById('portalBalanceDue');
    const barEl = document.getElementById('portalPaymentProgressBar');
    const receiptsContainer = document.getElementById('portalReceiptsContainer');

    const contract = Number(record.total_contract) || 0;
    const paid = Number(record.total_received ?? record.paid_amount ?? record.paid_to_date) || 0;
    const due = Number(record.balance_due) || Math.max(0, contract - paid);

    if (contractEl) contractEl.textContent = `₹${contract.toLocaleString('en-IN')}`;
    if (paidEl) paidEl.textContent = `₹${paid.toLocaleString('en-IN')}`;
    if (dueEl) dueEl.textContent = `₹${due.toLocaleString('en-IN')}`;

    if (barEl) {
      const pct = contract > 0 ? Math.min(100, Math.round((paid / contract) * 100)) : 0;
      barEl.style.width = `${pct}%`;
      const pctLabel = document.getElementById('portalPaymentPctLabel');
      if (pctLabel) pctLabel.textContent = `${pct}% Paid`;
    }

    // Quotation PDF link
    const pdfUrl = (record.quotation_pdf_url || record.pdf_url || '').trim();
    const pdfBox = document.getElementById('portalPdfContainer');
    const pdfBtn = document.getElementById('portalPdfDownloadBtn');
    if (pdfUrl) {
      if (pdfBox) pdfBox.classList.remove('hidden');
      if (pdfBtn) pdfBtn.href = pdfUrl;
    }

    if (!receiptsContainer) return;
    const receipts = Array.isArray(record.receipts) ? record.receipts : [];

    if (receipts.length === 0) {
      receiptsContainer.innerHTML = '<div class="text-center py-6 text-slate-500 text-xs">No formal payment receipts posted yet.</div>';
      return;
    }

    receiptsContainer.innerHTML = receipts.map(rc => {
      const isCredit = rc.type === 'credit';
      return `
        <div class="p-3.5 rounded-xl bg-slate-900/60 border border-white/10 flex items-center justify-between gap-3">
          <div>
            <div class="flex items-center gap-2">
              <span class="text-xs font-bold text-white">${rc.title || 'Payment Entry'}</span>
              <span class="px-2 py-0.5 rounded-full text-[9px] font-black uppercase ${isCredit ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'}">${rc.category || (isCredit ? 'Credit' : 'Debit')}</span>
            </div>
            <p class="text-[11px] text-slate-400 mt-0.5">${rc.date || ''} • ${rc.mode || 'Direct Transfer'}</p>
          </div>
          <div class="text-right">
            <span class="text-sm font-black font-mono ${isCredit ? 'text-emerald-400' : 'text-rose-400'}">${isCredit ? '+' : '-'}₹${Number(rc.amount || 0).toLocaleString('en-IN')}</span>
          </div>
        </div>
      `;
    }).join('');
  }

  window.renderPortalFinancials = renderPortalFinancials;
})(window);
