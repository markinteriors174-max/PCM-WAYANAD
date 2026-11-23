/**
 * PCM WAYANAD PORTAL - REALTIME WEBSOCKET SUBSCRIPTIONS (< 80 lines)
 */

window.PortalRealtime = {
  subscribe() {
    const client = window.PortalApi.getClient();
    if (!client) return;

    // 1. Portals Changes Channel with Real-time Invalidation
    client
      .channel('schema-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'site_portals' }, (payload) => {
        const isCurrentClient = (rec) => {
          if (!rec) return false;
          const sid = (rec.site_id || '').toLowerCase();
          const phone = (rec.client_phone || '').replace(/\D/g, '').slice(-10);
          const curSid = (window.PortalState?.currentSiteId || '').toLowerCase();
          const curPhone = (localStorage.getItem('pcm_client_phone') || '').replace(/\D/g, '').slice(-10);
          return (sid && curSid && sid === curSid) || (phone && curPhone && phone === curPhone);
        };

        if (payload.eventType === 'DELETE') {
          if (isCurrentClient(payload.old)) {
            console.warn('[Portal] Account deleted by administrator in backend. Booting session.');
            alert('⚠️ നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിനിസ്ട്രേറ്റർ നീക്കം ചെയ്തു / Your account was removed by the administrator.');
            if (window.PortalAuthService) window.PortalAuthService.logout();
          }
        } else if (payload.eventType === 'UPDATE') {
          if (isCurrentClient(payload.new)) {
            const status = (payload.new.status || '').toLowerCase();
            if (status.includes('revoked') || status.includes('deleted') || status.includes('inactive') || status.includes('blocked')) {
              alert('⚠️ നിങ്ങളുടെ അക്കൗണ്ട് അക്സസ് റദ്ദാക്കി / Your account access has been revoked.');
              if (window.PortalAuthService) window.PortalAuthService.logout();
            } else if (window.PortalApp) {
              window.PortalApp.syncUI(payload.new);
            }
          }
        } else if (payload.new) {
          const sid = (payload.new.site_id || '').toLowerCase();
          const cur = (window.PortalState?.currentSiteId || '').toLowerCase();
          if (!sid || sid === cur || sid === 'pcm-ms-003') {
            if (window.PortalApp) window.PortalApp.syncUI(payload.new);
          }
        }
      })
      .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'website_leads' }, (payload) => {
        if (payload.old) {
          const oldPhone = (payload.old.phone_number || payload.old.phone || '').replace(/\D/g, '').slice(-10);
          const curPhone = (localStorage.getItem('pcm_client_phone') || '').replace(/\D/g, '').slice(-10);
          if (oldPhone && curPhone && oldPhone === curPhone) {
            console.warn('[Portal] Website lead deleted by administrator. Booting session.');
            alert('⚠️ അക്കൗണ്ട് അഡ്മിനിസ്ട്രേറ്റർ നീക്കം ചെയ്തു / Your registration was removed.');
            if (window.PortalAuthService) window.PortalAuthService.logout();
          }
        }
      })
      .subscribe((status) => {
        const badge = document.getElementById('syncBadge');
        if (badge) {
          if (status === 'SUBSCRIBED') {
            badge.innerText = 'LIVE QUOTATION & SYNC (REALTIME)';
          } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
            badge.innerText = 'LIVE QUOTATION & SYNC (POLLING)';
          }
        }
      });

    // 2. Chat Live Stream Channel
    client
      .channel('chat_live_stream')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'site_chat_messages' }, (payload) => {
        if (payload.new) {
          const sid = (payload.new.site_id || '').toLowerCase();
          const cur = window.PortalState.currentSiteId.toLowerCase();
          if (!sid || sid === cur || sid === 'pcm-ms-003') {
            if (window.PortalChatComponent) {
              window.PortalChatComponent.renderBubble(
                payload.new.sender,
                payload.new.message || payload.new.text || '',
                payload.new.created_at
              );
            }
          }
        }
      })
      .subscribe();

    // 3. Website CMS Realtime Channel
    client
      .channel('cms_realtime_stream')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'website_cms' }, () => {
        window.PortalApi.loadFounderMemorial();
      })
      .subscribe();
  }
};
