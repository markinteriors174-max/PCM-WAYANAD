/**
 * PCM WAYANAD PORTAL - ACCOUNT STATEMENT & TRANSACTION LEDGER (< 90 lines)
 */

window.PortalStatementComponent = {
  renderMount() {
    return `
      <div class="card" id="statementCardSection">
        <div class="card-head-pill pill-receipts flex items-center justify-between">
          <span class="font-bold">📊 ACCOUNT STATEMENT & TRANSACTION LEDGER</span>
          <span class="badge-realtime text-xs px-2 py-0.5 rounded bg-blue-100 text-blue-800 font-semibold">LIVE LEDGER</span>
        </div>
        <div class="statement-container mt-3 overflow-x-auto">
          <div id="statementEmptyMsg" class="text-sm text-gray-500 py-4 text-center">
            Loading official account statement...
          </div>
          <table class="w-full text-left text-xs border-collapse hidden" id="statementTable">
            <thead>
              <tr class="border-b border-gray-200 bg-gray-50 text-gray-600 font-bold uppercase">
                <th class="py-2.5 px-3">Date</th>
                <th class="py-2.5 px-3">Transaction / Description</th>
                <th class="py-2.5 px-3">Type</th>
                <th class="py-2.5 px-3 text-right">Amount (₹)</th>
                <th class="py-2.5 px-3 text-right">Balance Due</th>
              </tr>
            </thead>
            <tbody id="statementTableBody" class="divide-y divide-gray-100"></tbody>
          </table>
        </div>
      </div>
    `;
  },

  sync(row) {
    if (!row) return;
    const receipts = row.receipts || row.payment_receipts || [];
    const table = document.getElementById('statementTable');
    const tbody = document.getElementById('statementTableBody');
    const emptyMsg = document.getElementById('statementEmptyMsg');
    if (!table || !tbody || !emptyMsg) return;

    if (!Array.isArray(receipts) || receipts.length === 0) {
      table.classList.add('hidden');
      emptyMsg.classList.remove('hidden');
      emptyMsg.innerText = "No payment transactions logged yet. Formal account statement will appear here as payments are recorded.";
      return;
    }

    emptyMsg.classList.add('hidden');
    table.classList.remove('hidden');

    tbody.innerHTML = receipts.map((r) => {
      const isCredit = (r.type === 'credit' || r.category === 'Advance Payment' || r.category === 'Progress Payment');
      const badgeClass = isCredit ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800';
      const badgeText = isCredit ? 'CREDIT / PAYMENT' : 'DEBIT / INVOICE';
      const amtStr = (isCredit ? '- ' : '+ ') + window.formatInr(Number(r.amount || 0));
      const balStr = r.running_balance != null ? window.formatInr(Number(r.running_balance)) : '-';
      const dateStr = r.date || '-';
      const title = r.title || r.description || 'Payment Transaction';

      return `
        <tr class="hover:bg-gray-50 transition-colors">
          <td class="py-2.5 px-3 font-medium text-gray-700 whitespace-nowrap">${dateStr}</td>
          <td class="py-2.5 px-3">
            <div class="font-bold text-gray-900">${title}</div>
            ${r.mode ? `<div class="text-[10px] text-gray-400 font-mono">${r.mode}</div>` : ''}
          </td>
          <td class="py-2.5 px-3 whitespace-nowrap">
            <span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-bold ${badgeClass}">${badgeText}</span>
          </td>
          <td class="py-2.5 px-3 text-right font-bold ${isCredit ? 'text-emerald-700' : 'text-gray-900'} whitespace-nowrap">${amtStr}</td>
          <td class="py-2.5 px-3 text-right font-mono font-semibold text-gray-700 whitespace-nowrap">${balStr}</td>
        </tr>
      `;
    }).join('');
  }
};
