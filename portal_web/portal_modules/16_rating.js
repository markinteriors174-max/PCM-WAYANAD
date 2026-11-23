/**
 * PCM WAYANAD - Client Portal: Dynamic Star Rating & Review Module
 */
(function (window) {
  'use strict';

  async function initDynamicStarRating() {
    const starsContainer = document.getElementById('portalStarRating');
    if (!starsContainer) return;

    const stars = starsContainer.querySelectorAll('.star-btn');
    stars.forEach((star, idx) => {
      star.addEventListener('click', async () => {
        const rating = idx + 1;
        stars.forEach((s, i) => {
          s.textContent = i < rating ? '★' : '☆';
          s.className = `star-btn text-2xl transition cursor-pointer ${i < rating ? 'text-amber-400' : 'text-slate-600'}`;
        });

        const statusEl = document.getElementById('ratingStatusMsg');
        if (statusEl) {
          statusEl.textContent = `Thank you! Rated ${rating}/5 Stars.`;
          statusEl.classList.remove('hidden');
        }

        const client = window.getSupabase ? window.getSupabase() : null;
        if (client) {
          const siteId = localStorage.getItem('pcm_client_site_id') || 'GUEST';
          try {
            await client.from('website_reviews').insert([{
              site_id: siteId,
              rating: rating,
              client_name: localStorage.getItem('pcm_portal_user') || 'Verified Client',
              created_at: new Date().toISOString()
            }]);
          } catch (_) {}
        }
      });
    });
  }

  window.initDynamicStarRating = initDynamicStarRating;
})(window);
