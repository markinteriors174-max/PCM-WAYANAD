/**
 * =========================================================================
 * PCM WAYANAD - CLIENT PORTAL & WEB STUDIO (MODULAR MASTER ENTRYPOINT)
 * =========================================================================
 */
(function () {
  'use strict';

  const MODULES = [
    'portal_modules/01_core.js',
    'portal_modules/02_slideshow.js',
    'portal_modules/03_gallery.js',
    'portal_modules/04_lightbox.js',
    'portal_modules/05_craftsmen.js',
    'portal_modules/06_before_after.js',
    'portal_modules/07_room_tabs.js',
    'portal_modules/08_sync.js',
    'portal_modules/09_render_rooms.js',
    'portal_modules/10_render_financials.js',
    'portal_modules/11_render_milestones.js',
    'portal_modules/12_chat.js',
    'portal_modules/13_realtime.js',
    'portal_modules/14_cms.js',
    'portal_modules/15_nav.js',
    'portal_modules/16_rating.js',
    'portal_modules/17_3d_preview.js'
  ];

  function loadScript(src) {
    return new Promise((resolve) => {
      const s = document.createElement('script');
      s.src = src;
      s.async = false;
      s.onload = () => resolve(true);
      s.onerror = () => { console.warn(`[PCM Portal] Module failed: ${src}`); resolve(false); };
      document.head.appendChild(s);
    });
  }

  async function bootstrapPortal() {
    for (const mod of MODULES) {
      await loadScript(mod);
    }

    if (typeof window.initGypsumDesignSlideshow === 'function') window.initGypsumDesignSlideshow();
    if (typeof window.loadLiveWebsiteGallery === 'function') window.loadLiveWebsiteGallery();
    if (typeof window.loadLiveCraftsmenTeam === 'function') window.loadLiveCraftsmenTeam();
    if (typeof window.initBeforeAfterSlider === 'function') window.initBeforeAfterSlider();
    if (typeof window.initRealtimePortalSync === 'function') window.initRealtimePortalSync();
    if (typeof window.syncLiveCmsData === 'function') window.syncLiveCmsData();
    if (typeof window.initDynamicStarRating === 'function') window.initDynamicStarRating();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrapPortal);
  } else {
    bootstrapPortal();
  }
})();
