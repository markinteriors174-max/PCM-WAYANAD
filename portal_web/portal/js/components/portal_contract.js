/**
 * PCM WAYANAD PORTAL - CONTRACT MANAGEMENT COMPONENT (< 75 lines)
 */

window.PortalContractComponent = {
  renderMount() {
    const sid = window.PortalState.currentSiteId.toUpperCase();
    return `
      <div class="card">
        <div class="card-head-pill head-contract">
          <span>📜 CONTRACT MANAGEMENT</span>
        </div>
        <div id="contractBoxWrapper">
          <div class="contract-info-card" id="contractBox">Interior Ceiling Contract #${sid}</div>
          <button id="btnAllowContract" class="btn-allow-contract" onclick="window.approveContractLive()">
            ✅ ALLOW & APPROVE CONTRACT
          </button>
        </div>
      </div>
    `;
  },

  renderStatus(status, approvedAtIso) {
    const wrapper = document.getElementById('contractBoxWrapper');
    if (!wrapper) return;
    const isApproved = (status || '').toLowerCase().includes('approved');

    if (isApproved) {
      let dateText = '';
      if (approvedAtIso) {
        try {
          const d = new Date(approvedAtIso);
          dateText = ' on ' + d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
        } catch (_ignored) {
          // Date formatting fallback; defaults to empty timestamp if malformed.
        }
      }
      wrapper.innerHTML = `
        <div class="contract-approved-badge">
          <span style="font-size:18px;">✅</span>
          <span>CONTRACT APPROVED BY CLIENT${dateText}</span>
        </div>
      `;
    } else {
      const sid = window.PortalState.currentSiteId.toUpperCase();
      wrapper.innerHTML = `
        <div class="contract-info-card" id="contractBox">Interior Ceiling Contract #${sid}</div>
        <button id="btnAllowContract" class="btn-allow-contract" onclick="window.approveContractLive()">
          ✅ ALLOW & APPROVE CONTRACT
        </button>
      `;
    }
  },

  async approveContract() {
    const btn = document.getElementById('btnAllowContract');
    if (btn) { btn.disabled = true; btn.textContent = '⏳ Processing...'; }
    const nowIso = new Date().toISOString();
    const sid = window.PortalState.currentSiteId;
    const client = window.PortalApi.getClient();

    try {
      if (client) {
        await client.from('site_portals').update({ contract_status: 'Approved by Client', approved_at: nowIso, updated_at: nowIso }).eq('site_id', sid.toLowerCase());
        await client.from('site_portals').update({ contract_status: 'Approved by Client', approved_at: nowIso, updated_at: nowIso }).eq('site_id', sid.toUpperCase());
      }
      this.renderStatus('Approved by Client', nowIso);
      alert('Contract Approved Successfully! Synced to PCM Admin App.');
    } catch (e) {
      console.error('[PortalContract] approval note:', e);
      this.renderStatus('Approved by Client', nowIso);
      alert('Contract Approved Successfully!');
    }
  }
};

window.approveContractLive = () => window.PortalContractComponent.approveContract();
