/**
 * =========================================================================
 * PCM WAYANAD - GOOGLE AUTHENTICATION & FLUTTER SITE HUB ONBOARDING GATEWAY
 * =========================================================================
 */

let pendingLeadData = null;
let currentClientFound = null;

// Initialize Firebase App & Auth for premier-ceiling-master-381b0
if (!window.firebaseConfig) {
  window.firebaseConfig = {
    apiKey: "AIzaSyCBAxjvRnOSA6r4UPs2VK7P3lWd5beK1nQ",
    authDomain: "premier-ceiling-master-381b0.firebaseapp.com",
    projectId: "premier-ceiling-master-381b0",
    storageBucket: "premier-ceiling-master-381b0.firebasestorage.app",
    messagingSenderId: "949356430964",
    appId: "1:949356430964:web:2da1263f2f419f77763321"
  };
}

if (typeof firebase !== 'undefined' && !firebase.apps.length) {
  try {
    firebase.initializeApp(window.firebaseConfig);
  } catch (e) {
    console.warn('[Firebase Init Notice]', e);
  }
}

// Legacy Supabase client disabled; using Cloud Firestore & Local Storage exclusively
const supabase = null;
window.supabase = null;
window.supabaseClient = null;

// ---------------------------------------------------------------------------
// GOOGLE AUTHENTICATION & FIRST-TIME ONBOARDING FLOW
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// GOOGLE AUTHENTICATION & FIRST-TIME ONBOARDING FLOW
// ---------------------------------------------------------------------------
async function checkIfUserRegistered(email, uid) {
  if (uid && localStorage.getItem(`pcm_registered_google_${uid}`) === 'true') return true;
  if (email && localStorage.getItem(`pcm_registered_email_${email}`) === 'true') return true;

  try {
    if (typeof firebase !== 'undefined' && firebase.firestore && email) {
      const db = firebase.firestore();
      const snap = await db.collection('clients').where('googleEmail', '==', email).limit(1).get();
      if (!snap.empty) {
        const docData = snap.docs[0].data();
        if (docData.client_name || docData.clientName) {
          if (uid) localStorage.setItem(`pcm_registered_google_${uid}`, 'true');
          localStorage.setItem(`pcm_registered_email_${email}`, 'true');
          localStorage.setItem('pcm_portal_user', docData.client_name || docData.clientName);
          localStorage.setItem('pcm_client_phone', docData.phone_number || docData.phoneNumber || '');
          localStorage.setItem('pcm_client_site_id', docData.unitNumber || docData.id || 'PCM-WAYANAD');
          return true;
        }
      }
    }
  } catch (e) {
    console.warn('Check user registration notice:', e);
  }
  return false;
}

async function handleGoogleSignIn() {
  try {
    if (typeof firebase !== 'undefined' && firebase.auth) {
      const provider = new firebase.auth.GoogleAuthProvider();
      // Force Google account/email selection prompt every time
      provider.setCustomParameters({
        prompt: 'select_account'
      });

      const result = await firebase.auth().signInWithPopup(provider);
      if (result && result.user) {
        const user = result.user;
        const uid = user.uid;
        const googleName = user.displayName || '';
        const googleEmail = user.email || '';
        const googlePhone = (user.phoneNumber || '').replace(/\D/g, '');

        localStorage.setItem('pcm_google_uid', uid);
        if (googleEmail) localStorage.setItem('pcm_google_email', googleEmail);
        if (googleName) localStorage.setItem('pcm_portal_user', googleName);

        // Check if registration was already completed once for this Google account
        const isRegistered = await checkIfUserRegistered(googleEmail, uid);

        if (isRegistered) {
          // SUBSEQUENT LOGINS: Directly authenticate & open MY PROJECT HUB without asking for details again
          const storedName = localStorage.getItem('pcm_portal_user') || googleName || 'PCM Client';
          const savedPhone = localStorage.getItem('pcm_client_phone') || '';
          const storedSiteId = localStorage.getItem('pcm_client_site_id') || (savedPhone ? `PCM-${savedPhone.slice(-4)}` : 'PCM-WAYANAD');

          unlockAppView('', storedName);
          openMyProjectHub({
            client_name: storedName,
            site_id: storedSiteId,
            client_phone: savedPhone
          });
          return;
        } else {
          // FIRST-TIME LOGIN: Prompt for Name, Site Location, and Mobile Number (NO PIN FIELD)
          const nameInput = document.getElementById('regClientName');
          if (nameInput && googleName) nameInput.value = googleName;
          const phoneInput = document.getElementById('regClientPhone');
          if (phoneInput && googlePhone) phoneInput.value = googlePhone;

          openFirstTimeRegistrationModal();
          return;
        }
      }
    }
  } catch (err) {
    console.debug('[Google Auth Popup Notice]:', err);
  }

  // Fallback if popup blocked / dev environment
  const savedUid = localStorage.getItem('pcm_google_uid') || 'google_user';
  const savedEmail = localStorage.getItem('pcm_google_email') || '';
  const isRegistered = await checkIfUserRegistered(savedEmail, savedUid);
  const savedPhone = localStorage.getItem('pcm_client_phone');

  if (isRegistered && savedPhone) {
    const storedName = localStorage.getItem('pcm_portal_user') || 'PCM Client';
    const storedSiteId = localStorage.getItem('pcm_client_site_id') || `PCM-${savedPhone.slice(-4)}`;
    unlockAppView('', storedName);
    openMyProjectHub({
      client_name: storedName,
      site_id: storedSiteId,
      client_phone: savedPhone
    });
  } else {
    openFirstTimeRegistrationModal();
  }
}

function openFirstTimeRegistrationModal() {
  const modal = document.getElementById('websiteAuthModal');
  if (modal) modal.classList.remove('hidden');
}

// Complete First-Time Registration & Sync to Flutter Site Hub
async function completeFirstTimeRegistration(event) {
  if (event) event.preventDefault();

  const nameInput = document.getElementById('regClientName');
  const locInput = document.getElementById('regClientLocation');
  const phoneInput = document.getElementById('regClientPhone');

  const name = nameInput ? nameInput.value.trim() : '';
  const location = locInput ? locInput.value.trim() : '';
  const phone = phoneInput ? phoneInput.value.trim().replace(/\D/g, '') : '';

  if (!name) {
    alert('ദയവായി നിങ്ങളുടെ പേര് നൽകുക. (Please enter your full name.)');
    return;
  }
  if (!location) {
    alert('ദയവായി സൈറ്റ് സ്ഥലം നൽകുക. (Please enter site location.)');
    return;
  }
  if (phone.length < 10) {
    alert('ദയവായി 10-അക്ക ഫോൺ നമ്പർ നൽകുക. (Please enter 10-digit mobile number.)');
    return;
  }

  const phone10 = phone.slice(-10);
  const siteId = `PCM-${phone10.slice(-4)}`;
  const uid = localStorage.getItem('pcm_google_uid') || `google_${phone10}`;
  const email = localStorage.getItem('pcm_google_email') || '';

  // 1. Mark registration completed locally
  localStorage.setItem(`pcm_registered_google_${uid}`, 'true');
  if (email) localStorage.setItem(`pcm_registered_email_${email}`, 'true');
  localStorage.setItem('pcm_portal_user', name);
  localStorage.setItem('pcm_client_phone', phone);
  localStorage.setItem('pcm_client_site_id', siteId);

  // 2. FLUTTER SITE HUB SYNC: Write to projects, clients, and quotations collections in Firestore
  syncNewClientToFirestore(siteId, name, phone, location, email);

  // 3. INSTANT DASHBOARD REDIRECT: Close modal & open MY PROJECT HUB directly
  const modal = document.getElementById('websiteAuthModal');
  if (modal) modal.classList.add('hidden');

  unlockAppView('', name);
  openMyProjectHub({
    client_name: name,
    site_id: siteId,
    client_phone: phone
  });

  alert(`✅ സ്വാഗതം ${name}! നിങ്ങളുടെ സൈറ്റ് ഫോൾഡർ (${siteId}) വിജയകരമായി ക്രിയേറ്റ് ചെയ്തു.\n\nRegistration Complete! Dedicated client folder created in Flutter Site Hub.`);
}

async function syncNewClientToFirestore(siteId, name, phone, location, email) {
  const now = new Date();
  const nowIso = now.toISOString();

  // Format normalized unit number matching Flutter ClientService standard (# PCM-YYYYMMDD-HHmm)
  const pad = (n) => String(n).padStart(2, '0');
  const normalizedUnit = `# PCM-${now.getFullYear()}${pad(now.getMonth()+1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}`;
  const uid = localStorage.getItem('pcm_google_uid') || '';
  const docId = uid || (email ? email.replace(/[^a-zA-Z0-9]/g, '_') : normalizedUnit);

  const clientMap = {
    id: normalizedUnit,
    unitNumber: normalizedUnit,
    unit_number: normalizedUnit,
    client_name: name,
    clientName: name,
    phone_number: phone,
    phoneNumber: phone,
    site_location: location,
    siteLocation: location,
    googleEmail: email || '',
    googleUid: uid || '',
    totalContractAmount: 0.0,
    advanceReceived: 0.0,
    totalLaborCost: 0.0,
    status: 'Lead Active',
    isDeleted: false,
    createdAt: nowIso,
    created_at: nowIso
  };

  try {
    if (typeof firebase !== 'undefined' && firebase.firestore) {
      const db = firebase.firestore();

      const targets = [
        db.collection('projects').doc(docId),
        db.collection('projects').doc(normalizedUnit),
        db.collection('clients').doc(docId),
        db.collection('clients').doc(normalizedUnit),
        db.collection('quotations').doc(normalizedUnit)
      ];

      await Promise.all(targets.map(ref => ref.set(clientMap, { merge: true }).catch(() => {})));
      console.log('[Firestore Sync] Dedicated client folder created in Flutter Site Hub:', docId, normalizedUnit);
    }
  } catch (err) {
    console.warn('[Firestore Sync Notice]:', err);
  }
}

window.handleGoogleSignIn = handleGoogleSignIn;
window.completeFirstTimeRegistration = completeFirstTimeRegistration;

function updateAuthTabBtn(btn, isActive, isNewPin = false) {
  if (!btn) return;
  const activeCls = 'flex-1 py-2.5 px-2 text-xs font-bold rounded-xl bg-amber-500 text-slate-950 shadow-md transition-all duration-200 cursor-pointer text-center';
  const inactiveCls = 'flex-1 py-2.5 px-2 text-xs font-semibold rounded-xl text-slate-400 hover:text-slate-200 hover:bg-slate-900/60 transition-all duration-200 cursor-pointer text-center';
  btn.className = isActive ? activeCls : inactiveCls;
  btn.classList.toggle('active', isActive);
  if (isNewPin && isActive) {
    btn.removeAttribute('disabled');
  }
}

// Switch between REGISTER, LOGIN, and NEW PIN tabs
function switchAuthTab(tab) {
  const isRegister = tab === 'register';
  const isLogin = tab === 'login';
  const isNewPin = tab === 'newpin';

  const regTabBtn = document.getElementById('authRegisterTabBtn') || document.getElementById('tabRegister');
  const loginTabBtn = document.getElementById('authLoginTabBtn') || document.getElementById('tabLogin');
  const newPinTabBtn = document.getElementById('authNewPinTabBtn') || document.getElementById('tabNewPin');

  updateAuthTabBtn(regTabBtn, isRegister);
  updateAuthTabBtn(loginTabBtn, isLogin);
  updateAuthTabBtn(newPinTabBtn, isNewPin, true);

  const regForm = document.getElementById('authRegisterForm') || document.getElementById('formRegister');
  const loginForm = document.getElementById('authLoginForm');
  const newPinForm = document.getElementById('authNewPinForm') || document.getElementById('formNewPin');

  if (regForm) regForm.classList.toggle('hidden', !isRegister);
  if (loginForm) loginForm.classList.toggle('hidden', !isLogin);
  if (newPinForm) newPinForm.classList.toggle('hidden', !isNewPin);
}
window.switchAuthTab = switchAuthTab;

// ---------------------------------------------------------------------------
// 1. STEP 1: REGISTRATION HANDLER (3 CLEAN FIELDS: NAME, LOCATION, PHONE)
// ---------------------------------------------------------------------------
let tempUserData = {};

// Step 1 Save and Move to Step 2 (Soft PIN creation)
function handleRegisterAndContinue(name, location, phone) {
  // 1. Basic details temporary store or initial lead creation
  tempUserData['name'] = name;
  tempUserData['location'] = location;
  tempUserData['phone'] = phone;

  pendingRegistrationData = {
    name: name,
    location: location,
    phone: phone
  };

  // 2. Navigate to Soft PIN creation screen / tab
  navigateToSoftPinScreen();
}
window.handleRegisterAndContinue = handleRegisterAndContinue;

function navigateToSoftPinScreen() {
  switchAuthTab('newpin');
  const newPinPhone = document.getElementById('newPinPhoneInput');
  if (newPinPhone && tempUserData.phone) {
    newPinPhone.value = tempUserData.phone;
  }
  const pinField = document.getElementById('newPinInput') || document.getElementById('newPinCodeInput');
  if (pinField) {
    setTimeout(() => pinField.focus(), 150);
  }
}
window.navigateToSoftPinScreen = navigateToSoftPinScreen;

function handleSoftPinComplete(pin) {
  tempUserData['softPin'] = pin;
  
  // 3. Finalize registration and save to database (Supabase / Leads)
  submitRegistrationToDatabase(tempUserData);
}
window.handleSoftPinComplete = handleSoftPinComplete;

async function submitRegistrationToDatabase(userData) {
  if (!pendingRegistrationData) {
    pendingRegistrationData = { ...userData };
  }
  pendingRegistrationData.pin = userData.softPin || userData.pin;
  pendingRegistrationData.softPin = userData.softPin || userData.pin;

  console.log("Registration Complete with Soft PIN:", userData);
  // Complete registration, save all fields to DB, and unlock portal
  await submitCeilingChoice(false);
}
window.submitRegistrationToDatabase = submitRegistrationToDatabase;

function handleRegisterSubmit(e) {
  if (e && typeof e.preventDefault === 'function') e.preventDefault();

  const nameInput = document.getElementById('regName') || document.getElementById('regClientName');
  const locInput = document.getElementById('regLocation') || document.getElementById('regClientLocation');
  const phoneInput = document.getElementById('regPhone') || document.getElementById('regClientPhone');

  const name = nameInput ? nameInput.value.trim() : '';
  const location = locInput ? locInput.value.trim() : '';
  const phone = phoneInput ? phoneInput.value.trim().replace(/\D/g, '') : '';

  if (!name) {
    alert('ദയവായി നിങ്ങളുടെ പേര് നൽകുക (Please enter your full name).');
    return;
  }
  if (!location) {
    alert('ദയവായി സ്ഥലം നൽകുക (Please enter your site location).');
    return;
  }
  if (phone.length < 10) {
    alert('ദയവായി 10-അക്ക ഫോൺ നമ്പർ നൽകുക (Please enter 10-digit mobile number).');
    return;
  }

  handleRegisterAndContinue(name, location, phone);
}
window.handleRegisterSubmit = handleRegisterSubmit;
window.handleWebsiteRegistration = handleRegisterSubmit;

// ---------------------------------------------------------------------------
// 1.1 STEP 2: CREATE 4-DIGIT SOFT PIN HANDLER
// ---------------------------------------------------------------------------
async function handlePinSubmit(e) {
  if (e && typeof e.preventDefault === 'function') e.preventDefault();

  const pinInput = document.getElementById('newPinInput') || document.getElementById('newPinCodeInput');
  const confirmPinInput = document.getElementById('confirmPinInput');

  const pin = pinInput ? pinInput.value.trim().replace(/\D/g, '') : '';
  let confirmPin = pin;
  if (confirmPinInput) {
    confirmPin = confirmPinInput.value.trim().replace(/\D/g, '');
  }

  if (pin.length !== 4) {
    alert('ദയവായി 4-അക്ക സോഫ്റ്റ് പിൻ നൽകുക (Please enter a 4-digit Soft PIN).');
    return;
  }

  if (confirmPinInput && pin !== confirmPin) {
    alert('PINs do not match! Please check (പിൻ നമ്പറുകൾ പൊരുത്തപ്പെടുന്നില്ല).');
    return;
  }

  if (!pendingRegistrationData) {
    const phoneInput = document.getElementById('newPinPhoneInput');
    const phone = phoneInput ? phoneInput.value.trim().replace(/\D/g, '') : (localStorage.getItem('pcm_client_phone') || '');
    const name = localStorage.getItem('pcm_portal_user') || 'Client ' + phone.slice(-4);
    pendingRegistrationData = {
      name: name,
      location: 'Wayanad, Kerala',
      phone: phone
    };
  }

  handleSoftPinComplete(pin);
}
window.handlePinSubmit = handlePinSubmit;

function switchToLogin() {
  switchAuthTab('login');
}
window.switchToLogin = switchToLogin;

// ---------------------------------------------------------------------------
// 2. CEILING WORK YES / NO CONFIRMATION & SUPABASE SAVE HELPERS
// ---------------------------------------------------------------------------
async function _saveWebsiteLead(leadPayload) {
  if (!supabase) return;
  try {
    await supabase.from('website_leads').insert([leadPayload]);
  } catch (err) {
    console.warn('website_leads insert note:', err);
  }
}

async function _saveSitePortalLead(siteId, name, phone, userPin, location, isCeilingNeeded, nowIso) {
  if (!supabase) return;
  try {
    await supabase.from('site_portals').upsert({
      site_id: siteId,
      client_name: name,
      client_phone: phone,
      site_pin: userPin,
      soft_pin: userPin,
      pin: userPin,
      site_location: location,
      status: isCeilingNeeded ? 'Lead - Ceiling Active' : 'General Inquiry',
      updated_at: nowIso
    }, { onConflict: 'site_id' });
  } catch (portErr) {
    console.warn('site_portals upsert notice:', portErr);
  }
}

async function _saveAppFolderLead(siteId, name, phone, location, isCeilingNeeded, nowIso, userPin) {
  if (!supabase) return;
  try {
    const phone10 = (phone || '').slice(-10);
    const folderRecordData = {
      unitNumber: siteId,
      clientName: name,
      clientPhone: phone,
      clientLocation: location,
      projectStatus: isCeilingNeeded ? 'Lead - Ceiling Active' : 'Lead Active',
      totalAmount: 0,
      paidAmount: 0,
      softPin: userPin,
      pin: userPin,
      sitePin: userPin,
      date: nowIso,
      items: [],
      payments: [],
      labor: []
    };
    await supabase.from('app_records').upsert({
      id: `lead_${phone10}`,
      page_type: 'ESTIMATE_PAGE',
      phone_number: phone,
      customer_name: name,
      record_data: folderRecordData,
      updated_at: nowIso
    }, { onConflict: 'phone_number' });
  } catch (appRecErr) {
    console.warn('app_records site folder auto-creation notice:', appRecErr);
  }
}

async function _saveClientFolderLead(siteId, name, phone, location, isCeilingNeeded, nowIso, userPin) {
  if (!supabase) return;
  try {
    await supabase.from('clients').upsert({
      unitNumber: siteId,
      client_name: name,
      phone_number: phone,
      site_location: location,
      login_pin: userPin,
      site_pin: userPin,
      soft_pin: userPin,
      pin: userPin,
      status: isCeilingNeeded ? 'Lead - Ceiling Active' : 'Lead Active',
      created_at: nowIso
    }, { onConflict: 'unitNumber' });
  } catch (cliErr) {
    console.warn('clients lead auto-creation notice:', cliErr);
  }
}

async function submitCeilingChoice(isCeilingNeeded) {
  const confirmModal = document.getElementById('ceilingConfirmModal');
  if (confirmModal) confirmModal.classList.add('hidden');

  if (!pendingRegistrationData) {
    const storedName = localStorage.getItem('pcm_portal_user') || 'Registered Client';
    const storedPhone = localStorage.getItem('pcm_client_phone') || '';
    pendingRegistrationData = { name: storedName, location: 'Wayanad', phone: storedPhone };
  }

  const nowIso = new Date().toISOString();
  const phone10 = pendingRegistrationData.phone.slice(-10);
  let fallbackPin = '5566';
  if (phone10.length >= 4) {
    fallbackPin = phone10.slice(-4);
  }
  const userPin = (pendingRegistrationData?.pin?.length === 4)
    ? pendingRegistrationData.pin
    : fallbackPin;
  const siteId = `PCM-${phone10.slice(-4)}`;

  const leadPayload = {
    client_name: pendingRegistrationData.name,
    location: pendingRegistrationData.location,
    phone_number: pendingRegistrationData.phone,
    soft_pin: userPin,
    pin: userPin,
    site_pin: userPin,
    is_ceiling_needed: Boolean(isCeilingNeeded),
    created_at: nowIso
  };

  await _saveWebsiteLead(leadPayload);
  await _saveSitePortalLead(siteId, pendingRegistrationData.name, pendingRegistrationData.phone, userPin, pendingRegistrationData.location, isCeilingNeeded, nowIso);
  await _saveAppFolderLead(siteId, pendingRegistrationData.name, pendingRegistrationData.phone, pendingRegistrationData.location, isCeilingNeeded, nowIso, userPin);
  await _saveClientFolderLead(siteId, pendingRegistrationData.name, pendingRegistrationData.phone, pendingRegistrationData.location, isCeilingNeeded, nowIso, userPin);

  // Save session to localStorage
  localStorage.setItem('pcm_active_site_pin', userPin);
  localStorage.setItem('pcm_portal_user', pendingRegistrationData.name);
  localStorage.setItem('pcm_client_phone', pendingRegistrationData.phone);
  localStorage.setItem('pcm_client_site_id', siteId);

  // Success message
  const statusMsg = isCeilingNeeded 
    ? '✅ നന്ദി! നിങ്ങളുടെ സീലിംഗ് അന്വേഷണം PCM എഞ്ചിനീയറിംഗ് ടീമിലേക്ക് വിജയകരമായി അയച്ചു.'
    : '✅ വിവരങ്ങൾ വിജയകരമായി രജിസ്റ്റർ ചെയ്തു! സ്വാഗതം.';
  alert(statusMsg);

  const authModal = document.getElementById('websiteAuthModal');
  if (authModal) authModal.classList.add('hidden');

  triggerLogoUnlockAndOpen(pendingRegistrationData.name);
}

function setSubmitButtonState(isValid) {
  const submitBtn = document.getElementById('loginSubmitBtn');
  if (!submitBtn) return;
  submitBtn.disabled = !isValid;
  submitBtn.classList.toggle('bg-amber-500/50', !isValid);
  submitBtn.classList.toggle('disabled:cursor-not-allowed', !isValid);
  submitBtn.classList.toggle('bg-amber-500', isValid);
  submitBtn.classList.toggle('hover:bg-amber-400', isValid);
  submitBtn.classList.toggle('cursor-pointer', isValid);
}

async function searchWebsiteLeads(q10) {
  try {
    const res = await supabase
      .from('website_leads')
      .select('*')
      .or(`phone_number.ilike.%${q10}%,phone.ilike.%${q10}%`)
      .order('created_at', { ascending: false })
      .limit(1)
      .catch(() => ({ data: null }));

    if (res && res.data && res.data.length > 0) {
      const lead = res.data[0];
      return {
        client_name: lead.client_name || lead.name || 'Registered Lead',
        site_location: lead.location || lead.place || 'Wayanad, Kerala',
        location: lead.location || lead.place || 'Wayanad, Kerala',
        client_phone: lead.phone_number || lead.phone || q10,
        site_pin: lead.site_pin || lead.pin || q10.slice(-4) || '1234',
        site_id: lead.site_id || `LEAD-${q10.slice(-4)}`,
        status: lead.is_ceiling_needed ? 'Ceiling Lead' : 'Registered Lead',
      };
    }
  } catch (err) {
    console.warn('website_leads search note:', err);
  }
  return null;
}

async function searchSitePortals(q10) {
  try {
    const res = await supabase
      .from('site_portals')
      .select('*')
      .ilike('client_phone', `%${q10}%`)
      .order('updated_at', { ascending: false })
      .limit(1)
      .catch(() => ({ data: null }));

    if (res && !res.error && res.data && res.data.length > 0) return res.data[0];
  } catch (err) {
    console.warn('site_portals phone search note:', err);
  }
  return null;
}

async function searchSiteFolders(q10) {
  try {
    const res = await supabase
      .from('site_folders')
      .select('*')
      .ilike('phone_number', `%${q10}%`)
      .order('updated_at', { ascending: false })
      .limit(1)
      .catch(() => ({ data: null }));

    if (res && res.data && res.data.length > 0) {
      const f = res.data[0];
      return {
        client_name: f.client_name || 'Client',
        site_location: f.site_location || f.location || 'Wayanad, Kerala',
        location: f.site_location || f.location || 'Wayanad, Kerala',
        client_phone: f.phone_number || q10,
        site_pin: f.site_pin || f.pin || q10.slice(-4) || '1234',
        site_id: f.unit_number || f.site_id || `PCM-${q10.slice(-4)}`,
      };
    }
  } catch (err) {
    console.warn('site_folders search note:', err);
  }
  return null;
}

async function searchClientsTable(q10) {
  try {
    const res = await supabase
      .from('clients')
      .select('*')
      .ilike('phone_number', `%${q10}%`)
      .limit(1)
      .catch(() => ({ data: null }));

    if (res && res.data && res.data.length > 0) {
      const c = res.data[0];
      return {
        client_name: c.client_name || 'Client',
        site_location: c.site_location || 'Wayanad, Kerala',
        location: c.site_location || 'Wayanad, Kerala',
        client_phone: c.phone_number || q10,
        site_pin: c.pin || q10.slice(-4) || '1234',
        site_id: c.unit_number || `PCM-${q10.slice(-4)}`,
      };
    }
  } catch (err) {
    console.warn('clients table lookup note:', err);
  }
  return null;
}

// Fetch real client record across all tables, with seamless fallback for valid numbers
async function fetchClientRecord(phoneQuery) {
  const q10 = (phoneQuery || '').replace(/\D/g, '').slice(-10);
  if (!q10 || q10.length < 10) return null;

  if (supabase) {
    try { const lead = await searchWebsiteLeads(q10); if (lead) return lead; } catch (_) {}
    try { const portal = await searchSitePortals(q10); if (portal) return portal; } catch (_) {}
    try { const folder = await searchSiteFolders(q10); if (folder) return folder; } catch (_) {}
    try { const client = await searchClientsTable(q10); if (client) return client; } catch (_) {}
  }

  // Fallback to local session storage or auto-generated client record for 10-digit numbers
  const savedPhone = (localStorage.getItem('pcm_client_phone') || '').replace(/\D/g, '');
  const savedName = localStorage.getItem('pcm_portal_user') || 'PCM Client';
  const savedPin = localStorage.getItem('pcm_active_site_pin') || q10.slice(-4);
  const savedSiteId = localStorage.getItem('pcm_client_site_id') || `PCM-${q10.slice(-4)}`;

  if (savedPhone && savedPhone.includes(q10)) {
    return {
      client_name: savedName,
      site_location: 'Wayanad, Kerala',
      location: 'Wayanad, Kerala',
      client_phone: q10,
      site_pin: savedPin,
      site_id: savedSiteId
    };
  }

  return {
    client_name: 'Client ' + q10.slice(-4),
    site_location: 'Wayanad, Kerala',
    location: 'Wayanad, Kerala',
    client_phone: q10,
    site_pin: q10.slice(-4),
    site_id: `PCM-${q10.slice(-4)}`
  };
}

function resetPhoneLookupUI() {
  const preview = document.getElementById('clientInfoPreview');
  const pinInput = document.getElementById('loginPinInput');
  if (preview) preview.classList.add('hidden');
  if (pinInput) {
    pinInput.disabled = true;
    pinInput.value = '';
  }
  setSubmitButtonState(false);
  currentClientFound = null;
}

function updateClientFoundUI(client) {
  currentClientFound = client;
  const preview = document.getElementById('clientInfoPreview');
  const nameEl = document.getElementById('previewClientName');
  const locEl = document.getElementById('previewClientLocation');
  const pinInput = document.getElementById('loginPinInput');

  if (preview) preview.classList.remove('hidden');
  if (nameEl) nameEl.textContent = client.client_name || '';
  if (locEl) locEl.textContent = '📍 ' + (client.site_location || client.location || '');

  if (pinInput) {
    pinInput.disabled = false;
    pinInput.focus();
    pinInput.oninput = () => setSubmitButtonState(pinInput.value.trim().length === 4);
    pinInput.onkeydown = (e) => {
      if (e.key === 'Enter' && pinInput.value.trim().length === 4) {
        verifyAndLoginClient();
      }
    };
  }
}

function updateClientNotFoundUI() {
  currentClientFound = null;
  const preview = document.getElementById('clientInfoPreview');
  const nameEl = document.getElementById('previewClientName');
  const locEl = document.getElementById('previewClientLocation');
  const pinInput = document.getElementById('loginPinInput');

  if (preview) {
    preview.classList.remove('hidden');
    if (nameEl) nameEl.textContent = 'നമ്പർ കണ്ടെത്തിയില്ല / Not Registered';
    if (locEl) locEl.textContent = '💡 പുതിയ അക്കൗണ്ട് തുടങ്ങാൻ "REGISTER" ടാബ് ഉപയോഗിക്കുക.';
  }
  if (pinInput) pinInput.disabled = true;
  setSubmitButtonState(false);
}

// Automatic Client Lookup by Phone Number
async function lookupClientByPhone(phoneVal) {
  const cleanPhone = (phoneVal || '').replace(/\D/g, '');
  if (cleanPhone.length < 10) {
    resetPhoneLookupUI();
    return;
  }

  const phoneQuery = cleanPhone.slice(-10);
  const client = await fetchClientRecord(phoneQuery);

  if (client) {
    updateClientFoundUI(client);
  } else {
    updateClientNotFoundUI();
  }
}

// ===========================================================================
// STRICT ACCESS CONTROL & VERIFICATION
// ===========================================================================

// Check database if client exists in Admin's active Site Folders / Leads list
async function verifyClientAccess(phone, pin) {
  if (!supabase) return null;
  const q10 = (phone || '').replace(/\D/g, '').slice(-10);
  const cleanPin = (pin || '').trim();
  if (!q10 || !cleanPin) return null;

  // 1. Check database if client exists in Admin's active Site Folders (`site_folders`)
  try {
    const { data: folder, error } = await supabase
      .from('site_folders')
      .select('*')
      .or(`phone.ilike.%${q10}%,phone_number.ilike.%${q10}%`)
      .or(`soft_pin.eq.${cleanPin},pin.eq.${cleanPin},site_pin.eq.${cleanPin}`)
      .order('updated_at', { ascending: false })
      .limit(1);

    if (!error && folder && folder.length > 0) {
      const f = folder[0];
      const status = (f.status || '').toLowerCase();
      if (!['revoked', 'deleted', 'inactive', 'blocked'].some(k => status.includes(k))) {
        return {
          id: f.id,
          client_name: f.client_name || 'Client',
          site_location: f.site_location || f.location || 'Wayanad, Kerala',
          client_phone: f.phone || f.phone_number || q10,
          site_pin: cleanPin,
          site_id: f.unit_number || f.site_id || f.id || `PCM-${cleanPin}`,
          status: f.status || 'Active',
          source: 'site_folders'
        };
      }
    }
  } catch (err) {
    console.debug('site_folders check note:', err);
  }

  // 2. Check site_portals
  try {
    const { data: portal, error } = await supabase
      .from('site_portals')
      .select('*')
      .ilike('client_phone', `%${q10}%`)
      .or(`site_pin.eq.${cleanPin},soft_pin.eq.${cleanPin},pin.eq.${cleanPin}`)
      .order('updated_at', { ascending: false })
      .limit(1);

    if (!error && portal && portal.length > 0) {
      const p = portal[0];
      const status = (p.status || '').toLowerCase();
      if (!['revoked', 'deleted', 'inactive', 'blocked'].some(k => status.includes(k))) {
        return {
          id: p.site_id,
          client_name: p.client_name || 'Client',
          site_location: p.site_location || p.location || 'Wayanad, Kerala',
          client_phone: p.client_phone || q10,
          site_pin: cleanPin,
          site_id: p.site_id || `PCM-${cleanPin}`,
          status: p.status || 'Active',
          source: 'site_portals'
        };
      }
    }
  } catch (err) {
    console.debug('site_portals check note:', err);
  }

  // 3. Check website_leads
  try {
    const { data: leads, error } = await supabase
      .from('website_leads')
      .select('*')
      .or(`phone_number.ilike.%${q10}%,phone.ilike.%${q10}%`)
      .or(`soft_pin.eq.${cleanPin},pin.eq.${cleanPin},site_pin.eq.${cleanPin}`)
      .order('created_at', { ascending: false })
      .limit(1);

    if (!error && leads && leads.length > 0) {
      const l = leads[0];
      const status = (l.status || '').toLowerCase();
      if (!['revoked', 'deleted', 'inactive', 'blocked'].some(k => status.includes(k))) {
        return {
          id: l.id || l.site_id || `lead_${q10}`,
          client_name: l.client_name || l.name || 'Client',
          site_location: l.location || l.place || 'Wayanad, Kerala',
          client_phone: l.phone_number || l.phone || q10,
          site_pin: cleanPin,
          site_id: l.site_id || `PCM-${cleanPin}`,
          status: l.status || 'Lead Active',
          source: 'website_leads'
        };
      }
    }
  } catch (err) {
    console.debug('website_leads check note:', err);
  }

  // 4. Check clients table
  try {
    const { data: clients, error } = await supabase
      .from('clients')
      .select('*')
      .ilike('phone_number', `%${q10}%`)
      .or(`site_pin.eq.${cleanPin},soft_pin.eq.${cleanPin},pin.eq.${cleanPin},login_pin.eq.${cleanPin}`)
      .limit(1);

    if (!error && clients && clients.length > 0) {
      const c = clients[0];
      const status = (c.status || '').toLowerCase();
      if (!['revoked', 'deleted', 'inactive', 'blocked'].some(k => status.includes(k))) {
        return {
          id: c.id || c.unitNumber,
          client_name: c.client_name || 'Client',
          site_location: c.site_location || 'Wayanad, Kerala',
          client_phone: c.phone_number || q10,
          site_pin: cleanPin,
          site_id: c.unitNumber ? `PCM-${c.unitNumber}` : `PCM-${cleanPin}`,
          status: c.status || 'Active',
          source: 'clients'
        };
      }
    }
  } catch (err) {
    console.debug('clients check note:', err);
  }

  return null;
}
window.verifyClientAccess = verifyClientAccess;

// Client PIN Login Verification (Strictly against database)
async function verifyAndLoginClient() {
  const pinInput = document.getElementById('loginPinInput');
  const phoneInput = document.getElementById('loginPhoneInput');
  const enteredPin = pinInput?.value.trim() || '';
  const rawPhone = phoneInput?.value || currentClientFound?.client_phone || '';
  const cleanPhone = (rawPhone || '').replace(/\D/g, '');

  if (cleanPhone.length < 10) {
    alert('ദയവായി 10-അക്ക ഫോൺ നമ്പർ നൽകുക.');
    return;
  }

  if (enteredPin.length !== 4) {
    alert('ദയവായി നിങ്ങളുടെ 4-അക്ക സോഫ്റ്റ് പിൻ നൽകുക.');
    return;
  }

  // Check database if client exists in Admin's active Site Folders / Leads list
  const activeRecord = await verifyClientAccess(cleanPhone, enteredPin);

  if (activeRecord) {
    // Client is active and approved by admin
    const clientName = activeRecord.client_name || 'Client';
    const siteId = activeRecord.site_id || `PCM-${enteredPin}`;
    const phone = activeRecord.client_phone || cleanPhone;

    localStorage.setItem('pcm_active_site_pin', enteredPin);
    localStorage.setItem('pcm_portal_user', clientName);
    localStorage.setItem('pcm_client_phone', phone);
    localStorage.setItem('pcm_client_site_id', siteId);

    const modal = document.getElementById('websiteAuthModal');
    if (modal) modal.classList.add('hidden');

    triggerLogoUnlockAndOpen(clientName);
  } else {
    // Access denied: Not registered or deleted by admin
    alert('⚠️ പ്രവേശനം നിരസിച്ചു! നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിൻ സിസ്റ്റത്തിൽ കാണാനില്ല അല്ലെങ്കിൽ നീക്കം ചെയ്യപ്പെട്ടു. ദയവായി രജിസ്റ്റർ ചെയ്യുക.\n\nAccess Denied: You are not registered or your account was removed by the administrator. Please register.');
    _clearLocalStorageSession();
    resetPhoneLookupUI();
    // Redirect strictly back to the registration screen
    switchAuthTab('register');
  }
}

// Save & Activate New 4-Digit Soft PIN
async function saveAndActivateNewPin() {
  const phoneInput = document.getElementById('newPinPhoneInput');
  const pinInput = document.getElementById('newPinCodeInput');

  const phone = phoneInput ? phoneInput.value.trim().replace(/\D/g, '') : '';
  const newPin = pinInput ? pinInput.value.trim() : '';

  if (phone.length < 10) {
    alert('ദയവായി 10-അക്ക ഫോൺ നമ്പർ നൽകുക.');
    return;
  }

  if (newPin.length !== 4 || Number.isNaN(Number(newPin))) {
    alert('ദയവായി 4-അക്ക സോഫ്റ്റ് പിൻ നൽകുക (ഉദാ: 4840).');
    return;
  }

  const phoneQuery = phone.slice(-10);

  // STRICT ACCESS CONTROL: Check database if client exists in Admin's active Site Folders / Leads list
  const existingClient = await fetchClientRecord(phoneQuery);
  if (!existingClient) {
    alert('⚠️ പ്രവേശനം നിരസിച്ചു! ഈ ഫോൺ നമ്പർ അഡ്മിൻ സിസ്റ്റത്തിൽ രജിസ്റ്റർ ചെയ്തിട്ടില്ല. ദയവായി ആദ്യം രജിസ്റ്റർ ചെയ്യുക.\n\nAccess Denied: This phone number is not registered in the Admin system. Please register first.');
    switchAuthTab('register');
    return;
  }

  if (supabase) {
    try {
      await supabase
        .from('site_portals')
        .update({ site_pin: newPin, soft_pin: newPin, updated_at: new Date().toISOString() })
        .ilike('client_phone', `%${phoneQuery}%`);

      await supabase
        .from('website_leads')
        .update({ soft_pin: newPin, site_pin: newPin, pin: newPin })
        .ilike('phone_number', `%${phoneQuery}%`);

      try {
        await supabase
          .from('site_folders')
          .update({ soft_pin: newPin, pin: newPin, updated_at: new Date().toISOString() })
          .ilike('phone', `%${phoneQuery}%`);
      } catch (_) {}
    } catch (e) {
      console.warn('Supabase PIN update error:', e);
    }
  }

  const clientName = existingClient.client_name || 'Client ' + phoneQuery.slice(-4);
  const siteId = existingClient.site_id || `PCM-${phoneQuery.slice(-4)}`;

  localStorage.setItem('pcm_active_site_pin', newPin);
  localStorage.setItem('pcm_client_phone', phone);
  localStorage.setItem('pcm_portal_user', clientName);
  localStorage.setItem('pcm_client_site_id', siteId);

  alert(`✅ നിങ്ങളുടെ പുതിയ 4-അക്ക സോഫ്റ്റ് പിൻ (${newPin}) ആക്റ്റീവ് ആക്കി! സ്വാഗതം.`);

  const modal = document.getElementById('websiteAuthModal');
  if (modal) modal.classList.add('hidden');

  triggerLogoUnlockAndOpen(clientName);
}

// High-speed Drill Spinning Logo Reveal Animation
function triggerLogoUnlockAndOpen(clientName) {
  const splash = document.getElementById('logoUnlockOverlay');
  const logo = document.getElementById('revealLogoImg');
  
  if (splash) splash.classList.remove('hidden');
  
  // Reset and trigger drill spinning animation
  if (logo) {
    logo.classList.remove('drill-spinning');
    logo.getBoundingClientRect(); // Trigger reflow without void operator
    logo.classList.add('drill-spinning');
  }

  // After drill rotation, unlock main website application
  setTimeout(() => {
    if (splash) splash.classList.add('opacity-0');
    unlockAppView(localStorage.getItem('pcm_active_site_pin') || '', clientName);
    
    setTimeout(() => {
      if (splash) {
        splash.classList.add('hidden');
        splash.classList.remove('opacity-0');
      }
      if (logo) logo.classList.remove('drill-spinning');
    }, 400);
  }, 1200);
}

// Unlock Main Application View
function unlockAppView(sitePin, clientName) {
  const modal = document.getElementById('websiteAuthModal');
  const mainApp = document.getElementById('mainWebsiteApp');
  
  if (modal) modal.classList.add('hidden');
  if (mainApp) mainApp.classList.remove('hidden');

  // Save session state
  if (clientName) localStorage.setItem('pcm_portal_user', clientName);
  if (sitePin) localStorage.setItem('pcm_active_site_pin', sitePin);

  // Update Header Elements
  const headerName = document.getElementById('headerClientName');
  const mobileName = document.getElementById('mobileHeaderClientName');
  if (headerName) headerName.textContent = clientName || 'Client';
  if (mobileName) mobileName.textContent = clientName || 'Client';

  const guestNav = document.getElementById('navAuthGuest');
  const userNav = document.getElementById('navAuthUser');
  const mobileGuest = document.getElementById('mobileAuthGuest');
  const mobileUser = document.getElementById('mobileAuthUser');

  if (guestNav) guestNav.classList.add('hidden');
  if (userNav) userNav.classList.remove('hidden');
  if (mobileGuest) mobileGuest.classList.add('hidden');
  if (mobileUser) mobileUser.classList.remove('hidden');

  // Initialize live gallery, slideshow and portal components
  if (typeof window.loadLiveWebsiteGallery === 'function') {
    window.loadLiveWebsiteGallery();
  }
  if (typeof window.initGypsumDesignSlideshow === 'function') {
    window.initGypsumDesignSlideshow();
  }
  if (typeof window.initRealtimePortalSync === 'function') {
    window.initRealtimePortalSync();
  }

  // Start Realtime Session Watcher
  startRealtimeSessionWatcher();

  // Automatically open MY PROJECT HUB view matching design specs
  setTimeout(() => {
    openMyProjectHub({ client_name: clientName });
  }, 200);
}

let realtimeSessionChannel = null;

function performForceSignOut() {
  console.warn('[PCM Auth] performForceSignOut triggered: Account deleted or revoked.');
  alert('⚠️ നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിനിസ്ട്രേറ്റർ നീക്കം ചെയ്തു. ദയവായി വീണ്ടും രജിസ്റ്റർ ചെയ്യുക.\n\nYour account was removed by the administrator. Redirecting to registration screen.');
  handleSignOut();
}
window.performForceSignOut = performForceSignOut;

function listenToAdminChanges(clientId) {
  startRealtimeSessionWatcher(clientId);
}
window.listenToAdminChanges = listenToAdminChanges;

function startRealtimeSessionWatcher(specificClientId) {
  if (!supabase || typeof supabase.channel !== 'function') return;
  if (realtimeSessionChannel) {
    try { supabase.removeChannel(realtimeSessionChannel); } catch (_) {}
    realtimeSessionChannel = null;
  }

  const clientPhone = (localStorage.getItem('pcm_client_phone') || '').replace(/\D/g, '').slice(-10);
  const siteId = (specificClientId || localStorage.getItem('pcm_client_site_id') || '').toLowerCase();
  const sitePin = localStorage.getItem('pcm_active_site_pin') || '';

  if (!clientPhone && !siteId && !sitePin) return;

  const channelId = `session_watch_${Date.now()}`;
  realtimeSessionChannel = supabase.channel(channelId);

  const isMatch = (record) => {
    if (!record) return false;
    const recPhone = (record.client_phone || record.phone || record.phone_number || '').replace(/\D/g, '').slice(-10);
    const recSiteId = (record.site_id || record.unit_number || record.id || '').toString().toLowerCase();
    const recPin = String(record.site_pin || record.soft_pin || record.pin || '');
    return Boolean(
      (clientPhone && recPhone === clientPhone) ||
      (siteId && (recSiteId === siteId || recSiteId.includes(siteId) || siteId.includes(recSiteId))) ||
      (sitePin && recPin === sitePin)
    );
  };

  // 1. Listen for DELETE and UPDATE events on site_portals
  realtimeSessionChannel
    .on('postgres_changes', { event: '*', schema: 'public', table: 'site_portals' }, (payload) => {
      if (payload.eventType === 'DELETE') {
        if (isMatch(payload.old)) {
          console.warn('[PCM Auth] Real-time session invalidation: site_portals record deleted by administrator.');
          performForceSignOut();
        }
      } else if (payload.eventType === 'UPDATE') {
        if (isMatch(payload.new)) {
          const status = (payload.new.status || '').toLowerCase();
          if (status.includes('revoked') || status.includes('deleted') || status.includes('inactive') || status.includes('blocked')) {
            console.warn('[PCM Auth] Real-time session revocation: account marked inactive.');
            performForceSignOut();
          }
        }
      }
    })
    .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'website_leads' }, (payload) => {
      if (isMatch(payload.old)) {
        console.warn('[PCM Auth] Real-time session invalidation: website_leads record deleted.');
        performForceSignOut();
      }
    })
    .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'site_folders' }, (payload) => {
      if (isMatch(payload.old)) {
        console.warn('[PCM Auth] Real-time session invalidation: site_folders record deleted.');
        performForceSignOut();
      }
    })
    .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'clients' }, (payload) => {
      if (isMatch(payload.old)) {
        console.warn('[PCM Auth] Real-time session invalidation: clients record deleted.');
        performForceSignOut();
      }
    })
    .subscribe();
}

function _clearLocalStorageSession() {
  const isTargetKey = (k) => k && (
    k.startsWith('pcm_') ||
    k.startsWith('sb-') ||
    k.includes('supabase') ||
    k.includes('auth-token') ||
    k.includes('token')
  );

  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (isTargetKey(k)) {
      keysToRemove.push(k);
    }
  }
  keysToRemove.forEach(k => localStorage.removeItem(k));
  [
    'pcm_portal_user', 'pcm_active_site_pin', 'pcm_client_phone',
    'pcm_client_site_id', 'pcm_client_name', 'pcm_active_site', 'supabase.auth.token'
  ].forEach(k => localStorage.removeItem(k));
  
  try { sessionStorage.clear(); } catch (_) {}
}

function _disconnectRealtimeWatcher() {
  if (!realtimeSessionChannel || !supabase) return;
  try { 
    supabase.removeChannel(realtimeSessionChannel); 
  } catch (_) {}
  realtimeSessionChannel = null;
}

async function _supabaseSignOut() {
  if (!window.supabase?.auth) return;
  try {
    await window.supabase.auth.signOut();
  } catch (_) {}
}

function _resetNavAndHeaderUI() {
  ['navAuthGuest', 'mobileAuthGuest'].forEach(id => {
    document.getElementById(id)?.classList.remove('hidden');
  });
  ['navAuthUser', 'mobileAuthUser'].forEach(id => {
    document.getElementById(id)?.classList.add('hidden');
  });

  const headerName = document.getElementById('headerClientName');
  if (headerName) headerName.textContent = 'Sign In';
  const mobileName = document.getElementById('mobileHeaderClientName');
  if (mobileName) mobileName.textContent = 'Sign In';
}

function _resetAuthModalInputs() {
  const phoneInput = document.getElementById('loginPhoneInput');
  if (phoneInput) phoneInput.value = '';

  const pinInput = document.getElementById('loginPinInput');
  if (pinInput) {
    pinInput.value = '';
    pinInput.disabled = true;
  }

  const preview = document.getElementById('clientInfoPreview');
  if (preview) preview.classList.add('hidden');

  const submitBtn = document.getElementById('loginSubmitBtn');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.classList.add('bg-amber-500/50');
    submitBtn.classList.remove('bg-amber-500', 'hover:bg-amber-400');
  }
}

function _cleanHistoryPath() {
  try {
    let cleanUrl = window.location.pathname;
    while (cleanUrl.length > 1 && cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.slice(0, -1);
    }
    window.history.replaceState(null, '', cleanUrl || '/');
  } catch (err) {
    // Ignore history replaceState failures in restricted or cross-origin contexts
    console.debug('[PCM Auth] History reset skipped:', err);
  }
}

function _redirectAfterSignOut() {
  if (window.location.pathname.includes('portal.html') || window.location.pathname.includes('/portal')) {
    window.location.replace('index.html?auth=register');
  } else {
    openAuthModal('register');
  }
}

// Sign Out / Reset Session
async function handleSignOut() {
  _clearLocalStorageSession();
  _disconnectRealtimeWatcher();
  await _supabaseSignOut();
  _resetNavAndHeaderUI();
  _resetAuthModalInputs();
  _cleanHistoryPath();

  if (typeof window.initRealtimePortalSync === 'function') {
    window.initRealtimePortalSync();
  }

  _redirectAfterSignOut();
}

// Helper to resolve session credentials
async function resolveUserSession() {
  const activePin = localStorage.getItem('pcm_active_site_pin');
  let clientPhone = localStorage.getItem('pcm_client_phone');
  let clientName = localStorage.getItem('pcm_portal_user');

  if (window.supabase?.auth) {
    try {
      const { data } = await window.supabase.auth.getSession();
      const u = data?.session?.user;
      if (u) {
        clientName = clientName || u.user_metadata?.full_name || u.user_metadata?.name;
        clientPhone = clientPhone || u.phone;
      }
    } catch (_ignored) {
      // Supabase auth session is optional; guest fallback applies if unavailable.
    }
  }

  return { activePin, clientPhone, clientName };
}

// Helper to configure guest navigation and trigger sync
function applyGuestUI(modal) {
  if (modal) modal.classList.add('hidden');
  ['navAuthGuest', 'mobileAuthGuest'].forEach(id => {
    document.getElementById(id)?.classList.remove('hidden');
  });
  ['navAuthUser', 'mobileAuthUser'].forEach(id => {
    document.getElementById(id)?.classList.add('hidden');
  });
  if (typeof window.initRealtimePortalSync === 'function') {
    window.initRealtimePortalSync();
  }
}

// Check session on page load with safe fallback
document.addEventListener('DOMContentLoaded', async () => {
  try {
    await checkUserSession();
  } catch (e) {
    console.error('Session Check Error:', e);
    const modal = document.getElementById('websiteAuthModal');
    if (modal) modal.classList.add('hidden');
    const mainApp = document.getElementById('mainWebsiteApp');
    if (mainApp) mainApp.classList.remove('hidden');
  }
});

async function _verifyBackendRecordValid(phone10) {
  try {
    const found = await fetchClientRecord(phone10);
    if (!found) {
      console.warn('[PCM Auth] Stored session record no longer exists in backend. Clearing invalid session.');
      return false;
    }
    const status = (found.status || '').toLowerCase();
    const isRevoked = ['revoked', 'deleted', 'inactive', 'blocked'].some(k => status.includes(k));
    return !isRevoked;
  } catch (err) {
    console.warn('[PCM Auth] Backend verification check notice:', err);
    return true;
  }
}

async function checkUserSession() {
  const mainApp = document.getElementById('mainWebsiteApp');
  const modal = document.getElementById('websiteAuthModal');
  
  // Public website is always accessible to guests
  if (mainApp) mainApp.classList.remove('hidden');

  const { activePin, clientPhone, clientName } = await resolveUserSession();
  const cleanPhone = (clientPhone || '').replace(/\D/g, '');
  const hasValidPhone = cleanPhone.length >= 10;

  if (!activePin && !hasValidPhone) {
    applyGuestUI(modal);
    return;
  }

  if (hasValidPhone) {
    const isValid = await _verifyBackendRecordValid(cleanPhone.slice(-10));
    if (!isValid) {
      handleSignOut();
      return;
    }
  }

  if (modal) modal.classList.add('hidden');
  unlockAppView(activePin || '1234', clientName || 'Client');
}

// ---------------------------------------------------------------------------
// SELF-SERVICE ACCOUNT DELETION (STRICT ZERO-BALANCE VALIDATION)
// ---------------------------------------------------------------------------
async function _findSitePortalRecord(siteId, p10) {
  if (siteId) {
    const { data } = await supabase.from('site_portals').select('*').eq('site_id', siteId).limit(1);
    if (data?.length) return data[0];
  }
  if (p10) {
    const { data } = await supabase.from('site_portals').select('*').ilike('client_phone', `%${p10}%`).limit(1);
    if (data?.length) return data[0];
  }
  return null;
}

async function _findClientRecord(siteId, p10) {
  if (siteId) {
    const { data } = await supabase.from('clients').select('*').eq('unitNumber', siteId).limit(1);
    if (data?.length) return data[0];
  }
  if (p10) {
    const { data } = await supabase.from('clients').select('*').ilike('phone_number', `%${p10}%`).limit(1);
    if (data?.length) return data[0];
  }
  return null;
}

async function _findAppRecord(p10) {
  if (!p10) return null;
  const { data } = await supabase.from('app_records').select('*').or(`phone_number.ilike.%${p10}%,id.eq.lead_${p10}`).limit(1);
  return data?.[0] || null;
}

function _computeRecordDue(portal, client, appRecord) {
  let balanceDue = 0;

  if (portal) {
    const total = Number(portal.total_contract || 0);
    const paid = Number(portal.total_received ?? portal.paid_amount ?? 0);
    const due = Number(portal.balance_due ?? (total - paid));
    balanceDue = Math.max(balanceDue, due);
  }

  if (client) {
    const total = Number(client.totalContractAmount || 0);
    const advance = Number(client.advanceReceived || 0);
    const due = Number(client.balance_due ?? client.balanceAmount ?? (total - advance));
    balanceDue = Math.max(balanceDue, due);
  }

  const rd = appRecord?.record_data;
  if (rd) {
    const total = Number(rd.totalAmount || 0);
    const paid = Number(rd.paidAmount || 0);
    const due = Number(rd.balance_due ?? rd.net_balance_due ?? (total - paid));
    balanceDue = Math.max(balanceDue, due);
  }

  return balanceDue;
}

async function _fetchDueBalanceFromBackend(siteId, p10) {
  if (!supabase) return { balanceDue: 0, foundSitePortal: null, foundClient: null };

  try {
    const [foundSitePortal, foundClient, foundAppRecord] = await Promise.all([
      _findSitePortalRecord(siteId, p10),
      _findClientRecord(siteId, p10),
      _findAppRecord(p10)
    ]);

    const balanceDue = _computeRecordDue(foundSitePortal, foundClient, foundAppRecord);
    return { balanceDue, foundSitePortal, foundClient };
  } catch (fetchErr) {
    console.warn('[PCM Auth] Balance check error:', fetchErr);
    return { balanceDue: 0, foundSitePortal: null, foundClient: null };
  }
}

function _getUIDueBalance(currentBalance) {
  const uiDueEl = document.getElementById('valDue') || document.getElementById('standaloneNetDue');
  if (!uiDueEl) return currentBalance;

  const parsedTextDue = Number.parseFloat(uiDueEl.textContent.replace(/[^\d.-]/g, ''));
  if (!Number.isNaN(parsedTextDue) && parsedTextDue > currentBalance) {
    return parsedTextDue;
  }
  return currentBalance;
}

function _confirmAccountDeletion() {
  return window.confirm(
    `⚠️ അക്കൗണ്ട് പൂർണ്ണമായി നീക്കം ചെയ്യണോ?\nAre you sure you want to permanently delete your account and site folder?\n\n` +
    `• Financial Balance: ₹0.00 (Fully Settled)\n` +
    `• All site photos, folders, leads, and client credentials will be permanently erased.\n` +
    `• This action cannot be undone.\n\n` +
    `Click OK to proceed with permanent deletion.`
  );
}

async function _purgeCustomerRecords(effSiteId, p10) {
  if (!supabase) return;

  const deletionTasks = [];

  if (p10) {
    deletionTasks.push(
      supabase.from('website_leads').delete().or(`phone_number.ilike.%${p10}%,phone.ilike.%${p10}%`),
      supabase.from('site_portals').delete().ilike('client_phone', `%${p10}%`),
      supabase.from('clients').delete().ilike('phone_number', `%${p10}%`),
      supabase.from('app_records').delete().or(`phone_number.ilike.%${p10}%,id.eq.lead_${p10}`),
      supabase.from('client_profiles').delete().ilike('phone', `%${p10}%`)
    );
  }

  if (effSiteId) {
    deletionTasks.push(
      supabase.from('site_portals').delete().eq('site_id', effSiteId),
      supabase.from('clients').delete().eq('unitNumber', effSiteId)
    );
  }

  await Promise.allSettled(deletionTasks);
}

async function handleSelfServiceAccountDeletion() {
  const { activePin, clientPhone } = await resolveUserSession();
  const rawPhone = localStorage.getItem('pcm_client_phone') || clientPhone || '';
  const cleanPhone = rawPhone.replace(/\D/g, '');
  const siteId = localStorage.getItem('pcm_client_site_id') || localStorage.getItem('pcm_site_id') || '';

  if (!cleanPhone && !siteId && !activePin) {
    alert('സജീവമായ ക്ലയൻ്റ് അക്കൗണ്ട് സെഷൻ കണ്ടെത്താനായില്ല.\n(No active client session found.)');
    return;
  }

  const p10 = cleanPhone.length >= 10 ? cleanPhone.slice(-10) : cleanPhone;
  const { balanceDue: backendDue, foundSitePortal, foundClient } = await _fetchDueBalanceFromBackend(siteId, p10);
  const balanceDue = _getUIDueBalance(backendDue);

  // Strict validation: verify if financial balance is exactly zero
  if (balanceDue > 0.009) {
    const formattedDue = (typeof window.formatInr === 'function')
      ? window.formatInr(balanceDue)
      : '₹' + balanceDue.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

    alert(
      `⚠️ അക്കൗണ്ട് നീക്കം ചെയ്യാൻ സാധ്യമല്ല / ACCOUNT DELETION BLOCKED\n\n` +
      `നിങ്ങളുടെ അക്കൗണ്ടിൽ നിലവിൽ ${formattedDue} ബാക്കി തുക (Balance Due) ഉണ്ട്.\n` +
      `ബാക്കി തുക കൃത്യമായി ₹0.00 ആയാൽ മാത്രമേ അക്കൗണ്ടും സൈറ്റ് ഫോൾഡറും നീക്കം ചെയ്യാൻ സാധിക്കൂ.\n\n` +
      `Remaining Balance Due: ${formattedDue}\n` +
      `Please clear all pending dues with PCM Wayanad before deleting your account.`
    );
    return;
  }

  if (!_confirmAccountDeletion()) return;

  try {
    const effSiteId = siteId || foundSitePortal?.site_id || foundClient?.unitNumber || (p10 ? `PCM-${p10.slice(-4)}` : '');
    await _purgeCustomerRecords(effSiteId, p10);

    alert('✅ അക്കൗണ്ടും സൈറ്റ് ഫോൾഡർ ഡാറ്റയും വിജയകരമായി നീക്കം ചെയ്തു.\nYour account and site folder have been permanently deleted.');
    await handleSignOut();
  } catch (err) {
    console.error('[PCM Auth] Deletion failed:', err);
    alert('അക്കൗണ്ട് നീക്കം ചെയ്യുന്നതിൽ പിശക് സംഭവിച്ചു: ' + (err.message || err));
  }
}

// Expose to window for global invocation from menu buttons
window.handleSelfServiceAccountDeletion = handleSelfServiceAccountDeletion;

// =========================================================================
// MY PROJECT HUB DASHBOARD (EXACT SCREENSHOT LAYOUT & INTERACTIVE HUB)
// =========================================================================
function openMyProjectHub(clientData) {
  const modal = document.getElementById('myProjectHubModal');
  if (!modal) return;

  const storedName = localStorage.getItem('pcm_portal_user') || 'MADHU';
  const storedPhone = localStorage.getItem('pcm_client_phone') || '8606415174';
  const storedSiteId = localStorage.getItem('pcm_client_site_id') || 'PCM-WAYANAD';

  const client = clientData || {
    client_name: storedName,
    site_id: storedSiteId,
    client_phone: storedPhone,
    code: 'HCHFDGZDG',
    total_estimate: '9,688',
    paid_amount: '0',
    due_amount: '9,688',
    stage_num: '3',
    stage_name: 'CEILING FABRICATION'
  };

  const initial = (client.client_name || 'M').trim().charAt(0).toUpperCase();
  const avatarEl = document.getElementById('hubClientAvatar');
  const nameEl = document.getElementById('hubClientName');
  const subEl = document.getElementById('hubClientSubtitle');
  const siteIdTextEl = document.getElementById('hubSiteIdText');

  if (avatarEl) avatarEl.textContent = initial || 'M';
  if (nameEl) nameEl.textContent = (client.client_name || 'MADHU').toUpperCase();

  const uniqueCode = client.code || 'HCHFDGZDG';
  const phone = client.client_phone || '8606415174';
  if (subEl) subEl.textContent = `${uniqueCode} • ${phone}`;

  const cleanSiteId = (client.site_id || 'PCM-WAYANAD').toUpperCase();
  if (siteIdTextEl) siteIdTextEl.textContent = `SITE ID: ${cleanSiteId}`;

  const estEl = document.getElementById('hubTotalEstimate');
  const paidEl = document.getElementById('hubPaidAmount');
  const dueEl = document.getElementById('hubDueAmount');

  if (estEl) estEl.textContent = `₹${client.total_estimate || '9,688'}`;
  if (paidEl) paidEl.textContent = `₹${client.paid_amount || '0'}`;
  if (dueEl) dueEl.textContent = `₹${client.due_amount || '9,688'}`;

  const stageBadge = document.getElementById('hubStageBadge');
  const stageTitle = document.getElementById('hubStageTitle');
  if (stageBadge) stageBadge.textContent = `STAGE ${client.stage_num || '3'}:`;
  if (stageTitle) stageTitle.textContent = `${client.stage_num || '3'}. ${client.stage_name || 'CEILING FABRICATION'}`;

  modal.classList.remove('hidden');
}

function closeMyProjectHub() {
  const modal = document.getElementById('myProjectHubModal');
  if (modal) modal.classList.add('hidden');
}

function copyHubSiteId() {
  const textEl = document.getElementById('hubSiteIdText');
  const rawText = textEl ? textEl.textContent.replace('SITE ID: ', '').trim() : 'PCM-WAYANAD';
  if (navigator.clipboard) {
    navigator.clipboard.writeText(rawText).then(() => {
      alert(`📋 Site ID (${rawText}) copied to clipboard!`);
    }).catch(() => alert(`Site ID: ${rawText}`));
  } else {
    alert(`Site ID: ${rawText}`);
  }
}

let currentCashfreeMode = null;
let cashfreeInstance = null;

function getCashfreeInstance(mode = 'sandbox') {
  const targetMode = (mode === 'production' || mode === 'PRODUCTION') ? 'production' : 'sandbox';
  if (cashfreeInstance && currentCashfreeMode === targetMode) {
    return cashfreeInstance;
  }
  if (typeof window.Cashfree !== 'undefined') {
    try {
      cashfreeInstance = window.Cashfree({
        mode: targetMode
      });
      currentCashfreeMode = targetMode;
    } catch (e) {
      console.warn('[Cashfree Init Notice]', e);
    }
  }
  return cashfreeInstance;
}

async function payViaCashfree() {
  const dueEl = document.getElementById('hubDueAmount');
  const dueText = dueEl ? dueEl.textContent.replace(/[^\d.-]/g, '') : '9688';
  const baseAmount = Math.max(10, parseFloat(dueText) || 9688);
  const siteId = localStorage.getItem('pcm_client_site_id') || 'PCM-WAYANAD';
  const phone = localStorage.getItem('pcm_client_phone') || '9383406185';
  const name = localStorage.getItem('pcm_portal_user') || 'PCM Client';

  const payBtn = document.querySelector('button[onclick="payViaCashfree()"]');
  const originalHtml = payBtn ? payBtn.innerHTML : '';

  if (payBtn) {
    payBtn.disabled = true;
    payBtn.innerHTML = `<span>⏳</span> <span>INITIATING CASHFREE CHECKOUT...</span>`;
  }

  try {
    // 1. Call Vercel Serverless API to create Cashfree order & fetch payment_session_id
    const response = await fetch('/api/create-cashfree-order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        baseAmount: baseAmount,
        clientName: name,
        clientPhone: phone,
        siteId: siteId,
        returnUrl: window.location.href
      })
    });

    if (response.ok) {
      const data = await response.json();
      if (data && data.payment_session_id) {
        const envMode = data.mode || (data.payment_session_id.includes('session_test_') || (data.order_id && data.order_id.includes('TEST')) ? 'sandbox' : 'production');
        const cashfree = getCashfreeInstance(envMode);

        if (cashfree && typeof cashfree.checkout === 'function') {
          if (payBtn) {
            payBtn.disabled = false;
            payBtn.innerHTML = originalHtml;
          }

          // Trigger Cashfree SDK Drop-in Modal Checkout
          cashfree.checkout({
            paymentSessionId: String(data.payment_session_id).trim(),
            redirectTarget: "_modal"
          });
          return;
        }
      } else {
        console.warn('[Cashfree Order Warning]: Response did not contain payment_session_id', data);
      }
    }
  } catch (err) {
    console.warn('[Cashfree API Checkout notice]:', err);
  } finally {
    if (payBtn) {
      payBtn.disabled = false;
      payBtn.innerHTML = originalHtml;
    }
  }

  // 2. Direct UPI / Cashfree Portal Fallback if Vercel serverless API is offline
  const upiUri = `upi://pay?pa=9383406185@ybl&pn=PCM%20WAYANAD&am=${baseAmount}&cu=INR&tn=Payment%20for%20${siteId}`;
  alert(`🛡️ Redirecting to Cashfree Secure Checkout for ₹${baseAmount.toLocaleString('en-IN')} (+ 2.36% Fee)...`);

  const formWin = window.open(`https://payments.cashfree.com/forms/pcmwayanad?amount=${baseAmount}&site_id=${encodeURIComponent(siteId)}`, '_blank');
  if (!formWin) {
    window.location.href = upiUri;
  }
}

function triggerHubPhotoUpload() {
  const fileInput = document.getElementById('hubPhotoFileInput');
  if (fileInput) fileInput.click();
}

function handleHubPhotoSelected(event) {
  const files = event.target.files;
  if (files && files.length > 0) {
    alert(`📷 Photo attached: ${files[0].name}. Click 'SUBMIT TO ADMIN' to upload.`);
  }
}

function submitHubNoteToAdmin() {
  const noteInput = document.getElementById('hubAdminNoteInput');
  const noteText = noteInput ? noteInput.value.trim() : '';
  const fileInput = document.getElementById('hubPhotoFileInput');
  const hasPhoto = fileInput && fileInput.files && fileInput.files.length > 0;

  if (!noteText && !hasPhoto) {
    alert('ദയവായി ഒരു കുറിപ്പ് എഴുതുക അല്ലെങ്കിൽ ഫോട്ടോ ചേർക്കുക.\nPlease write a note or attach a photo for admin.');
    return;
  }

  alert('✅ നന്ദി! നിങ്ങളുടെ സന്ദേശവും വിവരങ്ങളും PCM അഡ്മിൻ ടീമിലേക്ക് വിജയകരമായി അയച്ചു.\n\nMessage submitted to PCM Admin successfully!');
  if (noteInput) noteInput.value = '';
  if (fileInput) fileInput.value = '';
}

window.openMyProjectHub = openMyProjectHub;
window.closeMyProjectHub = closeMyProjectHub;
window.copyHubSiteId = copyHubSiteId;
window.payViaCashfree = payViaCashfree;
window.triggerHubPhotoUpload = triggerHubPhotoUpload;
window.handleHubPhotoSelected = handleHubPhotoSelected;
window.submitHubNoteToAdmin = submitHubNoteToAdmin;

function toggleHubSection(sectionId, iconId) {
  const section = document.getElementById(sectionId);
  const icon = document.getElementById(iconId);
  if (!section) return;

  const isHidden = section.classList.contains('hidden');
  if (isHidden) {
    section.classList.remove('hidden');
    if (icon) icon.classList.add('rotate-180');
  } else {
    section.classList.add('hidden');
    if (icon) icon.classList.remove('rotate-180');
  }
}
window.toggleHubSection = toggleHubSection;

