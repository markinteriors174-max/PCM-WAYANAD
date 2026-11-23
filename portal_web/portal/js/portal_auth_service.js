/**
 * PCM WAYANAD PORTAL - AUTH & PIN LOGIC SERVICE (< 90 lines)
 */

window.PortalAuthService = {
  isValidPin(enteredPin) {
    const client = window.PortalState?.currentClientFound || window.PortalState?.portalData;
    const clientPin = client?.soft_pin ?? client?.site_pin;
    return clientPin !== undefined && clientPin !== null && String(enteredPin).trim() === String(clientPin).trim();
  },

  async applySuccessfulLogin(enteredPin, verifiedRecord) {
    const client = verifiedRecord || window.PortalState?.currentClientFound || window.PortalState?.portalData;
    const name = client?.client_name || client?.name || 'Valued Client';
    const siteId = client?.site_id || client?.unit_number || client?.id || window.PortalState?.currentSiteId;
    const phone = client?.phone_number || client?.client_phone || client?.phone || '';

    localStorage.setItem('pcm_active_site_pin', String(enteredPin).trim());
    localStorage.setItem('pcm_client_name', name);
    localStorage.setItem('pcm_portal_user', name);
    if (phone) localStorage.setItem('pcm_client_phone', phone);
    if (siteId) localStorage.setItem('pcm_client_site_id', siteId);

    window.PortalAuthModalComponent?.setModalVisibility(false);
    if (siteId && window.PortalState) {
      window.PortalState.currentSiteId = String(siteId).toLowerCase();
      if (window.PortalApp) window.PortalApp.initLoad();
      if (window.PortalChatService) window.PortalChatService.loadChat();
    }

    // Start Realtime Session Watcher if available
    if (typeof window.listenToAdminChanges === 'function' && siteId) {
      window.listenToAdminChanges(siteId);
    }
  },

  async verifyLogin() {
    const pinInput = document.getElementById('loginPinInput');
    const phoneInput = document.getElementById('clientLookupInput');
    const enteredPin = pinInput ? pinInput.value.trim() : '';
    const enteredPhone = phoneInput ? phoneInput.value.trim().replace(/\D/g, '') : '';

    if (enteredPin.length !== 4) {
      alert('ദയവായി നിങ്ങളുടെ 4-അക്ക സോഫ്റ്റ് പിൻ നൽകുക.');
      return;
    }

    // Check if global verifyClientAccess is available from auth.js
    if (typeof window.verifyClientAccess === 'function') {
      const isAllowed = await window.verifyClientAccess(enteredPhone, enteredPin);
      if (isAllowed) {
        await this.applySuccessfulLogin(enteredPin, window.activeVerifiedClientRecord);
        return;
      } else {
        alert('⚠️ പ്രവേശനം നിരസിച്ചു! നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിൻ സിസ്റ്റത്തിൽ കാണാനില്ല അല്ലെങ്കിൽ നീക്കം ചെയ്യപ്പെട്ടു. ദയവായി രജിസ്റ്റർ ചെയ്യുക.\n\nAccess Denied: You are not registered or your account was removed by the administrator. Please register.');
        window.location.replace('index.html?auth=register');
        return;
      }
    }

    // Direct Database Verification
    const client = window.PortalApi?.getClient ? window.PortalApi.getClient() : (window.supabase || null);
    let verified = null;

    if (client) {
      try {
        const phoneQuery = enteredPhone.length >= 10 ? enteredPhone.slice(-10) : '';
        
        // 1. site_folders
        let q1 = client.from('site_folders').select('*').eq('soft_pin', enteredPin);
        if (phoneQuery) q1 = q1.ilike('phone', `%${phoneQuery}%`);
        const { data: sf } = await q1.maybeSingle();
        if (sf && !['revoked', 'deleted', 'inactive', 'blocked'].some(k => (sf.status || '').toLowerCase().includes(k))) {
          verified = sf;
        }

        // 2. site_portals
        if (!verified) {
          let q2 = client.from('site_portals').select('*').eq('site_pin', enteredPin);
          if (phoneQuery) q2 = q2.ilike('client_phone', `%${phoneQuery}%`);
          const { data: sp } = await q2.maybeSingle();
          if (sp && !['revoked', 'deleted', 'inactive', 'blocked'].some(k => (sp.status || '').toLowerCase().includes(k))) {
            verified = sp;
          }
        }

        // 3. website_leads
        if (!verified) {
          let q3 = client.from('website_leads').select('*').eq('soft_pin', enteredPin);
          if (phoneQuery) q3 = q3.ilike('phone_number', `%${phoneQuery}%`);
          const { data: wl } = await q3.maybeSingle();
          if (wl && !['revoked', 'deleted', 'inactive', 'blocked'].some(k => (wl.status || '').toLowerCase().includes(k))) {
            verified = wl;
          }
        }
      } catch (err) {
        console.warn('[PortalAuth] verification query error:', err);
      }
    }

    if (verified) {
      await this.applySuccessfulLogin(enteredPin, verified);
    } else {
      alert('⚠️ പ്രവേശനം നിരസിച്ചു! നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിൻ സിസ്റ്റത്തിൽ കാണാനില്ല അല്ലെങ്കിൽ നീക്കം ചെയ്യപ്പെട്ടു. ദയവായി രജിസ്റ്റർ ചെയ്യുക.\n\nAccess Denied: You are not registered or your account was removed by the administrator. Please register.');
      window.location.replace('index.html?auth=register');
    }
  },

  async saveAndActivateNewPin() {
    const phone = (document.getElementById('newPinPhoneInput')?.value || '').trim().replace(/\D/g, '');
    const newPin = (document.getElementById('newPinCodeInput')?.value || '').trim();
    if (phone.length < 10) return alert('ദയവായി 10-അക്ക ഫോൺ നമ്പർ നൽകുക.');
    if (newPin.length !== 4 || Number.isNaN(Number(newPin))) return alert('ദയവായി 4-അക്ക സോഫ്റ്റ് പിൻ നൽകുക.');

    const phoneQuery = phone.slice(-10);
    const client = window.PortalApi.getClient();
    if (client) {
      try {
        const { data: existing } = await client.from('site_portals').select('*').ilike('client_phone', `%${phoneQuery}%`).maybeSingle();
        if (existing) {
          await client.from('site_portals').update({ site_pin: newPin, updated_at: new Date().toISOString() }).eq('site_id', existing.site_id);
          window.PortalState.currentSiteId = existing.site_id.toLowerCase();
        } else {
          const newSid = `PCM-${phoneQuery.slice(-4)}`;
          await client.from('site_portals').insert([{
            site_id: newSid, client_name: 'Client ' + phoneQuery.slice(-4), client_phone: phone, site_pin: newPin,
            site_location: 'Wayanad, Kerala', status: 'Active', updated_at: new Date().toISOString()
          }]);
          window.PortalState.currentSiteId = newSid.toLowerCase();
        }
      } catch (e) { console.warn('[PortalAuth] PIN update note:', e); }
    }
    const cName = window.PortalState.currentClientFound?.client_name || ('Client ' + phoneQuery.slice(-4));
    localStorage.setItem('pcm_active_site_pin', newPin);
    localStorage.setItem('pcm_client_phone', phone);
    localStorage.setItem('pcm_client_name', cName);
    localStorage.setItem('pcm_portal_user', cName);
    alert(`✅ പുതിയ 4-അക്ക സോഫ്റ്റ് പിൻ (${newPin}) ആക്റ്റീവ് ആക്കി!`);
    window.PortalAuthModalComponent.setModalVisibility(false);
    if (window.PortalApp) window.PortalApp.initLoad();
    if (window.PortalChatService) window.PortalChatService.loadChat();
  },

  checkUserSession() {
    const hasPin = Boolean(localStorage.getItem('pcm_active_site_pin') || localStorage.getItem('pcm_portal_user'));
    const urlParams = new URLSearchParams(window.location.search);
    const allowPreview = urlParams.get('preview') === 'true';
    const mainContent = document.getElementById('mainPortalContent');
    if (!hasPin && !allowPreview) {
      if (mainContent) mainContent.classList.add('hidden');
      if (window.PortalAuthModalComponent) {
        window.PortalAuthModalComponent.setModalVisibility(true);
        window.PortalAuthModalComponent.resetClientLookup();
      }
      window.location.replace('index.html?auth=register');
      return false;
    } else {
      if (mainContent) mainContent.classList.remove('hidden');
      if (window.PortalAuthModalComponent) {
        window.PortalAuthModalComponent.setModalVisibility(false);
      }
      return true;
    }
  },

  _clearSessionData() {
    const keysToRemove = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && (key.startsWith('pcm_') || key.startsWith('sb-') || key.includes('supabase') || key.includes('token'))) {
        keysToRemove.push(key);
      }
    }
    keysToRemove.forEach(k => localStorage.removeItem(k));
    [
      'pcm_active_site_pin', 'pcm_client_phone', 'pcm_client_name',
      'pcm_portal_user', 'pcm_site_id', 'pcm_client_site_id',
      'pcm_active_site', 'supabase.auth.token'
    ].forEach(k => localStorage.removeItem(k));

    try {
      sessionStorage.clear();
    } catch (err) {
      // Non-fatal: ignore storage access restrictions in cross-origin sandboxes
      console.warn('[PortalAuth] sessionStorage clear notice:', err);
    }
  },

  _clearMountedViews() {
    const mainContent = document.getElementById('mainPortalContent');
    if (mainContent) mainContent.classList.add('hidden');

    const mountIds = [
      'ledgerMount', 'financialsMount', 'statementMount', 'pdfMount',
      'progressMount', 'roomsMount', 'galleryMount', 'chatMount',
      'contractMount', 'upiMount', 'overviewMount', 'detailsMount'
    ];
    mountIds.forEach(id => {
      const el = document.getElementById(id);
      if (el) el.innerHTML = '';
    });
  },

  async _signOutSupabase() {
    try {
      const client = window.supabase || (window.getSupabase ? window.getSupabase() : null);
      if (client?.auth?.signOut) {
        await client.auth.signOut();
      }
    } catch (err) {
      // Non-blocking signOut fallback
      console.warn('[PortalAuth] Supabase signOut notice:', err);
    }
  },

  async logout() {
    await this._signOutSupabase();

    this._clearSessionData();

    if (window.PortalState) {
      window.PortalState.portalData = null;
      window.PortalState.currentClientFound = null;
      window.PortalState.currentSiteId = null;
    }

    this._clearMountedViews();

    if (window.PortalAuthModalComponent) {
      window.PortalAuthModalComponent.resetClientLookup();
      window.PortalAuthModalComponent.setModalVisibility(true);
      window.PortalAuthModalComponent.switchTab('register');
    }

    // Strictly redirect to registration screen
    window.location.replace('index.html?auth=register');
  },

  async performForceSignOut() {
    console.warn('[PortalAuth] performForceSignOut triggered: Account deleted or revoked by admin.');
    alert('⚠️ അഡ്മിൻ പാനലിൽ നിന്ന് അക്കൗണ്ട് നീക്കം ചെയ്യപ്പെട്ടു. പ്രവേശനം തടഞ്ഞു. രജിസ്ട്രേഷൻ പേജിലേക്ക് മാറ്റുന്നു.\n\nYour client account was deleted or revoked by administrator. Access blocked.');
    await this.logout();
  }
};

window.verifyLogin = () => window.PortalAuthService.verifyLogin();
window.saveAndActivateNewPin = () => window.PortalAuthService.saveAndActivateNewPin();
window.checkUserSession = () => window.PortalAuthService.checkUserSession();
window.logout = () => window.PortalAuthService.logout();
window.lockPortal = window.logout;
window.handlePortalLogout = window.logout;
if (!window.performForceSignOut) {
  window.performForceSignOut = () => window.PortalAuthService.performForceSignOut();
}
