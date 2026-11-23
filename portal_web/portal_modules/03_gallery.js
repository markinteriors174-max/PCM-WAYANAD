/**
 * PCM WAYANAD - Client Portal: Live Website Gallery & Price Inquiry Module
 */
(function (window) {
  'use strict';

  async function loadLiveWebsiteGallery() {
    const grid = document.getElementById('liveGalleryGrid');
    if (!grid) return;
    const client = window.getSupabase ? window.getSupabase() : null;
    let photos = [];

    if (client) {
      try {
        const { data } = await client.from('website_cms').select('*')
          .or('section_key.eq.gallery_card,section_key.eq.gallery_item,section_key.eq.gallery')
          .order('updated_at', { ascending: false });
        if (data && data.length > 0) {
          photos = data.map(p => ({ id: p.id, title: p.title || 'Wayanad Ceiling', category: p.subtitle || p.category || 'Living Area', image_url: p.image_url || p.image || '', likes_count: Number(p.likes_count) || 0 }))
            .filter(p => p.image_url && p.image_url.startsWith('http') && !p.image_url.includes('unsplash.com'));
        }
      } catch (e) { console.warn('Gallery load notice:', e); }
    }

    if (photos.length === 0) {
      grid.innerHTML = '<div class="col-span-full text-center py-10 text-slate-500 text-xs">No gallery designs uploaded yet.</div>';
      return;
    }
    grid.innerHTML = photos.map(p => renderGalleryCardHtml(p)).join('');
  }

  function renderGalleryCardHtml(photo) {
    const escapedTitle = (photo.title || '').replaceAll("'", "\\'");
    return `
      <div class="group relative rounded-2xl overflow-hidden bg-slate-900/80 border border-white/10 shadow-lg hover:border-amber-500/50 transition duration-300 flex flex-col">
        <div class="relative aspect-[4/3] overflow-hidden cursor-pointer" onclick="openPhotoLightbox('${photo.image_url}', '${escapedTitle}')">
          <img src="${photo.image_url}" alt="${photo.title}" class="w-full h-full object-cover group-hover:scale-105 transition duration-500">
          <span class="absolute top-3 left-3 px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md text-amber-400 font-bold text-[10px] uppercase border border-white/10">${photo.category}</span>
        </div>
        <div class="p-4 flex flex-col justify-between flex-1">
          <h4 class="text-sm font-bold text-white truncate">${photo.title}</h4>
          <div class="mt-3 flex items-center justify-between gap-2">
            <button type="button" onclick="votePhoto('${photo.id}', 'like')" class="text-xs text-slate-400 hover:text-amber-400 transition flex items-center gap-1">👍 <span id="likeCount_${photo.id}">${photo.likes_count}</span></button>
            <button type="button" onclick="openPriceEnquiryModal('${photo.id}', '${photo.image_url}')" class="px-2.5 py-1 rounded-lg bg-amber-500/20 text-amber-400 hover:bg-amber-500 hover:text-slate-950 font-bold text-[11px] transition">Get Price</button>
          </div>
        </div>
      </div>
    `;
  }

  async function votePhoto(photoId, type) {
    const countEl = document.getElementById(`likeCount_${photoId}`);
    if (countEl) countEl.textContent = Number(countEl.textContent || 0) + 1;
    const client = window.getSupabase ? window.getSupabase() : null;
    if (client) {
      try {
        const { data } = await client.from('website_cms').select('likes_count').eq('id', photoId).maybeSingle();
        const current = (data && data.likes_count) || 0;
        await client.from('website_cms').update({ likes_count: current + 1 }).eq('id', photoId);
      } catch (_) {}
    }
  }

  function openPriceEnquiryModal(photoId, photoUrl) {
    const modal = document.getElementById('priceEnquiryModal');
    if (modal) {
      const img = document.getElementById('enquiryModalImg');
      if (img) img.src = photoUrl;
      modal.classList.remove('hidden');
    }
  }

  window.loadLiveWebsiteGallery = loadLiveWebsiteGallery;
  window.renderGalleryCardHtml = renderGalleryCardHtml;
  window.votePhoto = votePhoto;
  window.openPriceEnquiryModal = openPriceEnquiryModal;
})(window);
