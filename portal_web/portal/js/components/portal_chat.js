/**
 * PCM WAYANAD PORTAL - LIVE CHAT COMPONENT (< 85 lines)
 */

window.PortalChatComponent = {
  renderMount() {
    return `
      <div class="card" id="chatSection">
        <div class="card-head-pill head-chat">
          <span>💬 LIVE PROJECT CHAT (PCM TEAM)</span>
          <span class="badge-realtime">REALTIME</span>
        </div>
        <div class="chat-box" id="chatMessagesContainer">
          <div class="chat-empty">No messages yet. Send a message to PCM team below.</div>
        </div>
        <form class="chat-form" id="chatForm" onsubmit="window.sendClientMessage(event); return false;">
          <label for="chatInput" class="sr-only">Type message to PCM Admin</label>
          <input type="text" id="chatInput" class="chat-input" placeholder="Type message to PCM Admin..." aria-label="Type message to PCM Admin" autocomplete="off">
          <button type="submit" id="btnSendChat" class="btn-send-chat">➤ SEND</button>
        </form>
      </div>
    `;
  },

  renderBubble(sender, message, timeIso) {
    if (!message?.trim()) return;
    const container = document.getElementById('chatMessagesContainer');
    if (!container) return;

    const key = `${sender}_${message}_${timeIso || ''}`;
    if (window.PortalState.renderedMsgSet.has(key)) return;
    window.PortalState.renderedMsgSet.add(key);

    const empty = container.querySelector('.chat-empty');
    if (empty) empty.remove();

    const isAdmin = (sender || '').toLowerCase() === 'admin';
    const timeStr = window.formatChatTime(timeIso || new Date().toISOString());

    const bubble = document.createElement('div');
    bubble.className = `chat-bubble ${isAdmin ? 'chat-bubble-admin' : 'chat-bubble-client'}`;

    const tag = document.createElement('span');
    tag.className = `chat-sender-tag ${isAdmin ? 'tag-admin' : 'tag-client'}`;
    tag.textContent = isAdmin ? 'PCM ADMIN 🛡️' : 'YOU (CLIENT) 👤';

    const txt = document.createElement('div');
    txt.className = 'chat-msg-txt';
    txt.textContent = message;

    const time = document.createElement('div');
    time.className = 'chat-time';
    time.textContent = timeStr;

    bubble.appendChild(tag);
    bubble.appendChild(txt);
    bubble.appendChild(time);
    container.appendChild(bubble);
    container.scrollTop = container.scrollHeight;
  }
};
