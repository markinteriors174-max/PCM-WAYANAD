/**
 * =========================================================================
 * PCM WAYANAD - CLIENT-SIDE SPA ROUTER & VCARD CONTACT SYNC ENGINE
 * =========================================================================
 * Provides seamless client-side routing, deep linking, 404-prevention,
 * browser history support (pushState / popstate), direct path handling,
 * and automatic smartphone vCard contact card address book integration.
 */

(function () {
  'use strict';

  const ROUTES = {
    '/': { action: 'home', title: 'Home | PCM WAYANAD' },
    '/home': { action: 'home', title: 'Home | PCM WAYANAD' },
    '/gallery': { action: 'scroll', targetId: 'gallery', title: 'Portfolio Gallery | PCM WAYANAD' },
    '/portfolio': { action: 'scroll', targetId: 'gallery', title: 'Portfolio Gallery | PCM WAYANAD' },
    '/before-after': { action: 'scroll', targetId: 'before-after', title: 'Before & After Transformations | PCM WAYANAD' },
    '/room-selector': { action: 'scroll', targetId: 'room-selector', title: 'Room Design Selector | PCM WAYANAD' },
    '/calculator': { action: 'scroll', targetId: 'calculator', title: 'Budget Calculator | PCM WAYANAD' },
    '/calc': { action: 'scroll', targetId: 'calculator', title: 'Budget Calculator | PCM WAYANAD' },
    '/estimate': { action: 'scroll', targetId: 'calculator', title: 'Budget Calculator | PCM WAYANAD' },
    '/team-showcase': { action: 'scroll', targetId: 'team-showcase', title: 'Master Craftsmen | PCM WAYANAD' },
    '/craftsmen': { action: 'scroll', targetId: 'team-showcase', title: 'Master Craftsmen | PCM WAYANAD' },
    '/team': { action: 'scroll', targetId: 'team-showcase', title: 'Master Craftsmen | PCM WAYANAD' },
    '/site-portal': { action: 'scroll', targetId: 'site-portal', title: 'Client Live Portal | PCM WAYANAD' },
    '/client-portal': { action: 'scroll', targetId: 'site-portal', title: 'Client Live Portal | PCM WAYANAD' },
    '/process': { action: 'scroll', targetId: 'process', title: 'Workflow & Process | PCM WAYANAD' },
    '/contact': { action: 'scroll', targetId: 'contact', title: 'Contact & Booking | PCM WAYANAD' },
    '/login': { action: 'authModal', tab: 'login', title: 'Client Login | PCM WAYANAD' },
    '/register': { action: 'authModal', tab: 'register', title: 'Client Registration | PCM WAYANAD' },
    '/newpin': { action: 'authModal', tab: 'newpin', title: 'Reset / Create PIN | PCM WAYANAD' },
    '/portal': { action: 'portalRedirect', title: 'Client Portal Dashboard' },
    '/portal/': { action: 'portalRedirect', title: 'Client Portal Dashboard' },
  };

  const PCM_LOGO_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAwFBMVEVsol8fMCcXTWLX5tSZrqIabpYaUmkUYisYTm8fb40jTiOlzphrlaCap5VfblwMNUonXyeRyltbc2kdb4dYlzcNLyk2SCQ3hDRKYzFwlGGFtWYoSlJGcGJofYV8iYsNPmhXXlAmOEBDUTN5iXCStstxqcMjiKNIejiDmmy4xMnI6L5+xkkJOFUAAAAJFRIFGCQPNkcJJjIKJTMHGyn7/PoMZy8oeDIXJRLV2dIzOTAUQ1ILO1UUczMSKBEZWXNTmDl69jgqAAAAQHRSTlP3HVv48+Ga2d6fZPj5qFtbmv+ldvZKLfpqovAy7NWc3DEuK2j//6qpnv/5/6MACxcyGScm//r6E+8ZMoz+JHX69+RYYgAAApBJREFUeNrtlemSmzAMgG3jQDhD7nPvu62FTQLkzvu/1coku5ltx+zOtr86aBKCYvlDkiVBxF8KqQE1oAbUgP8UMO/LllTUbK1SNGjNjYDEbt1It8FM+1nDZZLZSUUIANrMTOTKC2n+9TWaG1RmQOVCGU3m82rK7w0ToIqarYSifo8iZACpPNS0jSVFC8nDUDB104hQT8BIAHtMToP5/iqAbipQDnrq+vr1e974SPnAyDL8gNpk553VKPlAsWKcFOeOW9GzjYzApws7/VI7zCM9ZO4tVgsNeNZA7L+0cYbnll/erB1dBTxcIvWoWWF6P8qtKiAZnN23Aa9vAJASEf/FITYglrLsPyz35lGrDObkTKwJ4JiBHC/VMH3x5iAJRU3l5ezRnBJgfCA+5hd6vsTn5sA4Fv6oXD3AxPX4eSCvyxeApuWK1GoF31rPLZ8MAHQu/H4edImBG4uguDeCngHTisRJZPBrd8uIlw1AfJ8SH6224enQtgP3OLo9+ptxRPxAc94JOI8NwKyzPG80UBXkgwueNCZ4t3quqwDT8DwQCYg4iwD8zHG752L3odhtLq9sxbRESC8XnsgRLytqoMz4N6yy0IsSxHyrT5EbyQ0oKISnXeAfOBYQ4hYhvoUHKf/tuI5zldmIgTc2IDmbqR0VxSU0gF+CWe7ouxn3dFz7O9U0XI+QVLRzrvdjg4Gt5SuRiOKikhwkgDgMBEglaRSShwv3xzrin0aQn+zabWE2ivBpmvXZbatNblma9btumwvJBOgTUyADYrN3H1j73bdxy4OcVuPctllrPvouvu9i8hN65f5vYADNE2kXKu1/uBIVSJlGDdjazmlSuKIRZtv5KDiNOvXew2oATXgnwFeAdfsqOn/TXjoAAAAAElFTkSuQmCC';

  /**
   * Generates standard vCard 3.0 content string with embedded company logo
   */
  function generateVCardContent(details = {}) {
    const name = details.name || 'Madhusudhan (Master Craftsman)';
    const org = details.org || 'PCM WAYANAD - Architectural Ceilings & Interiors';
    const rawPhone = details.phone || '9383406185';
    const cleanPhone = rawPhone.replace(/\D/g, '').slice(-10);
    const email = details.email || 'pcmwayanad@gmail.com';
    const website = details.website || 'https://pcm-wayanad-portal.vercel.app';
    const address = details.address || 'Meenangadi, Wayanad, Kerala - 673591';

    return [
      'BEGIN:VCARD',
      'VERSION:3.0',
      `FN:${name} - PCM WAYANAD`,
      `N:Madhusudhan;Master Craftsman;;;`,
      `ORG:${org}`,
      'TITLE:Master Craftsman & Contractor',
      `TEL;TYPE=CELL,VOICE,PREF:+91${cleanPhone}`,
      ...(details.backupPhone ? [`TEL;TYPE=WORK,VOICE:+91${details.backupPhone.replace(/\D/g, '').slice(-10)}`] : []),
      `EMAIL;TYPE=WORK,INTERNET:${email}`,
      `URL;TYPE=WORK:${website}`,
      `ADR;TYPE=WORK:;;Meenangadi;Wayanad;Kerala;673591;India`,
      `LABEL;TYPE=WORK:${address}`,
      'NOTE:Luxury Gypsum False Ceiling, Acoustic Grid Panels, PVC Paneling, Architectural LED Profile Lighting & Realtime Client Portal.',
      `PHOTO;TYPE=PNG;ENCODING=BASE64:${PCM_LOGO_BASE64}`,
      'REV:2026-09-18T08:00:00Z',
      'END:VCARD'
    ].join('\r\n');
  }

  /**
   * Triggers native vCard download prompt on smartphones / desktop
   */
  function triggerVCardDownload(details = {}) {
    try {
      const vcardText = generateVCardContent(details);
      const blob = new Blob([vcardText], { type: 'text/vcard;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'PCM_WAYANAD_Contact.vcf');
      document.body.appendChild(link);
      link.click();
      setTimeout(() => {
        if (link.parentNode) link.parentNode.removeChild(link);
        URL.revokeObjectURL(url);
      }, 500);
    } catch (err) {
      console.warn('Direct vCard blob download fallback:', err);
      window.location.href = 'pcm_wayanad.vcf';
    }
  }

  /**
   * Displays an elegant top notification banner confirming contact card prompt
   */
  function showVCardPromptBanner(details = {}) {
    const existing = document.getElementById('pcmVcardPromptBanner');
    if (existing) existing.remove();

    const banner = document.createElement('div');
    banner.id = 'pcmVcardPromptBanner';
    banner.className = 'fixed top-0 left-0 right-0 z-50 bg-gradient-to-r from-[#0F172A] via-[#1E293B] to-[#0F172A] border-b-2 border-amber-500/80 px-4 py-3 text-white shadow-2xl transition-all duration-300 transform translate-y-0';
    banner.innerHTML = `
      <div class="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2.5">
          <span class="text-xl animate-bounce">📲</span>
          <div>
            <span class="font-extrabold text-amber-400 tracking-wide">PCM WAYANAD CONTACT READY</span>
            <p class="text-slate-300 text-[11px]">Save <strong>+91 9383406185</strong> directly to your phone's address book.</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button id="pcmSaveVcardAgainBtn" class="px-3.5 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider shadow transition cursor-pointer flex items-center gap-1.5">
            <span>💾</span> <span>SAVE TO CONTACTS</span>
          </button>
          <button id="pcmCloseVcardBannerBtn" class="p-1.5 rounded-lg text-slate-400 hover:text-white transition cursor-pointer" title="Dismiss">
            ✕
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(banner);

    const saveBtn = document.getElementById('pcmSaveVcardAgainBtn');
    if (saveBtn) {
      saveBtn.onclick = () => triggerVCardDownload(details);
    }

    const closeBtn = document.getElementById('pcmCloseVcardBannerBtn');
    if (closeBtn) {
      closeBtn.onclick = () => banner.remove();
    }

    // Auto-dismiss after 15 seconds
    setTimeout(() => {
      if (banner.parentNode) {
        banner.style.opacity = '0';
        banner.style.transform = 'translateY(-100%)';
        setTimeout(() => banner.remove(), 300);
      }
    }, 15000);
  }

  class ClientRouter {
    constructor() {
      this.currentRoute = null;
      this.initialized = false;
    }

    init() {
      if (this.initialized) return;
      this.initialized = true;

      // Listen for browser Back / Forward buttons
      window.addEventListener('popstate', () => {
        this.handleCurrentRoute(false);
      });

      // Listen for hashchange events as fallback
      window.addEventListener('hashchange', () => {
        this.handleCurrentRoute(false);
      });

      // Intercept internal link clicks to perform SPA navigation
      this.bindLinkInterception();

      // Handle the initial route on page load
      this.handleCurrentRoute(false);

      // Check if QR code scanner triggered vCard contact card download
      this.checkVCardTrigger();

      console.log('[PCM Router] Client-side SPA router & vCard engine initialized.');
    }

    /**
     * Checks if QR scan included vCard flag (?vcard=1, ?vcard=true, or ?action=save-contact)
     */
    checkVCardTrigger() {
      const searchParams = new URLSearchParams(window.location.search);
      const isVCardRequested = searchParams.has('vcard') ||
        searchParams.get('action') === 'save-contact' ||
        searchParams.get('download_vcard') === '1';

      if (isVCardRequested) {
        const customPhone = searchParams.get('phone') || '9383406185';
        const customName = searchParams.get('name') || 'PCM WAYANAD (Master Craftsman)';
        const details = { phone: customPhone, name: customName };

        // 1. Trigger the download prompt after brief delay for mobile browser readiness
        setTimeout(() => {
          triggerVCardDownload(details);
          showVCardPromptBanner(details);
        }, 350);
      }
    }

    /**
     * Resolves the current path from window.location
     */
    getCurrentPath() {
      const pathname = window.location.pathname.toLowerCase();
      // Remove trailing slash except for root
      if (pathname.length > 1 && pathname.endsWith('/')) {
        return pathname.slice(0, -1);
      }
      return pathname || '/';
    }

    isUserAuthenticated() {
      const pin = localStorage.getItem('pcm_active_site_pin');
      const phone = (localStorage.getItem('pcm_client_phone') || '').replace(/\D/g, '');
      return Boolean(pin || phone.length >= 10);
    }

    /**
     * Main route dispatcher
     */
    handleCurrentRoute(pushToHistory = true) {
      const path = this.getCurrentPath();
      const hash = window.location.hash.toLowerCase().replace('#', '');
      const searchParams = new URLSearchParams(window.location.search);

      // 1. Direct Portal Guard & Redirect if pathname is /portal or /portal/
      if (path === '/portal' || path === '/portal/' || path.startsWith('/portal/')) {
        if (!this.isUserAuthenticated()) {
          console.warn('[PCM Router] Unauthenticated direct access to /portal. Halting and prompting login.');
          this.openAuthTab('login');
          return;
        }
        if (!window.location.pathname.includes('portal.html')) {
          const targetUrl = 'portal.html' + window.location.search;
          window.location.replace(targetUrl);
          return;
        }
      }

      // 2. Query param based deep linking (e.g. ?site=pcm-ms-003 or ?tab=login or ?auth=login)
      const tabParam = searchParams.get('tab') || searchParams.get('auth');
      if (tabParam && ['login', 'register', 'newpin'].includes(tabParam)) {
        this.openAuthTab(tabParam);
      }

      const siteParam = searchParams.get('site') || searchParams.get('pin');
      if (siteParam) {
        this.handleSiteParam(siteParam);
      }

      // 3. Match defined routes
      const route = ROUTES[path];
      if (route) {
        this.executeRouteAction(route, path, pushToHistory);
        return;
      }

      // 4. Hash fallback (e.g. #calculator, #gallery)
      if (hash) {
        const hashTarget = document.getElementById(hash);
        if (hashTarget) {
          this.scrollToElement(hashTarget);
          return;
        }
      }

      // 5. Friendly SPA Fallback for any unknown route (Prevent 404)
      if (path !== '/' && path !== '/index.html') {
        console.warn(`[PCM Router] Direct path '${path}' not explicitly mapped. Rendering home view.`);
        const mainApp = document.getElementById('mainWebsiteApp');
        if (mainApp) mainApp.classList.remove('hidden');
      }
    }

    executeRouteAction(route, path, pushToHistory) {
      if (route.title) {
        document.title = route.title;
      }

      if (pushToHistory && window.location.pathname !== path) {
        window.history.pushState({ path }, route.title || '', path + window.location.search);
      }

      // Ensure main app container is unlocked and visible
      const mainApp = document.getElementById('mainWebsiteApp');
      if (mainApp) mainApp.classList.remove('hidden');

      switch (route.action) {
        case 'home':
          window.scrollTo({ top: 0, behavior: 'smooth' });
          break;

        case 'scroll':
          if (route.targetId) {
            const targetEl = document.getElementById(route.targetId);
            if (targetEl) {
              this.scrollToElement(targetEl);
            }
          }
          break;

        case 'authModal':
          this.openAuthTab(route.tab || 'login');
          break;

        case 'portalRedirect':
          if (!this.isUserAuthenticated()) {
            console.warn('[PCM Router] Access to /portal blocked: User not signed in. Opening Login Modal.');
            this.openAuthTab('login');
            alert('ദയവായി ക്ലയന്റ് പോർട്ടൽ തുറക്കാൻ നിങ്ങളുടെ 4-അക്ക സോഫ്റ്റ് പിൻ നൽകി ലോഗിൻ ചെയ്യുക (Please sign in with your PIN to access your project portal).');
          } else {
            window.location.replace('portal.html' + window.location.search);
          }
          break;
      }
    }

    scrollToElement(el) {
      setTimeout(() => {
        const headerOffset = 70;
        const elementPosition = el.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
      }, 100);
    }

    openAuthTab(tab) {
      if (typeof window.openAuthModal === 'function') {
        window.openAuthModal(tab);
      } else if (typeof window.switchAuthTab === 'function') {
        const modal = document.getElementById('websiteAuthModal');
        if (modal) modal.classList.remove('hidden');
        window.switchAuthTab(tab);
      }
    }

    isUserAuthenticated() {
      try {
        const pin = localStorage.getItem('pcm_active_site_pin');
        const user = localStorage.getItem('pcm_portal_user');
        const phone = localStorage.getItem('pcm_client_phone');
        const siteId = localStorage.getItem('pcm_client_site_id');
        const sessionUser = sessionStorage.getItem('pcm_authenticated_user');
        return !!(pin || user || phone || siteId || sessionUser);
      } catch (_e) {
        return false;
      }
    }

    handleSiteParam(siteCode) {
      const pinInput = document.getElementById('sitePinInput') || document.getElementById('loginPinInput');
      if (pinInput) {
        pinInput.value = siteCode;
      }
      if (typeof window.handleClientPhoneLookup === 'function') {
        const phoneInput = document.getElementById('loginPhoneInput');
        if (phoneInput && phoneInput.value) {
          window.handleClientPhoneLookup(phoneInput.value);
        }
      }
    }

    /**
     * Programmatic navigation
     */
    navigate(path) {
      const normalizedPath = (path.startsWith('/') ? path : '/' + path).toLowerCase();
      const route = ROUTES[normalizedPath] || { action: 'home' };
      this.executeRouteAction(route, normalizedPath, true);
    }

    /**
     * Intercepts clicks on local hrefs to provide smooth SPA navigation
     */
    bindLinkInterception() {
      document.addEventListener('click', (e) => {
        const link = e.target.closest('a');
        if (!link) return;

        const href = link.getAttribute('href');
        if (!href) return;

        // Skip external links, tel, mailto, whatsapp
        if (
          href.startsWith('http://') ||
          href.startsWith('https://') ||
          href.startsWith('tel:') ||
          href.startsWith('mailto:') ||
          href.startsWith('javascript:') ||
          link.getAttribute('target') === '_blank'
        ) {
          return;
        }

        // Hash links like #calculator
        if (href.startsWith('#')) {
          const targetId = href.substring(1);
          const targetEl = document.getElementById(targetId);
          if (targetEl) {
            e.preventDefault();
            this.scrollToElement(targetEl);
            const newPath = '/' + targetId;
            window.history.pushState({ path: newPath }, '', href);
          }
          return;
        }

        // Relative path links like /calculator, /gallery, /portal
        if (href.startsWith('/')) {
          const route = ROUTES[href.toLowerCase()];
          if (route) {
            e.preventDefault();
            this.navigate(href);
          }
        }
      });
    }
  }

  // Expose router & vCard functions globally
  window.pcmRouter = new ClientRouter();
  window.navigateTo = (path) => window.pcmRouter.navigate(path);
  window.downloadVCard = (details) => triggerVCardDownload(details);

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => window.pcmRouter.init());
  } else {
    window.pcmRouter.init();
  }
})();
