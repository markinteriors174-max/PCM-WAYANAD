/**
 * PCM WAYANAD - Client Portal: 3D Gypsum Designer Preview Module (< 100 lines)
 */
(function (window) {
  'use strict';

  function parseRoomPreset(cType = '') {
    const s = String(cType).toLowerCase();
    if (s.includes('box') || s.includes('multi') || s.includes('layer')) return 'multilayer';
    if (s.includes('island') || s.includes('floating')) return 'island';
    if (s.includes('step') || s.includes('border') || s.includes('perimeter')) return 'perimeter';
    return 'cove';
  }

  function loadRoom3D(r) {
    const iframe = document.getElementById('portal3DIframe');
    const badge = document.getElementById('portal3DRoomBadge');
    const fullBtn = document.getElementById('portal3DFullscreenBtn');
    if (!iframe) return;

    const sqft = Number(r.area_sqft || r.billable_sqft || 180);
    const sqM = sqft / 10.764;
    const w = Number(r.width_m) || (Number(r.width_ft) ? r.width_ft * 0.3048 : Math.sqrt(sqM / 1.3));
    const l = Number(r.length_m) || (Number(r.length_ft) ? r.length_ft * 0.3048 : w * 1.3);
    const gap = Number(r.cove_gap) || 0.5;
    const preset = parseRoomPreset(r.ceiling_type);
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
  }

  function renderPortal3DSection(rawRoomsData) {
    const tabsContainer = document.getElementById('portal3DRoomTabs');
    const iframe = document.getElementById('portal3DIframe');
    if (!tabsContainer || !iframe) return;

    let rooms = [];
    if (Array.isArray(rawRoomsData)) rooms = rawRoomsData;
    else if (typeof rawRoomsData === 'string' && rawRoomsData.trim().startsWith('[')) {
      try { rooms = JSON.parse(rawRoomsData); } catch (_) {}
    }
    if (rooms.length === 0) rooms = [{ room_name: 'Living Room', area_sqft: 220, ceiling_type: 'Cove Recess' }];

    tabsContainer.innerHTML = rooms.map((r, i) => `
      <button type="button" class="portal-3d-tab px-4 py-2 rounded-xl text-xs font-bold transition whitespace-nowrap cursor-pointer ${i === 0 ? 'bg-amber-500 text-slate-950 shadow-md' : 'bg-slate-800 text-slate-300 hover:text-white'}" data-idx="${i}">
        ${r.room_name || `Room ${i + 1}`}
      </button>
    `).join('');

    tabsContainer.querySelectorAll('.portal-3d-tab').forEach((btn) => {
      btn.addEventListener('click', () => {
        tabsContainer.querySelectorAll('.portal-3d-tab').forEach((b) => {
          b.className = 'portal-3d-tab px-4 py-2 rounded-xl text-xs font-bold transition whitespace-nowrap cursor-pointer bg-slate-800 text-slate-300 hover:text-white';
        });
        btn.className = 'portal-3d-tab px-4 py-2 rounded-xl text-xs font-bold transition whitespace-nowrap cursor-pointer bg-amber-500 text-slate-950 shadow-md';
        loadRoom3D(rooms[Number(btn.dataset.idx)]);
      });
    });

    loadRoom3D(rooms[0]);
  }

  function openGypsum3DModal(preset = 'cove') {
    const iframe = document.getElementById('portal3DIframe');
    if (iframe) iframe.src = `gypsum_3d_designer.html?preset=${preset}`;
  }

  window.renderPortal3DSection = renderPortal3DSection;
  window.loadRoom3D = loadRoom3D;
  window.openGypsum3DModal = openGypsum3DModal;
})(window);
