/**
 * PCM WAYANAD PORTAL - ROOM-WISE PROGRESS COMPONENT (< 95 lines)
 */

window.PortalRoomsComponent = {
  renderMount() {
    return `
      <div class="card" id="roomsProgressSection">
        <div class="card-head-pill head-progress flex items-center justify-between">
          <span class="font-bold">🏠 ROOM-BY-ROOM EXECUTION & COMPLETION</span>
          <span class="badge-realtime text-xs px-2 py-0.5 rounded bg-emerald-100 text-emerald-900 font-bold">REALTIME</span>
        </div>
        <div id="roomsEmptyState" class="text-sm text-gray-500 py-3 text-center">
          Loading site room specifications...
        </div>
        <div id="roomsContainer" class="grid grid-cols-1 md:grid-cols-2 gap-3 mt-3 hidden"></div>
      </div>
    `;
  },

  sync(row) {
    if (!row) return;
    const rooms = row.rooms_data || [];
    const container = document.getElementById('roomsContainer');
    const emptyState = document.getElementById('roomsEmptyState');
    if (!container || !emptyState) return;

    if (!Array.isArray(rooms) || rooms.length === 0) {
      container.classList.add('hidden');
      emptyState.classList.remove('hidden');
      emptyState.innerText = "Room specifications will appear here once finalized by engineering team.";
      return;
    }

    emptyState.classList.add('hidden');
    container.classList.remove('hidden');

    container.innerHTML = rooms.map((r, i) => {
      const isFin = r.is_finished === true || r.progress === 100;
      const progress = Math.min(100, Math.max(0, isFin ? 100 : (Number(r.progress) || 0)));
      const badgeClass = isFin ? 'bg-emerald-500 text-white' : (progress > 0 ? 'bg-amber-500 text-white' : 'bg-gray-200 text-gray-700');
      const badgeText = isFin ? '✓ COMPLETED' : (progress > 0 ? `${progress}% IN PROGRESS` : 'PENDING');
      const roomName = r.room_name || 'Room';
      const ceiling = r.ceiling_type || 'False Ceiling';
      const area = r.area_sqft ? `${r.area_sqft} sq.ft` : '';

      const fDone = isFin || r.framing_done === true;
      const bDone = isFin || r.boarding_done === true;
      const fnDone = isFin || r.finishing_done === true;
      const pDone = isFin || r.painting_done === true;

      const chip = (label, done) => `
        <span class="text-[10px] px-2 py-0.5 rounded-full font-bold flex items-center gap-1 ${done ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-500'}">
          ${done ? '✓' : '○'} ${label}
        </span>
      `;

      return `
        <div class="border border-gray-200 rounded-xl p-3 bg-white shadow-sm hover:shadow transition-shadow">
          <div class="flex items-center justify-between mb-2">
            <div>
              <h4 class="font-bold text-sm text-gray-800">${roomName}</h4>
              <p class="text-xs text-gray-400">${ceiling}${area ? ' • ' + area : ''}</p>
            </div>
            <span class="text-[10px] px-2 py-1 rounded font-black uppercase tracking-wider ${badgeClass}">
              ${badgeText}
            </span>
          </div>

          <div class="w-full bg-gray-100 rounded-full h-2 mb-2 overflow-hidden">
            <div class="h-2 rounded-full transition-all duration-500 ${isFin ? 'bg-emerald-500' : 'bg-amber-500'}" style="width: ${progress}%"></div>
          </div>

          <div class="flex items-center justify-between pt-2 border-t border-gray-100 mt-2">
            <div class="flex flex-wrap gap-1">${chip('Framing', fDone)}${chip('Boarding', bDone)}${chip('Finishing', fnDone)}${chip('Painting', pDone)}</div>
            <button type="button" class="text-[10px] font-bold text-amber-600 hover:text-amber-700 bg-amber-50 hover:bg-amber-100 px-2 py-0.5 rounded transition cursor-pointer" onclick="if(window.Portal3DComponent) window.Portal3DComponent.loadRoom(window.PortalState.portalData.rooms_data[${i}])">3D ➔</button>
          </div>
        </div>
      `;
    }).join('');
  }
};
