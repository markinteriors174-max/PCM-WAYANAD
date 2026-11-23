/**
 * PCM WAYANAD - Client Portal: Before/After Slider Module
 */
(function (window) {
  'use strict';

  function initBeforeAfterSlider() {
    const container = document.getElementById('beforeAfterContainer');
    const afterImg = document.getElementById('beforeAfterOverlay');
    const handle = document.getElementById('beforeAfterHandle');
    if (!container || !afterImg || !handle) return;

    let isDragging = false;

    function setPosition(x) {
      const rect = container.getBoundingClientRect();
      const clampedX = Math.max(0, Math.min(x - rect.left, rect.width));
      const pct = (clampedX / rect.width) * 100;
      afterImg.style.clipPath = `polygon(${pct}% 0, 100% 0, 100% 100%, ${pct}% 100%)`;
      handle.style.left = `${pct}%`;
    }

    container.addEventListener('mousedown', (e) => { isDragging = true; setPosition(e.clientX); });
    window.addEventListener('mouseup', () => { isDragging = false; });
    window.addEventListener('mousemove', (e) => { if (isDragging) setPosition(e.clientX); });

    container.addEventListener('touchstart', (e) => { isDragging = true; setPosition(e.touches[0].clientX); });
    window.addEventListener('touchend', () => { isDragging = false; });
    window.addEventListener('touchmove', (e) => { if (isDragging) setPosition(e.touches[0].clientX); });
  }

  window.initBeforeAfterSlider = initBeforeAfterSlider;
})(window);
