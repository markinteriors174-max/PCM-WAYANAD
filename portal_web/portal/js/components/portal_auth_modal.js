/**
 * PCM WAYANAD PORTAL - AUTH MODAL COMPONENT (< 95 lines)
 */

window.PortalAuthModalComponent = {
  renderMount() {
    return `
      <div id="websiteAuthModal" class="fixed inset-0 bg-slate-950/95 z-50 flex items-center justify-center p-4">
        <div class="auth-modal-card bg-slate-900/95 border border-slate-800/90 p-6 sm:p-8 rounded-3xl max-w-md w-full shadow-2xl relative z-10 backdrop-blur-xl">
          <div class="text-center mb-5">
            <div class="inline-flex p-3 bg-gradient-to-br from-amber-500/20 to-amber-500/5 border border-amber-500/30 rounded-2xl text-amber-400 mb-2.5 text-xl shadow-lg shadow-amber-500/10">🔐</div>
            <h3 class="text-white font-black text-sm uppercase tracking-wider">PCM WAYANAD PORTAL</h3>
            <p class="text-[11px] text-slate-400 mt-1">ക്ലയന്റ് ലൈവ് പോർട്ടൽ ആക്സസ് / Client Secure Gateway</p>
          </div>
          <div class="flex bg-slate-950/90 p-1.5 rounded-2xl mb-5 border border-slate-800/90 gap-1">
            <button onclick="window.PortalAuthModalComponent.switchTab('login')" id="authLoginTabBtn" class="flex-1 py-2.5 px-2 text-xs font-bold rounded-xl bg-amber-500 text-slate-950 shadow-md transition-all duration-200 cursor-pointer text-center">LOGIN (ലോഗിൻ)</button>
            <button onclick="window.PortalAuthModalComponent.switchTab('newpin')" id="authNewPinTabBtn" class="flex-1 py-2.5 px-2 text-xs font-semibold rounded-xl text-slate-400 hover:text-slate-200 hover:bg-slate-900/60 transition-all duration-200 cursor-pointer text-center">NEW PIN (പിൻ)</button>
          </div>
          <div id="authLoginForm" class="space-y-4">
            <div>
              <label for="loginPhoneInput" class="flex items-center justify-between text-xs mb-1.5 font-medium">
                <span class="text-slate-200 font-bold">Mobile Number</span>
                <span class="text-amber-400/90 text-[11px] font-medium">ഫോൺ നമ്പർ</span>
              </label>
              <input type="tel" id="loginPhoneInput" placeholder="10-digit registered mobile number" maxlength="10" inputmode="numeric" oninput="window.lookupClient(this.value)" class="w-full bg-slate-950/80 border border-slate-700/80 text-white placeholder-slate-500 px-4 py-3 rounded-xl focus:border-amber-500 focus:ring-1 focus:ring-amber-500/40 focus:outline-none text-sm transition shadow-inner leading-normal">
            </div>
            <div id="clientInfoPreview" class="hidden p-3.5 bg-slate-950/90 border border-amber-500/40 rounded-xl space-y-1 shadow-md">
              <div class="flex items-center justify-between">
                <p class="text-[10px] text-amber-400 uppercase tracking-widest font-extrabold flex items-center gap-1.5">
                  <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                  Client Found
                </p>
                <span class="text-[10px] text-slate-400">തിരിച്ചറിഞ്ഞു</span>
              </div>
              <p id="previewClientName" class="text-sm text-white font-bold"></p>
              <p id="previewClientLocation" class="text-xs text-slate-300"></p>
            </div>
            <div>
              <label for="loginPinInput" class="flex items-center justify-between text-xs mb-1.5 font-medium">
                <span class="text-slate-200 font-bold">4-Digit Soft PIN <span class="text-amber-400">*</span></span>
                <span class="text-amber-400/90 text-[11px] font-medium">സോഫ്റ്റ് പിൻ</span>
              </label>
              <input type="password" id="loginPinInput" placeholder="••••" maxlength="4" inputmode="numeric" disabled class="w-full bg-slate-950/80 border border-slate-700/80 text-amber-400 placeholder-slate-600 px-4 py-3 rounded-xl focus:border-amber-500 focus:ring-1 focus:ring-amber-500/40 focus:outline-none text-sm tracking-widest font-black disabled:opacity-40 transition shadow-inner">
            </div>
            <button onclick="window.verifyLogin()" id="loginSubmitBtn" disabled class="w-full bg-amber-500/50 text-slate-950 font-black py-3.5 px-4 rounded-xl transition-all duration-200 text-xs sm:text-sm shadow-lg disabled:cursor-not-allowed flex items-center justify-center gap-2">
              <span>ENTER PORTAL</span>
              <span class="text-xs opacity-90">(പോർട്ടലിൽ പ്രവേശിക്കുക)</span>
              <span>🔓</span>
            </button>
          </div>
          <div id="authNewPinForm" class="space-y-4 hidden">
            <div class="text-[11px] text-amber-300/90 bg-amber-500/10 border border-amber-500/20 p-3 rounded-xl flex items-start gap-2.5">
              <span class="text-sm">💡</span>
              <div>
                <p class="font-semibold text-amber-300">Set New PIN / പുതിയ പിൻ സെറ്റ് ചെയ്യാം</p>
                <p class="text-slate-400 text-[10px] mt-0.5">നിങ്ങളുടെ രജിസ്റ്റർ ചെയ്ത മൊബൈൽ നമ്പർ നൽകി പുതിയ 4 അക്ക സോഫ്റ്റ് പിൻ സെറ്റ് ചെയ്യാം.</p>
              </div>
            </div>
            <div>
              <label for="newPinPhoneInput" class="flex items-center justify-between text-xs mb-1.5 font-medium">
                <span class="text-slate-200 font-bold">Registered Mobile</span>
                <span class="text-amber-400/90 text-[11px] font-medium">രജിസ്റ്റർ ചെയ്ത നമ്പർ</span>
              </label>
              <input type="tel" id="newPinPhoneInput" placeholder="10-digit registered mobile number" maxlength="10" inputmode="numeric" class="w-full bg-slate-950/80 border border-slate-700/80 text-white placeholder-slate-500 px-4 py-3 rounded-xl focus:border-amber-500 focus:ring-1 focus:ring-amber-500/40 focus:outline-none text-sm transition shadow-inner leading-normal">
            </div>
            <div>
              <label for="newPinCodeInput" class="flex items-center justify-between text-xs mb-1.5 font-medium">
                <span class="text-slate-200 font-bold">Create 4-Digit PIN <span class="text-amber-400">*</span></span>
                <span class="text-amber-400/90 text-[11px] font-medium">പുതിയ 4 അക്ക പിൻ</span>
              </label>
              <input type="password" id="newPinCodeInput" placeholder="••••" maxlength="4" inputmode="numeric" class="w-full bg-slate-950/80 border border-slate-700/80 text-amber-400 placeholder-slate-600 px-4 py-3 rounded-xl focus:border-amber-500 focus:ring-1 focus:ring-amber-500/40 focus:outline-none text-sm tracking-widest font-black transition shadow-inner">
            </div>
            <button onclick="window.saveAndActivateNewPin()" class="w-full bg-gradient-to-r from-amber-500 to-amber-400 hover:from-amber-400 hover:to-amber-300 text-slate-950 font-black py-3.5 px-4 rounded-xl transition-all duration-200 text-xs sm:text-sm shadow-lg shadow-amber-500/20 cursor-pointer flex items-center justify-center gap-2">
              <span>SAVE PIN & LOGIN</span>
              <span class="text-xs opacity-90">(പിൻ സേവ് ചെയ്തു ലോഗിൻ ചെയ്യുക)</span>
              <span>🚀</span>
            </button>
          </div>
        </div>
      </div>
    `;
  },

  postMount() {
    const pin = document.getElementById('newPinCodeInput');
    if (pin) pin.onkeydown = (e) => { if (e.key === 'Enter') window.saveAndActivateNewPin(); };
  },

  setModalVisibility(show) {
    const m = document.getElementById('websiteAuthModal');
    const p = document.getElementById('mainPortalContent');
    if (m) m.classList.toggle('hidden', !show);
    if (p) p.classList.toggle('hidden', show);
  },

  switchTab(tab) {
    const isLogin = tab === 'login';
    document.getElementById('authLoginTabBtn')?.classList.toggle('bg-amber-500', isLogin);
    document.getElementById('authLoginTabBtn')?.classList.toggle('text-slate-950', isLogin);
    document.getElementById('authNewPinTabBtn')?.classList.toggle('bg-amber-500', !isLogin);
    document.getElementById('authNewPinTabBtn')?.classList.toggle('text-slate-950', !isLogin);
    document.getElementById('authLoginForm')?.classList.toggle('hidden', !isLogin);
    document.getElementById('authNewPinForm')?.classList.toggle('hidden', isLogin);
  },

  resetClientLookup() {
    document.getElementById('clientInfoPreview')?.classList.add('hidden');
    const pin = document.getElementById('loginPinInput');
    const btn = document.getElementById('loginSubmitBtn');
    if (pin) { pin.disabled = true; pin.value = ''; }
    if (btn) { btn.disabled = true; btn.className = 'w-full bg-amber-500/50 text-slate-950 font-black py-3.5 rounded-xl transition text-xs shadow-lg disabled:cursor-not-allowed'; }
    window.PortalState.currentClientFound = null;
  }
};

window.switchAuthTab = (t) => window.PortalAuthModalComponent.switchTab(t);
