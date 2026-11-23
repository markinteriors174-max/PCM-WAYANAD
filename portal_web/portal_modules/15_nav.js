/**
 * PCM WAYANAD - Client Portal: Navigation & Mobile Menu Module
 */
(function (window) {
  'use strict';

  function ensurePortalLoaded() {
    if (typeof window.initRealtimePortalSync === 'function') window.initRealtimePortalSync();
  }

  function handlePortalNavClick() {
    const portalSec = document.getElementById('clientPortalSection');
    if (portalSec) {
      portalSec.scrollIntoView({ behavior: 'smooth' });
      ensurePortalLoaded();
    }
  }

  function toggleMobileMenu() {
    const menu = document.getElementById('mobileNavMenu');
    if (menu) menu.classList.toggle('hidden');
  }

  window.ensurePortalLoaded = ensurePortalLoaded;
  window.handlePortalNavClick = handlePortalNavClick;
  window.toggleMobileMenu = toggleMobileMenu;
})(window);
