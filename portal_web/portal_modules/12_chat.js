/**
 * PCM WAYANAD - Client Portal: Real-Time Client-Engineer Chat Module
 */
(function (window) {
  'use strict';

  async function loadChatMessages(pin, siteId) {
    const container = document.getElementById('portalChatContainer');
    if (!container) return;
    const client = window.getSupabase ? window.getSupabase() : null;
    if (!client) return;

    const sId = (siteId || '').toLowerCase();
    try {
      const { data } = await client.from('site_chat_messages').select('*')
        .or(`site_id.eq.${sId},site_pin.eq.${pin}`)
        .order('created_at', { ascending: true });

      if (data && data.length > 0) {
        container.innerHTML = data.map(m => renderChatBubble(m)).join('');
        container.scrollTop = container.scrollHeight;
      } else {
        container.innerHTML = '<div class="text-center py-8 text-slate-500 text-xs">No chat messages yet. Send a query below to reach the PCM site engineer.</div>';
      }
    } catch (_) {}
  }

  async function sendPortalChatMessage(e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    const input = document.getElementById('portalChatInput');
    if (!input) return;
    const text = input.value.trim();
    if (!text) return;

    const pin = localStorage.getItem('pcm_active_site_pin') || '1234';
    const siteId = (localStorage.getItem('pcm_client_site_id') || `PCM-${pin}`).toLowerCase();
    const clientName = localStorage.getItem('pcm_portal_user') || 'Client';

    const newMsg = { site_id: siteId, site_pin: pin, sender: 'client', sender_name: clientName, message: text, created_at: new Date().toISOString() };
    input.value = '';

    const container = document.getElementById('portalChatContainer');
    if (container) {
      if (container.innerHTML.includes('No chat messages yet')) container.innerHTML = '';
      container.innerHTML += renderChatBubble(newMsg);
      container.scrollTop = container.scrollHeight;
    }

    const client = window.getSupabase ? window.getSupabase() : null;
    if (client) {
      try { await client.from('site_chat_messages').insert([newMsg]); }
      catch (_) { try { await client.from('site_chats').insert([newMsg]); } catch (_) {} }
    }
  }

  function renderChatBubble(msg) {
    const isAdmin = msg.sender === 'admin' || msg.sender === 'pcm' || msg.sender === 'ENGINEER';
    const time = msg.created_at ? new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Now';

    return `
      <div class="mb-3 flex flex-col ${isAdmin ? 'items-start' : 'items-end'}">
        <span class="text-[10px] text-slate-400 mb-0.5">${isAdmin ? '🛡️ PCM Engineer' : '👤 You'} • ${time}</span>
        <div class="max-w-[85%] px-3.5 py-2 rounded-2xl text-xs sm:text-sm leading-relaxed ${isAdmin ? 'bg-slate-800 text-white border border-white/10' : 'bg-amber-500 text-slate-950 font-medium'} shadow-md">
          ${msg.message}
        </div>
      </div>
    `;
  }

  window.loadChatMessages = loadChatMessages;
  window.sendPortalChatMessage = sendPortalChatMessage;
  window.renderChatBubble = renderChatBubble;
})(window);
