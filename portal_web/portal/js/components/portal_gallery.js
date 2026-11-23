/**
 * PCM WAYANAD PORTAL - DESIGN PORTFOLIO & GALLERY COMPONENT
 * Renders uploaded gypsum ceiling photos with verified watermark details,
 * title, date, and interactive lightbox preview.
 */

window.PortalGalleryComponent = {
  renderMount() {
    return `
      <div class="card" id="portfolioGallerySection">
        <div class="card-head-pill head-gallery flex items-center justify-between">
          <div class="flex items-center gap-2">
            <span>📸</span>
            <span class="font-black text-xs uppercase tracking-wider text-slate-900">DESIGN PORTFOLIO & NIGHT GALLERY</span>
          </div>
          <span class="badge-watermark text-[10px] font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">VERIFIED WATERMARK</span>
        </div>
        <div class="gallery-grid mt-3" id="portfolioGalleryContainer">
          <div class="gallery-empty py-8 text-center text-slate-400 text-xs">
            Loading site photos & ceiling portfolio...
          </div>
        </div>
      </div>
    `;
  },

  render(row) {
    const container = document.getElementById('portfolioGalleryContainer');
    if (!container || !row) return;

    // Merge and deduplicate all photo sources
    const photoMap = new Map();

    const addPhoto = (url, title, date, timestamp) => {
      if (!url || typeof url !== 'string') return;
      const cleanUrl = url.trim();
      if (!cleanUrl || !cleanUrl.startsWith('http')) return;
      if (!photoMap.has(cleanUrl)) {
        photoMap.set(cleanUrl, {
          url: cleanUrl,
          title: title || 'Gypsum False Ceiling',
          date: date || 'Verified',
          timestamp: timestamp || row.updated_at
        });
      }
    };

    // 1. Structured photos list
    if (Array.isArray(row.photos)) {
      row.photos.forEach(p => {
        if (typeof p === 'string') {
          addPhoto(p, 'Site Progress Photo');
        } else if (p && typeof p === 'object') {
          addPhoto(p.url || p.image_url, p.title || p.roomName, p.date, p.timestamp);
        }
      });
    }

    // 2. Portfolio gallery URLs
    if (Array.isArray(row.portfolio_gallery)) {
      row.portfolio_gallery.forEach((item, i) => {
        if (typeof item === 'string') {
          addPhoto(item, `Ceiling Design #${i + 1}`);
        } else if (item && typeof item === 'object') {
          addPhoto(item.url || item.image_url, item.title, item.date, item.timestamp);
        }
      });
    }

    // 3. Site photos array
    if (Array.isArray(row.site_photos)) {
      row.site_photos.forEach((u, i) => {
        addPhoto(typeof u === 'string' ? u : (u?.url || u?.image_url), `Site Progress #${i + 1}`);
      });
    }

    // 4. Room-wise photos
    if (Array.isArray(row.rooms_data)) {
      row.rooms_data.forEach(r => {
        if (Array.isArray(r.photos)) {
          r.photos.forEach(u => addPhoto(u, `${r.room_name || 'Room'} Ceiling`));
        }
      });
    }

    const photos = Array.from(photoMap.values());

    if (photos.length === 0) {
      container.innerHTML = `
        <div class="gallery-empty col-span-2 py-8 text-center text-slate-400 text-xs">
          📸 No site photos uploaded yet. New photos added from PCM Admin App appear here in real-time.
        </div>
      `;
      return;
    }

    container.innerHTML = photos.map((item, idx) => {
      const title = item.title || `False Ceiling Detail #${idx + 1}`;
      const timeStr = item.date || (item.timestamp
        ? new Date(item.timestamp).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
        : 'Verified');

      return `
        <div class="gallery-card group relative overflow-hidden rounded-2xl border border-slate-200 bg-slate-900 shadow-md hover:shadow-xl transition-all duration-300">
          <div class="gallery-img-wrap relative w-full h-40 overflow-hidden bg-slate-950">
            <img src="${item.url}" alt="${title}" class="gallery-img w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 cursor-pointer" loading="lazy" onclick="window.PortalGalleryComponent.openLightbox('${item.url}', '${title.replace(/'/g, "\\'")}', '${timeStr}')">
            
            <!-- OFFICIAL PCM WATERMARK BADGE OVERLAY -->
            <div class="absolute top-2 left-2 z-10 flex items-center gap-1 px-2 py-0.5 rounded bg-black/75 backdrop-blur-md border border-amber-500/40 text-[9px] font-black text-amber-400 tracking-wider">
              <span>🛡️</span>
              <span>PCM WAYANAD</span>
            </div>

            <!-- WATERMARK BOTTOM STAMP -->
            <span class="gallery-badge absolute bottom-2 right-2 z-10 px-2 py-0.5 rounded bg-slate-950/80 backdrop-blur-md text-[8px] font-bold text-white tracking-widest uppercase border border-white/10">
              ORIGINAL WORK
            </span>
          </div>

          <div class="gallery-info p-3 bg-white border-t border-slate-100">
            <div class="gallery-title text-xs font-black text-slate-900 truncate">${title}</div>
            <div class="gallery-time text-[10px] font-bold text-slate-500 mt-1 flex items-center justify-between">
              <span>📅 ${timeStr}</span>
              <span class="text-emerald-700 font-extrabold text-[9px]">VERIFIED ✓</span>
            </div>
          </div>
        </div>
      `;
    }).join('');
  },

  openLightbox(url, title, timeStr) {
    let overlay = document.getElementById('portalPhotoLightboxModal');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'portalPhotoLightboxModal';
      overlay.className = 'fixed inset-0 z-50 bg-slate-950/95 backdrop-blur-xl flex flex-col items-center justify-center p-4';
      overlay.innerHTML = `
        <button onclick="document.getElementById('portalPhotoLightboxModal').classList.add('hidden')" class="absolute top-4 right-4 text-white text-3xl font-black w-10 h-10 rounded-full bg-slate-800/80 flex items-center justify-center hover:bg-rose-600 transition cursor-pointer z-50">&times;</button>
        <div class="max-w-3xl w-full flex flex-col items-center">
          <div class="relative rounded-2xl overflow-hidden shadow-2xl border border-amber-500/30 bg-black">
            <img id="portalLightboxImg" src="" alt="Ceiling Photo" class="max-h-[75vh] w-auto object-contain">
            <div class="absolute top-3 left-3 bg-black/80 text-amber-400 text-xs font-black px-3 py-1 rounded-lg border border-amber-500/40 backdrop-blur-md flex items-center gap-1.5">
              <span>🛡️</span>
              <span>PCM WAYANAD ARCHITECTURAL CEILING</span>
            </div>
          </div>
          <div class="mt-3 text-center">
            <h4 id="portalLightboxTitle" class="text-white font-black text-sm sm:text-base"></h4>
            <p id="portalLightboxSub" class="text-slate-400 text-xs mt-0.5 font-bold"></p>
          </div>
        </div>
      `;
      document.body.appendChild(overlay);
    }

    const img = document.getElementById('portalLightboxImg');
    const t = document.getElementById('portalLightboxTitle');
    const s = document.getElementById('portalLightboxSub');
    if (img) img.src = url;
    if (t) t.innerText = title;
    if (s) s.innerText = `Recorded Site Progress • ${timeStr || 'Verified'}`;
    overlay.classList.remove('hidden');
  }
};
