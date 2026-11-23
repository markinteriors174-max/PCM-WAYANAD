/**
 * PCM WAYANAD - Client Portal: Dynamic Gypsum Design Slideshow Module
 */
(function (window) {
  'use strict';

  let slideshowDesigns = [];
  let currentSlideIndex = 0;
  let slideshowTimer = null;
  let isSlideshowPaused = false;

  async function initGypsumDesignSlideshow() {
    const container = document.getElementById('gypsumSlideshowContainer');
    const track = document.getElementById('gypsumSlidesTrack');
    const loader = document.getElementById('slideshowLoader');
    const dotsContainer = document.getElementById('slideshowDotsContainer');
    if (!container || !track) return;

    if (loader) loader.classList.remove('hidden');
    const client = window.getSupabase ? window.getSupabase() : null;
    let items = [];

    if (client && typeof client.from === 'function') {
      try {
        const { data: cmsItems } = await client.from('website_cms').select('*')
          .or('section_key.eq.gallery_card,section_key.eq.gallery_item,section_key.eq.gallery,section_key.eq.completed_project,section_key.eq.slideshow')
          .order('updated_at', { ascending: false });
        if (cmsItems && cmsItems.length > 0) {
          items = cmsItems.map(i => ({ id: i.id, title: i.title || 'Master Gypsum Ceiling', tag: i.subtitle || 'PCM Original', image_url: i.image_url || i.image || '', likes: Number(i.likes_count) || 0 }))
            .filter(i => i.image_url && i.image_url.startsWith('http') && !i.image_url.includes('unsplash.com'));
        }
      } catch (err) { console.warn('Slideshow fetch notice:', err); }
    }
    if (loader) loader.classList.add('hidden');
    slideshowDesigns = items;

    if (slideshowDesigns.length === 0) {
      track.innerHTML = '<div class="h-full flex items-center justify-center p-6 text-slate-400 text-xs">✨ Live design uploads from PCM Control Hub will appear here.</div>';
      if (dotsContainer) dotsContainer.innerHTML = '';
      return;
    }

    track.innerHTML = slideshowDesigns.map((d, idx) => `
      <div id="gypsumSlide_${idx}" class="absolute inset-0 transition-opacity duration-700 ${idx === 0 ? 'opacity-100 z-10' : 'opacity-0 z-0 pointer-events-none'}">
        <img src="${d.image_url}" alt="${d.title}" class="w-full h-full object-cover object-center brightness-[0.82] contrast-[1.05]">
        <div class="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/30 to-transparent"></div>
        <div class="absolute bottom-6 left-6 right-6 z-20 flex justify-between items-end gap-3 pointer-events-auto">
          <div><span class="px-3 py-1 rounded-full bg-amber-500/90 text-slate-950 font-black text-[10px] uppercase">${d.tag}</span><h3 class="text-xl font-black text-white mt-1">${d.title}</h3></div>
          <button type="button" onclick="openPhotoLightbox('${d.image_url}', '${d.title.replaceAll("'", "\\'")}')" class="px-3.5 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs transition">🔍 Full View</button>
        </div>
      </div>
    `).join('');

    if (dotsContainer) {
      dotsContainer.innerHTML = slideshowDesigns.map((_, idx) => `<button type="button" onclick="goToGypsumSlide(${idx})" class="w-2.5 h-2.5 rounded-full transition-all ${idx === 0 ? 'bg-amber-400 w-6' : 'bg-white/40'}"></button>`).join('');
    }

    currentSlideIndex = 0;
    if (slideshowTimer) clearInterval(slideshowTimer);
    slideshowTimer = setInterval(() => { if (!isSlideshowPaused && slideshowDesigns.length > 1) nextGypsumSlide(); }, 4500);

    container.onmouseenter = () => { isSlideshowPaused = true; };
    container.onmouseleave = () => { isSlideshowPaused = false; };
  }

  function goToGypsumSlide(idx) {
    if (!slideshowDesigns[idx]) return;
    document.querySelectorAll('[id^="gypsumSlide_"]').forEach((el, i) => {
      el.className = `absolute inset-0 transition-opacity duration-700 ${i === idx ? 'opacity-100 z-10' : 'opacity-0 z-0 pointer-events-none'}`;
    });
    currentSlideIndex = idx;
  }

  function nextGypsumSlide() { goToGypsumSlide((currentSlideIndex + 1) % slideshowDesigns.length); }
  function prevGypsumSlide() { goToGypsumSlide((currentSlideIndex - 1 + slideshowDesigns.length) % slideshowDesigns.length); }

  window.initGypsumDesignSlideshow = initGypsumDesignSlideshow;
  window.goToGypsumSlide = goToGypsumSlide;
  window.nextGypsumSlide = nextGypsumSlide;
  window.prevGypsumSlide = prevGypsumSlide;
})(window);
