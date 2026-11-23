/**
 * PCM WAYANAD - Client Portal: Realtime Portal Sync & Multi-Table Query Module (< 95 lines)
 */
(function (window) {
  'use strict';

  async function initRealtimePortalSync() {
    const client = window.getSupabase ? window.getSupabase() : null;
    if (!client) return;

    const activeSiteId = (localStorage.getItem('pcm_client_site_id') || '').trim();
    const activePin = (localStorage.getItem('pcm_active_site_pin') || '').trim();
    const phoneQuery = window.getCleanPhone10 ? window.getCleanPhone10(localStorage.getItem('pcm_client_phone') || '') : '';
    let rec = null;

    // 1. Query site_portals by site_id variants
    if (activeSiteId) {
      const digits = activeSiteId.replace(/\D/g, '');
      const sids = [activeSiteId, activeSiteId.toLowerCase(), activeSiteId.toUpperCase()];
      if (digits) sids.push(`pcm-ms-${digits}`, `PCM-MS-${digits}`, `pcm-${digits}`, digits);
      const orClause = sids.map(s => `site_id.eq.${s}`).join(',');
      const { data } = await client.from('site_portals').select('*').or(orClause).order('updated_at', { ascending: false }).limit(1);
      if (data && data.length > 0) rec = data[0];
    }

    // 2. Query site_portals by phone
    if (!rec && phoneQuery.length >= 10) {
      const { data } = await client.from('site_portals').select('*').ilike('client_phone', `%${phoneQuery}%`).order('updated_at', { ascending: false }).limit(1);
      if (data && data.length > 0) rec = data[0];
    }

    // 3. Fallback to site_folders
    if (!rec && (activeSiteId || phoneQuery.length >= 10)) {
      const sfConds = [];
      if (activeSiteId) sfConds.push(`id.eq.${activeSiteId}`, `unit_number.eq.${activeSiteId}`, `unit_number.ilike.%${activeSiteId}%`);
      if (phoneQuery.length >= 10) sfConds.push(`phone.ilike.%${phoneQuery}%`, `phone_number.ilike.%${phoneQuery}%`);
      const { data: sf } = await client.from('site_folders').select('*').or(sfConds.join(',')).order('updated_at', { ascending: false }).limit(1);
      if (sf && sf.length > 0) {
        const f = sf[0];
        rec = {
          ...f,
          site_id: f.unit_number || f.id || activeSiteId,
          client_name: f.client_name || f.name,
          client_phone: f.phone || f.phone_number,
          site_pin: f.soft_pin || f.pin || activePin,
          total_contract: f.total_contract ?? f.contract_amount ?? 0,
          total_received: f.total_received ?? f.paid_to_date ?? f.paid_amount ?? 0,
          paid_amount: f.paid_amount ?? f.paid_to_date ?? f.total_received ?? 0,
          balance_due: f.balance_due ?? 0,
          quotation_pdf_url: f.quotation_pdf_url || f.pdf_url || f.estimate_pdf_url || '',
          framing_progress: f.framing_progress ?? f.progress_framing ?? 0,
          boarding_progress: f.boarding_progress ?? f.progress_boarding ?? 0,
          finishing_progress: f.finishing_progress ?? f.progress_finishing ?? 0,
          painting_progress: f.painting_progress ?? f.progress_painting ?? 0,
          cleanup_progress: f.cleanup_progress ?? f.progress_cleanup ?? 0,
          rooms_data: f.rooms_data || []
        };
      }
    }
    if (!rec) return;

    // Normalize & Cache
    rec.total_contract = Number(rec.total_contract) || 0;
    rec.total_received = Number(rec.total_received ?? rec.paid_amount ?? rec.paid_to_date) || 0;
    rec.paid_amount = rec.total_received;
    rec.balance_due = rec.balance_due != null ? Number(rec.balance_due) : Math.max(0, rec.total_contract - rec.total_received);
    rec.quotation_pdf_url = (rec.quotation_pdf_url || rec.pdf_url || '').trim();
    rec.pdf_url = rec.quotation_pdf_url;
    window.currentPortalRecord = rec;

    // Header badges
    const setBadge = (id, text) => { const el = document.getElementById(id); if (el) { el.textContent = text; el.classList.remove('hidden'); } };
    setBadge('portalPinBadge', `PIN: ${rec.site_pin || activePin || '1234'}`);
    setBadge('portalClientBadge', `👤 ${rec.client_name || 'Client'}`);
    setBadge('portalLocationBadge', `📍 ${rec.site_location || rec.location || 'Wayanad, Kerala'}`);

    // Quotation PDF link in portal view
    const pdfBox = document.getElementById('portalPdfContainer');
    const pdfBtn = document.getElementById('portalPdfDownloadBtn');
    if (rec.quotation_pdf_url) {
      if (pdfBox) pdfBox.classList.remove('hidden');
      if (pdfBtn) pdfBtn.href = rec.quotation_pdf_url;
    }

    if (typeof window.renderPortalRooms === 'function') window.renderPortalRooms(rec.rooms_data);
    if (typeof window.renderPortal3DSection === 'function') window.renderPortal3DSection(rec.rooms_data, rec);
    if (typeof window.renderPortalFinancials === 'function') window.renderPortalFinancials(rec);
    if (typeof window.renderPortalMilestones === 'function') window.renderPortalMilestones(rec);

    if (typeof window.loadChatMessages === 'function') window.loadChatMessages(rec.site_pin || activePin, rec.site_id);
    if (typeof window.subscribeRealtimePortal === 'function') window.subscribeRealtimePortal(rec.site_pin || activePin, rec.site_id);
  }

  window.initRealtimePortalSync = initRealtimePortalSync;
})(window);
