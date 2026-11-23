/**
 * PCM WAYANAD PORTAL - 3D GYPSUM PREVIEW COMPONENT (< 95 lines)
 */

window.Portal3DComponent = {
  renderMount() {
    return `
      <div class="card" id="studio3DSection">
        <div class="card-head-pill head-details flex items-center justify-between">
          <span class="font-bold">📐 3D GYPSUM CEILING ARCHITECTURAL STUDIO</span>
          <div class="flex items-center gap-2">
            <span id="standalone3DRoomBadge" class="text-xs px-2 py-0.5 rounded bg-amber-100 text-amber-900 font-bold">Loading...</span>
            <a id="standalone3DFullscreen" href="gypsum_3d_designer.html" target="_blank" class="text-xs px-2.5 py-1 rounded-lg bg-slate-800 text-white font-bold hover:bg-slate-700 transition">⤢ Fullscreen</a>
          </div>
        </div>
        <p class="text-xs text-gray-500 mt-2 mb-3">
          Explore your customized false ceiling design, ambient cove lighting, and framing in interactive 3D.
        </p>
        <div id="standalone3DRoomTabs" class="flex gap-2 overflow-x-auto pb-2 mb-3"></div>
        <div class="relative w-full rounded-xl overflow-hidden border border-gray-200 shadow bg-slate-950 h-[440px]">
          <iframe id="standalone3DIframe" src="gypsum_3d_designer.html" class="w-full h-full border-none" title="PCM 3D Ceiling Studio"></iframe>
        </div>
      </div>
    `;
  },

  parsePreset(cType = '') {
    const s = String(cType).toLowerCase();
    if (s.includes('box') || s.includes('multi') || s.includes('layer')) return 'multilayer';
    if (s.includes('island') || s.includes('floating')) return 'island';
    if (s.includes('step') || s.includes('border') || s.includes('perimeter')) return 'perimeter';
    return 'cove';
  },

  loadRoom(r) {
    const iframe = document.getElementById('standalone3DIframe');
    const badge = document.getElementById('standalone3DRoomBadge');
    const fullBtn = document.getElementById('standalone3DFullscreen');
    if (!iframe) return;

    const sqft = Number(r.area_sqft || r.billable_sqft || 180);
    const sqM = sqft / 10.764;
    const w = Number(r.width_m) || (Number(r.width_ft) ? r.width_ft * 0.3048 : Math.sqrt(sqM / 1.3));
    const l = Number(r.length_m) || (Number(r.length_ft) ? r.length_ft * 0.3048 : w * 1.3);
    const gap = Number(r.cove_gap) || 0.5;
    const preset = this.parsePreset(r.ceiling_type);
    const name = r.room_name || 'Room';

    if (badge) badge.textContent = `${name} (${sqft.toFixed(0)} sq.ft)`;
    const q = `gypsum_3d_designer.html?room=${encodeURIComponent(name)}&l=${l.toFixed(1)}&w=${w.toFixed(1)}&gap=${gap.toFixed(1)}&preset=${preset}`;
    if (fullBtn) fullBtn.href = q;

    try {
      if (iframe.contentWindow) {
        iframe.contentWindow.postMessage({ type: 'PCM_SET_ROOM', room: name, length: l, width: w, gap, preset }, '*');
      }
    } catch (_) {}
    if (!iframe.src || !iframe.src.includes('gypsum_3d_designer.html')) {
      iframe.src = q;
    }
  },

  sync(row) {
    if (!row) return;
    const raw = row.rooms_data;
    let rooms = [];
    if (Array.isArray(raw)) rooms = raw;
    else if (typeof raw === 'string' && raw.trim().startsWith('[')) {
      try { rooms = JSON.parse(raw); } catch (_) {}
    }
    if (rooms.length === 0) rooms = [{ room_name: 'Living Room', area_sqft: 220, ceiling_type: 'Cove Recess' }];

    const tabs = document.getElementById('standalone3DRoomTabs');
    if (!tabs) return;

    tabs.innerHTML = rooms.map((r, i) => `
      <button type="button" class="portal-std-tab text-xs px-3 py-1.5 rounded-lg font-bold transition whitespace-nowrap cursor-pointer ${i === 0 ? 'bg-amber-500 text-slate-900 shadow' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}" data-idx="${i}">
        ${r.room_name || `Room ${i + 1}`}
      </button>
    `).join('');

    tabs.querySelectorAll('.portal-std-tab').forEach(btn => {
      btn.addEventListener('click', () => {
        tabs.querySelectorAll('.portal-std-tab').forEach(b => {
          b.className = 'portal-std-tab text-xs px-3 py-1.5 rounded-lg font-bold transition whitespace-nowrap cursor-pointer bg-gray-100 text-gray-700 hover:bg-gray-200';
        });
        btn.className = 'portal-std-tab text-xs px-3 py-1.5 rounded-lg font-bold transition whitespace-nowrap cursor-pointer bg-amber-500 text-slate-900 shadow';
        this.loadRoom(rooms[Number(btn.dataset.idx)]);
      });
    });

    this.loadRoom(rooms[0]);
  }
};
