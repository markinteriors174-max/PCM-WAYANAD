/**
 * PCM WAYANAD - Client Portal: Fullscreen Photo Lightbox Module
 */
(function (window) {
  'use strict';

  function openPhotoLightbox(imgUrl, title) {
    const lightbox = document.getElementById('portalPhotoLightbox');
    const img = document.getElementById('lightboxImg');
    const caption = document.getElementById('lightboxCaption');

    if (!lightbox || !img) {
      window.open(imgUrl, '_blank');
      return;
    }

    img.src = imgUrl;
    if (caption) caption.textContent = title || 'PCM Gypsum False Ceiling Work';
    lightbox.classList.remove('hidden');
    lightbox.classList.add('flex');
    document.body.style.overflow = 'hidden';
  }

  function closePhotoLightbox() {
    const lightbox = document.getElementById('portalPhotoLightbox');
    if (lightbox) {
      lightbox.classList.add('hidden');
      lightbox.classList.remove('flex');
      document.body.style.overflow = '';
    }
  }

  window.openPhotoLightbox = openPhotoLightbox;
  window.closePhotoLightbox = closePhotoLightbox;
})(window);
