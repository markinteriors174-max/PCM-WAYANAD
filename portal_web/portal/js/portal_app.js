/**
 * PCM WAYANAD PORTAL - APP ORCHESTRATOR & BOOTSTRAP (< 75 lines)
 */

window.PortalApp = {
  syncUI(row) {
    if (!row) return;
    window.PortalState.portalData = row;
    if (window.PortalOverviewComponent) window.PortalOverviewComponent.sync(row);
    if (window.PortalDetailsComponent) window.PortalDetailsComponent.sync(row);
    if (window.PortalLedgerComponent) window.PortalLedgerComponent.sync(row);
    if (window.PortalFinancialsComponent) window.PortalFinancialsComponent.sync(row);
    if (window.PortalStatementComponent) window.PortalStatementComponent.sync(row);
    if (window.PortalPdfComponent && typeof window.PortalPdfComponent.sync === 'function') window.PortalPdfComponent.sync(row);
    if (window.PortalProgressComponent) window.PortalProgressComponent.sync(row);
    if (window.PortalRoomsComponent) window.PortalRoomsComponent.sync(row);
    if (window.Portal3DComponent) window.Portal3DComponent.sync(row);
    if (window.PortalGalleryComponent) window.PortalGalleryComponent.render(row);
    if (window.PortalContractComponent && row.contract_status) {
      window.PortalContractComponent.renderStatus(row.contract_status, row.approved_at);
    }
  },

  async initLoad() {
    const data = await window.PortalApi.fetchPortalData();
    if (data) this.syncUI(data);
  },

  bootstrap() {
    // 1. Mount all UI components into their placeholder elements
    const mounts = [
      ['websiteAuthModalMount', window.PortalAuthModalComponent],
      ['portalHeaderMount', window.PortalHeaderComponent],
      ['overviewMount', window.PortalOverviewComponent],
      ['detailsMount', window.PortalDetailsComponent],
      ['ledgerMount', window.PortalLedgerComponent],
      ['financialsMount', window.PortalFinancialsComponent],
      ['statementMount', window.PortalStatementComponent],
      ['pdfMount', window.PortalPdfComponent],
      ['progressMount', window.PortalProgressComponent],
      ['roomsMount', window.PortalRoomsComponent],
      ['studio3DMount', window.Portal3DComponent],
      ['galleryMount', window.PortalGalleryComponent],
      ['chatMount', window.PortalChatComponent],
      ['contractMount', window.PortalContractComponent],
      ['upiMount', window.PortalUpiComponent]
    ];
    mounts.forEach(([id, comp]) => {
      const el = document.getElementById(id);
      if (el && comp && typeof comp.renderMount === 'function') {
        el.innerHTML = comp.renderMount();
        if (typeof comp.postMount === 'function') comp.postMount();
      }
    });

    // 2. Strict Auth Guard check before loading data
    const isAuth = window.PortalAuthService ? window.PortalAuthService.checkUserSession() : false;
    if (!isAuth) {
      console.warn('[PortalApp] Unauthenticated session. Halting data fetching and polling.');
      return;
    }

    // 3. Realtime WebSocket subscription
    if (window.PortalRealtime && typeof window.PortalRealtime.subscribe === 'function') {
      window.PortalRealtime.subscribe();
    }

    // 4. Initial loads for authenticated client
    this.initLoad();
    if (window.PortalChatService) window.PortalChatService.loadChat();
    if (window.PortalApi) window.PortalApi.loadFounderMemorial();

    // 5. Fallback polling intervals
    setInterval(() => this.initLoad(), 3000);
    setInterval(() => { if (window.PortalChatService) window.PortalChatService.loadChat(); }, 3500);
    setInterval(() => { if (window.PortalApi) window.PortalApi.loadFounderMemorial(); }, 12000);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  window.PortalApp.bootstrap();
});
