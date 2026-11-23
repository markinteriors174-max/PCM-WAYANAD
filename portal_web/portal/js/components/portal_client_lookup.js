/**
 * PCM WAYANAD PORTAL - CLIENT LOOKUP HANDLER (< 80 lines)
 */

window.PortalClientLookup = {
  showFound(client) {
    window.PortalState.currentClientFound = client;
    const preview = document.getElementById('clientInfoPreview');
    const nameEl = document.getElementById('previewClientName');
    const locEl = document.getElementById('previewClientLocation');
    const pin = document.getElementById('loginPinInput');
    const btn = document.getElementById('loginSubmitBtn');

    if (preview) preview.classList.remove('hidden');
    if (nameEl) nameEl.textContent = client.client_name || 'Valued Client';
    if (locEl) locEl.textContent = '📍 ' + (client.location || client.site_location || 'Wayanad, Kerala');
    if (!pin) return;
    pin.disabled = false;
    pin.focus();

    pin.oninput = () => {
      const ok = pin.value.trim().length === 4;
      if (btn) {
        btn.disabled = !ok;
        btn.className = ok
          ? 'w-full bg-amber-500 hover:bg-amber-400 cursor-pointer text-slate-950 font-black py-3.5 rounded-xl transition text-xs shadow-lg'
          : 'w-full bg-amber-500/50 text-slate-950 font-black py-3.5 rounded-xl transition text-xs shadow-lg disabled:cursor-not-allowed';
      }
    };
    pin.onkeydown = (e) => {
      if (e.key === 'Enter' && pin.value.trim().length === 4) window.verifyLogin();
    };
  },

  showNotFound() {
    window.PortalState.currentClientFound = null;
    const preview = document.getElementById('clientInfoPreview');
    const nameEl = document.getElementById('previewClientName');
    const locEl = document.getElementById('previewClientLocation');
    const pin = document.getElementById('loginPinInput');
    const btn = document.getElementById('loginSubmitBtn');

    if (preview) {
      preview.classList.remove('hidden');
      if (nameEl) nameEl.textContent = 'നമ്പർ കണ്ടെത്തിയില്ല / Not Found';
      if (locEl) locEl.textContent = '💡 പുതിയ പിൻ സെറ്റ് ചെയ്യാൻ മുകളിലെ "NEW PIN" ടാബ് ഉപയോഗിക്കുക.';
    }
    if (pin) { pin.disabled = true; pin.value = ''; }
    if (btn) {
      btn.disabled = true;
      btn.className = 'w-full bg-amber-500/50 text-slate-950 font-black py-3.5 rounded-xl transition text-xs shadow-lg disabled:cursor-not-allowed';
    }
  },

  async lookup(phoneVal) {
    const clean = (phoneVal || '').replace(/\D/g, '');
    if (clean.length < 10) {
      window.PortalAuthModalComponent.resetClientLookup();
      return;
    }
    const q = clean.slice(-10);
    const client = (await window.PortalApi.fetchClientFromSupabase(clean, q)) || window.PortalApi.findClientLocally(q);
    if (client) this.showFound(client);
    else this.showNotFound();
  }
};

window.lookupClient = (p) => window.PortalClientLookup.lookup(p);
window.lookupClientByPhone = window.lookupClient;
