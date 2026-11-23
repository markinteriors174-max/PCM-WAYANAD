/**
 * PCM WAYANAD PORTAL - CHAT SERVICE (< 70 lines)
 */

window.PortalChatService = {
  async loadChat() {
    const client = window.PortalApi.getClient();
    if (!client) return;
    try {
      const sid = window.PortalState.currentSiteId;
      const { data, error } = await client
        .from('site_chat_messages')
        .select('*')
        .or(`site_id.eq.${sid.toLowerCase()},site_id.eq.${sid.toUpperCase()}`)
        .order('created_at', { ascending: true });

      if (data && !error && data.length > 0) {
        data.forEach(m => {
          if (window.PortalChatComponent) {
            window.PortalChatComponent.renderBubble(m.sender, m.message || m.text || '', m.created_at);
          }
        });
      }
    } catch (err) {
      console.warn('[PortalChatService] loadChat note:', err);
    }
  },

  async sendMessage(e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    const input = document.getElementById('chatInput');
    if (!input) return;
    const text = input.value.trim();
    if (!text) return;
    input.value = '';

    const nowIso = new Date().toISOString();
    const sid = window.PortalState.currentSiteId.toLowerCase();
    const msgObj = {
      site_id: sid,
      sender: 'client',
      message: text,
      created_at: nowIso
    };

    if (window.PortalChatComponent) {
      window.PortalChatComponent.renderBubble('client', text, nowIso);
    }

    try {
      const client = window.PortalApi.getClient();
      if (client) {
        await client.from('site_chat_messages').insert([msgObj]);
      }
    } catch (err) {
      console.error('[PortalChatService] sendMessage err:', err);
    }
  }
};

window.sendClientMessage = function(e) {
  return window.PortalChatService.sendMessage(e);
};
