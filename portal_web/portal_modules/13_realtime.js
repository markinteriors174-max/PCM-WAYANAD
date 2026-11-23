/**
 * PCM WAYANAD - Client Portal: Realtime WebSocket Subscription Module (< 80 lines)
 */
(function (window) {
  'use strict';

  let _channel = null;

  function subscribeRealtimePortal(pin, siteId) {
    const client = window.getSupabase ? window.getSupabase() : null;
    if (!client) return;

    const cleanSiteId = (siteId || '').toLowerCase();
    if (_channel) {
      try { client.removeChannel(_channel); } catch (_) {}
      _channel = null;
    }

    if (typeof window.listenToAdminChanges === 'function') window.listenToAdminChanges(cleanSiteId);

    try {
      _channel = client
        .channel(`portal_rt_${cleanSiteId || 'global'}_${Date.now()}`)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'site_portals' }, (payload) => {
          if (payload.eventType === 'DELETE') {
            if (typeof window.performForceSignOut === 'function') window.performForceSignOut();
            else if (typeof window.initRealtimePortalSync === 'function') window.initRealtimePortalSync();
          } else if (payload.new) {
            handleRealtimePayload(payload.new);
          }
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'site_folders' }, (payload) => {
          if (payload.eventType === 'DELETE') {
            if (typeof window.performForceSignOut === 'function') window.performForceSignOut();
            else if (typeof window.initRealtimePortalSync === 'function') window.initRealtimePortalSync();
          } else if (payload.new) {
            handleRealtimePayload(payload.new);
          }
        })
        .subscribe();
    } catch (_) {}
  }

  function handleRealtimePayload(newRow) {
    if (!newRow) return;
    const currentSite = (localStorage.getItem('pcm_client_site_id') || '').toLowerCase();
    const currentPhone = window.getCleanPhone10 ? window.getCleanPhone10(localStorage.getItem('pcm_client_phone') || '') : '';

    const rowSite = (newRow.site_id || newRow.unit_number || newRow.id || '').toLowerCase();
    const rowPhone = window.getCleanPhone10 ? window.getCleanPhone10(newRow.client_phone || newRow.phone || newRow.phone_number || '') : '';

    const matchesSite = currentSite && rowSite && (rowSite === currentSite || currentSite.includes(rowSite) || rowSite.includes(currentSite));
    const matchesPhone = currentPhone.length >= 10 && rowPhone && (rowPhone === currentPhone || rowPhone.includes(currentPhone));

    if (matchesSite || matchesPhone) {
      const cur = window.currentPortalRecord || {};
      const merged = { ...cur, ...newRow };
      if (newRow.total_contract != null) merged.total_contract = Number(newRow.total_contract);
      if (newRow.total_received != null || newRow.paid_amount != null || newRow.paid_to_date != null) {
        merged.total_received = Number(newRow.total_received ?? newRow.paid_amount ?? newRow.paid_to_date ?? cur.total_received);
        merged.paid_amount = merged.total_received;
      }
      if (newRow.balance_due != null) merged.balance_due = Number(newRow.balance_due);
      if (newRow.quotation_pdf_url || newRow.pdf_url) {
        merged.quotation_pdf_url = (newRow.quotation_pdf_url || newRow.pdf_url || '').trim();
        merged.pdf_url = merged.quotation_pdf_url;
      }
      window.currentPortalRecord = merged;

      if (typeof window.renderPortalMilestones === 'function') window.renderPortalMilestones(merged);
      if (merged.rooms_data && typeof window.renderPortalRooms === 'function') window.renderPortalRooms(merged.rooms_data);
      if (typeof window.renderPortalFinancials === 'function') window.renderPortalFinancials(merged);
      if (merged.rooms_data && typeof window.renderPortal3DSection === 'function') window.renderPortal3DSection(merged.rooms_data, merged);
    }
  }

  window.subscribeRealtimePortal = subscribeRealtimePortal;
})(window);
