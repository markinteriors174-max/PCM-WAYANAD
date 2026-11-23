/**
 * PCM WAYANAD - Client Portal: Itemized Room Breakdown Renderer Module (< 80 lines)
 */
(function (window) {
  'use strict';

  function renderPortalRooms(rawRoomsData) {
    const container = document.getElementById('portalRoomsContainer');
    const totalRoomsBadge = document.getElementById('portalTotalRoomsBadge');
    const totalSqFtBadge = document.getElementById('portalTotalSqFtBadge');
    if (!container) return;

    let rooms = [];
    if (Array.isArray(rawRoomsData)) rooms = rawRoomsData;
    else if (typeof rawRoomsData === 'string' && rawRoomsData.trim().startsWith('[')) {
      try { rooms = JSON.parse(rawRoomsData); } catch (_) {}
    }

    if (rooms.length === 0) {
      container.innerHTML = '<div class="col-span-full py-8 text-center text-slate-500 text-xs">No itemized rooms recorded for this site yet.</div>';
      return;
    }

    let totalSqFt = 0;
    rooms.forEach(r => { totalSqFt += Number(r.area_sqft || r.billable_sqft || 0); });

    if (totalRoomsBadge) totalRoomsBadge.textContent = `${rooms.length} Rooms`;
    if (totalSqFtBadge) totalSqFtBadge.textContent = `${totalSqFt.toFixed(0)} Sq.Ft Total`;

    container.innerHTML = rooms.map(r => {
      const isFin = r.is_finished === true || Number(r.progress) === 100;
      const pct = isFin ? 100 : (Number(r.progress) || 0);
      const name = r.room_name || 'Room';
      const cType = r.ceiling_type || 'Gypsum False Ceiling';
      const area = Number(r.area_sqft || 0);
      const rEscaped = JSON.stringify(r).replace(/"/g, '&quot;');

      return `
        <div class="p-4 rounded-2xl ${isFin ? 'bg-emerald-950/20 border-emerald-500/40' : 'bg-slate-900/80 border-white/10'} border shadow-md flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between gap-2">
              <h4 class="text-sm font-bold text-white truncate">${name} ${isFin ? '✅' : ''}</h4>
              <span class="text-xs font-black ${isFin ? 'text-emerald-400' : 'text-amber-400'}">${isFin ? 'FINISHED' : `${pct}%`}</span>
            </div>
            <p class="text-[11px] text-slate-400 mt-1">${area > 0 ? `${area} sq.ft • ` : ''}${cType}</p>
          </div>
          <div class="mt-3">
            <div class="w-full bg-slate-800 rounded-full h-1.5 overflow-hidden">
              <div class="h-full ${isFin ? 'bg-emerald-500' : 'bg-amber-500'} transition-all duration-500" style="width: ${pct}%"></div>
            </div>
            <div class="mt-2 flex items-center justify-between text-[10px] text-slate-400">
              <span class="${r.framing_done || isFin ? 'text-emerald-400' : ''}">Frame: ${r.framing_done || isFin ? '✓' : '—'}</span>
              <span class="${r.boarding_done || isFin ? 'text-emerald-400' : ''}">Board: ${r.boarding_done || isFin ? '✓' : '—'}</span>
              <span class="${r.finishing_done || isFin ? 'text-emerald-400' : ''}">Joint: ${r.finishing_done || isFin ? '✓' : '—'}</span>
              <span class="${r.painting_done || isFin ? 'text-emerald-400' : ''}">Paint: ${r.painting_done || isFin ? '✓' : '—'}</span>
            </div>
            <div class="mt-3 pt-2 border-t border-white/5 flex justify-end">
              <button type="button" class="text-[10px] font-bold text-amber-400 hover:text-amber-300 bg-amber-400/10 hover:bg-amber-400/20 px-2.5 py-1 rounded-lg transition cursor-pointer flex items-center gap-1" onclick="if(typeof window.loadRoom3D==='function'){window.loadRoom3D(${rEscaped});document.getElementById('portal3DSection')?.scrollIntoView({behavior:'smooth'});}">
                <span>📐 View 3D</span>
              </button>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  window.renderPortalRooms = renderPortalRooms;
})(window);
