/**
 * PCM WAYANAD - Client Portal: Room Architecture Tabs Module
 */
(function (window) {
  'use strict';

  function selectRoomTab(roomKey) {
    document.querySelectorAll('.room-tab-btn').forEach(btn => {
      const active = btn.dataset.room === roomKey;
      btn.className = `room-tab-btn px-4 py-2 rounded-xl text-xs font-bold transition whitespace-nowrap ${active ? 'bg-amber-500 text-slate-950 shadow-md' : 'bg-slate-800/80 text-slate-400 hover:text-white'}`;
    });

    document.querySelectorAll('.room-detail-card').forEach(card => {
      if (roomKey === 'all' || card.dataset.room === roomKey) {
        card.classList.remove('hidden');
      } else {
        card.classList.add('hidden');
      }
    });
  }

  window.selectRoomTab = selectRoomTab;
})(window);
