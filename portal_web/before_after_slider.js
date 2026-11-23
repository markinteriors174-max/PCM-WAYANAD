/**
 * =========================================================================
 * PCM WAYANAD - DYNAMIC BEFORE & AFTER TRANSFORMATION SLIDER
 * Supports dynamic items (2, 3, 10, 20+) from Supabase website_cms.
 * Auto-cycling, smooth manual dragging, touch/pointer support, and presets.
 * Supports multiple instances on the page without conflict or freezing.
 * =========================================================================
 */

(function () {
  'use strict';

  // Default fallback slides
  const DEFAULT_SLIDES = [
    {
      id: 'default_1',
      title: 'Living Room Ceiling Transformation',
      content: 'Inspection of the bare concrete ceiling slab compared to the completed Saint-Gobain gypsum cove with concealed 3000K warm LED lighting.',
      beforeUrl: 'images/before.jpg',
      afterUrl: 'images/after.jpg'
    },
    {
      id: 'default_2',
      title: 'Drawing Hall & Living Area Ceiling',
      content: 'Expansive sense of luxury with sleek perimeter drops, concealed slim magnetic track light channels, and warm glow grooves.',
      beforeUrl: 'images/living.jpg',
      afterUrl: 'images/luxury_hall.jpg'
    },
    {
      id: 'default_3',
      title: 'Master Bedroom Architectural Ambience',
      content: 'Cozy ambience & zero-glare warmth. Perimeter cove lighting gently washes walls with soft amber glow without direct glare.',
      beforeUrl: 'images/dining.jpg',
      afterUrl: 'images/hero.jpg'
    }
  ];

  let slides = [...DEFAULT_SLIDES];
  let currentIndex = 0;
  let isDragging = false;
  let autoCycleTimer = null;
  let resumeTimer = null;
  let isHovered = false;

  // DOM Elements cache for main visualizer
  let mainContainer = null;
  let beforeWrapper = null;
  let beforeImg = null;
  let afterImg = null;
  let handle = null;
  let titleEl = null;
  let descEl = null;
  let tagEl = null;
  let dotsContainer = null;
  let cycleStatus = null;

  function getSupabaseClient() {
    if (window.supabaseClient) return window.supabaseClient;
    if (window.supabase && typeof window.supabase.createClient === 'function') {
      const url = window.PortalState?.SUPABASE_URL || 'https://acszqttuqdvpgmwbtndw.supabase.co';
      const key = window.PortalState?.SUPABASE_ANON || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjc3pxdHR1cWR2cGdtd2J0bmR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzODQ3NzksImV4cCI6MjA5OTk2MDc3OX0.8IohWgAWzeUromPsSE4YBu2ZTqn6wJZL7WYx637wBWE';
      try {
        window.supabaseClient = window.supabase.createClient(url, key);
        return window.supabaseClient;
      } catch (_) {}
    }
    return null;
  }

  async function fetchDynamicSlides() {
    const client = getSupabaseClient();
    if (!client || typeof client.from !== 'function') return;

    try {
      const { data, error } = await client
        .from('website_cms')
        .select('*')
        .eq('section_key', 'before_after')
        .order('updated_at', { ascending: false });

      if (!error && Array.isArray(data) && data.length > 0) {
        const fetched = data.map((item, idx) => ({
          id: item.id || `ba_${idx}`,
          title: (item.title || `Transformation Project ${idx + 1}`).trim(),
          content: (item.content || 'Architectural False Ceiling & Warm LED Transformation by PCM Wayanad.').trim(),
          beforeUrl: (item.image_url || 'images/before.jpg').trim(),
          afterUrl: (item.subtitle || 'images/after.jpg').trim()
        })).filter(s => s.beforeUrl.length > 0 && s.afterUrl.length > 0);

        if (fetched.length > 0) {
          // Merge fetched database items first, followed by default samples
          slides = [...fetched, ...DEFAULT_SLIDES];
          renderDots();
          renderSlide(currentIndex);
        }
      }
    } catch (e) {
      console.warn('[BeforeAfterSlider] Supabase fetch note:', e);
    }
  }

  function setSliderPosition(targetContainer, percent, smooth = false) {
    if (!targetContainer) return;
    percent = Math.max(0, Math.min(100, percent));

    const bWrap = targetContainer.querySelector('.ba-before-wrapper') || targetContainer.querySelector('#baBeforeWrapper') || targetContainer.querySelector('#ba-before-wrap');
    const bImg = targetContainer.querySelector('.ba-before-img') || targetContainer.querySelector('#baBeforeImg');
    const hLine = targetContainer.querySelector('.ba-handle') || targetContainer.querySelector('#baSliderHandle') || targetContainer.querySelector('#ba-divider');

    if (smooth) {
      if (bWrap) bWrap.style.transition = 'clip-path 0.35s cubic-bezier(0.4, 0, 0.2, 1), -webkit-clip-path 0.35s cubic-bezier(0.4, 0, 0.2, 1)';
      if (hLine) hLine.style.transition = 'left 0.35s cubic-bezier(0.4, 0, 0.2, 1)';
      setTimeout(() => {
        if (bWrap) bWrap.style.transition = 'none';
        if (hLine) hLine.style.transition = 'none';
      }, 360);
    } else {
      if (bWrap) bWrap.style.transition = 'none';
      if (hLine) hLine.style.transition = 'none';
    }

    targetContainer.style.setProperty('--slider-pos', percent + '%');

    if (bWrap) {
      bWrap.style.width = '100%';
      bWrap.style.clipPath = `inset(0 calc(100% - ${percent}%) 0 0)`;
      bWrap.style.webkitClipPath = `inset(0 calc(100% - ${percent}%) 0 0)`;
    }

    // Alignment fallback for browsers without clip-path support
    if (bImg && !window.CSS?.supports?.('clip-path', 'inset(0 50% 0 0)')) {
      if (bWrap) bWrap.style.width = percent + '%';
      bImg.style.width = targetContainer.offsetWidth + 'px';
      bImg.style.maxWidth = 'none';
    }

    if (hLine) {
      hLine.style.left = percent + '%';
    }
  }

  function calcPercentFromEvent(targetContainer, e) {
    if (!targetContainer) return 50;
    const rect = targetContainer.getBoundingClientRect();
    if (rect.width <= 0) return 50;

    let clientX = e.clientX;
    if (clientX === undefined && e.touches && e.touches.length > 0) {
      clientX = e.touches[0].clientX;
    }
    if (clientX === undefined) return 50;

    const offsetX = clientX - rect.left;
    const pct = (offsetX / rect.width) * 100;
    return Math.max(0, Math.min(100, pct));
  }

  function renderSlide(index) {
    if (slides.length === 0) return;
    currentIndex = ((index % slides.length) + slides.length) % slides.length;
    const slide = slides[currentIndex];

    if (titleEl) titleEl.innerText = slide.title;
    if (descEl) descEl.innerText = slide.content;
    if (tagEl) tagEl.innerText = `Transformation ${currentIndex + 1} of ${slides.length} • Kerala False Ceiling`;

    if (beforeImg) {
      beforeImg.style.opacity = '0.5';
      const bImg = new Image();
      bImg.onload = () => {
        beforeImg.src = slide.beforeUrl;
        beforeImg.style.opacity = '1';
      };
      bImg.onerror = () => {
        beforeImg.src = 'images/before.jpg';
        beforeImg.style.opacity = '1';
      };
      bImg.src = slide.beforeUrl;
    }

    if (afterImg) {
      afterImg.style.opacity = '0.5';
      const aImg = new Image();
      aImg.onload = () => {
        afterImg.src = slide.afterUrl;
        afterImg.style.opacity = '1';
      };
      aImg.onerror = () => {
        afterImg.src = 'images/after.jpg';
        afterImg.style.opacity = '1';
      };
      aImg.src = slide.afterUrl;
    }

    // Reset slider to center smoothly
    setSliderPosition(mainContainer, 50, true);
    updateActiveDot();
  }

  function renderDots() {
    if (!dotsContainer) return;
    dotsContainer.innerHTML = '';
    slides.forEach((_, idx) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = `ba-dot-indicator h-2.5 rounded-full transition-all duration-300 ${idx === currentIndex ? 'w-7 bg-amber-400' : 'w-2.5 bg-slate-700 hover:bg-slate-500'}`;
      btn.setAttribute('aria-label', `Go to Transformation ${idx + 1}`);
      btn.onclick = () => {
        renderSlide(idx);
        restartAutoCycle();
      };
      dotsContainer.appendChild(btn);
    });
  }

  function updateActiveDot() {
    if (!dotsContainer) return;
    const dots = dotsContainer.querySelectorAll('.ba-dot-indicator');
    dots.forEach((dot, idx) => {
      if (idx === currentIndex) {
        dot.className = 'ba-dot-indicator h-2.5 rounded-full transition-all duration-300 w-7 bg-amber-400';
      } else {
        dot.className = 'ba-dot-indicator h-2.5 rounded-full transition-all duration-300 w-2.5 bg-slate-700 hover:bg-slate-500';
      }
    });
  }

  function nextSlide() {
    renderSlide(currentIndex + 1);
  }

  function prevSlide() {
    renderSlide(currentIndex - 1);
  }

  function startAutoCycle() {
    stopAutoCycle();
    if (slides.length <= 1) return;
    autoCycleTimer = setInterval(() => {
      if (!isDragging && !isHovered) {
        nextSlide();
      }
    }, 6000);
    if (cycleStatus) cycleStatus.innerText = '● Auto-Cycling Active';
  }

  function stopAutoCycle() {
    if (autoCycleTimer) {
      clearInterval(autoCycleTimer);
      autoCycleTimer = null;
    }
    if (cycleStatus) cycleStatus.innerText = '⏸ Paused (Manual Control)';
  }

  function restartAutoCycle() {
    stopAutoCycle();
    if (resumeTimer) clearTimeout(resumeTimer);
    resumeTimer = setTimeout(() => {
      if (!isDragging && !isHovered) {
        startAutoCycle();
      }
    }, 4000);
  }

  function attachDragToContainer(elem) {
    if (!elem || elem.dataset.baBound === 'true') return;
    elem.dataset.baBound = 'true';

    setSliderPosition(elem, 50, false);

    const onPointerDown = (e) => {
      isDragging = true;
      stopAutoCycle();
      if (elem.setPointerCapture && e.pointerId !== undefined) {
        try { elem.setPointerCapture(e.pointerId); } catch (_) {}
      }
      const pct = calcPercentFromEvent(elem, e);
      setSliderPosition(elem, pct, false);
    };

    const onPointerMove = (e) => {
      if (!isDragging) return;
      const pct = calcPercentFromEvent(elem, e);
      setSliderPosition(elem, pct, false);
    };

    const onPointerUp = (e) => {
      if (!isDragging) return;
      isDragging = false;
      if (elem.releasePointerCapture && e.pointerId !== undefined) {
        try { elem.releasePointerCapture(e.pointerId); } catch (_) {}
      }
      restartAutoCycle();
    };

    elem.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('pointermove', onPointerMove, { passive: true });
    window.addEventListener('pointerup', onPointerUp);
    window.addEventListener('pointercancel', onPointerUp);

    // Touch support fallback
    elem.addEventListener('touchstart', (e) => {
      isDragging = true;
      stopAutoCycle();
      const pct = calcPercentFromEvent(elem, e);
      setSliderPosition(elem, pct, false);
    }, { passive: true });

    window.addEventListener('touchmove', (e) => {
      if (!isDragging) return;
      const pct = calcPercentFromEvent(elem, e);
      setSliderPosition(elem, pct, false);
    }, { passive: true });

    window.addEventListener('touchend', () => {
      if (!isDragging) return;
      isDragging = false;
      restartAutoCycle();
    });

    // Hover auto-pause
    elem.addEventListener('mouseenter', () => {
      isHovered = true;
      stopAutoCycle();
    });

    elem.addEventListener('mouseleave', () => {
      isHovered = false;
      if (!isDragging) restartAutoCycle();
    });
  }

  function init() {
    mainContainer = document.getElementById('baSliderContainer') || document.getElementById('ba-viewer') || document.querySelector('.ba-container');
    beforeWrapper = document.getElementById('baBeforeWrapper') || document.getElementById('ba-before-wrap') || mainContainer?.querySelector('.ba-before-wrapper');
    beforeImg = document.getElementById('baBeforeImg') || mainContainer?.querySelector('.ba-before-img');
    afterImg = document.getElementById('baAfterImg') || mainContainer?.querySelector('.ba-after-img');
    handle = document.getElementById('baSliderHandle') || document.getElementById('ba-divider') || mainContainer?.querySelector('.ba-handle');
    titleEl = document.getElementById('baActiveTitle');
    descEl = document.getElementById('baActiveDesc');
    tagEl = document.getElementById('baActiveTag');
    dotsContainer = document.getElementById('baDotsContainer');
    cycleStatus = document.getElementById('baCycleStatus');

    // Attach drag listener to all .ba-container elements found on page
    const allContainers = document.querySelectorAll('.ba-container');
    allContainers.forEach(c => attachDragToContainer(c));

    if (mainContainer) {
      renderDots();
      renderSlide(0);
      startAutoCycle();
    }

    // Fetch dynamic items from Supabase in background
    fetchDynamicSlides();
  }

  // Global helper functions
  window.baNextSlide = () => {
    nextSlide();
    restartAutoCycle();
  };

  window.baPrevSlide = () => {
    prevSlide();
    restartAutoCycle();
  };

  window.baSetPercent = (pct) => {
    setSliderPosition(mainContainer, pct, true);
    restartAutoCycle();
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
