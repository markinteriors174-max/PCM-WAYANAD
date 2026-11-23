/**
 * PCM WAYANAD - Client Portal: 5-Stage Milestones Progress Renderer Module
 */
(function (window) {
  'use strict';

  function renderPortalMilestones(record) {
    const container = document.getElementById('portalMilestonesContainer');
    const summaryEl = document.getElementById('portalMilestonesSummary');
    if (!container) return;

    let f = Math.min(100, Math.max(0, Number(record?.framing_progress ?? record?.progress_framing) || 0));
    let b = Math.min(100, Math.max(0, Number(record?.boarding_progress ?? record?.progress_boarding) || 0));
    let fn = Math.min(100, Math.max(0, Number(record?.finishing_progress ?? record?.progress_finishing) || 0));
    let p = Math.min(100, Math.max(0, Number(record?.painting_progress ?? record?.progress_painting) || 0));
    let c = Math.min(100, Math.max(0, Number(record?.cleanup_progress ?? record?.progress_cleanup) || 0));

    // Fallback: calculate from rooms_data if direct columns are 0
    if (f === 0 && b === 0 && fn === 0 && record?.rooms_data && Array.isArray(record.rooms_data) && record.rooms_data.length > 0) {
      const total = record.rooms_data.length;
      let fSum = 0, bSum = 0, fnSum = 0, pSum = 0;
      record.rooms_data.forEach(r => {
        if (r.is_finished) { fSum += 100; bSum += 100; fnSum += 100; pSum += 100; }
        else {
          fSum += (r.framing_done ? 100 : (Number(r.channel_work) || 0));
          bSum += (r.boarding_done ? 100 : (Number(r.board_work) || 0));
          fnSum += (r.finishing_done ? 100 : (Number(r.finishing_work) || 0));
          pSum += (r.painting_done ? 100 : 0);
        }
      });
      f = Math.round(fSum / total);
      b = Math.round(bSum / total);
      fn = Math.round(fnSum / total);
      p = Math.round(pSum / total);
    }

    const avg = Math.round((f + b + fn + p + c) / 5);
    if (summaryEl) summaryEl.textContent = `Overall Site Progress: ${avg}%`;

    const stages = [
      { title: '1. Laser Grid Framing', desc: 'GI perimeter & level alignment', pct: f },
      { title: '2. Gyproc Board Fixing', desc: '12.5mm Saint-Gobain Gyproc screwed', pct: b },
      { title: '3. Jointing & Paper Tape', desc: 'Compound coats & perforated tape', pct: fn },
      { title: '4. Primer & 2-Coat Emulsion', desc: 'Surface sanding & premium finish', pct: p },
      { title: '5. Cove Lighting & Handover', desc: 'Concealed LED strip lux test', pct: c }
    ];

    container.innerHTML = stages.map(st => {
      const isDone = st.pct === 100;
      const inProg = st.pct > 0 && st.pct < 100;
      const col = isDone ? 'text-emerald-400' : (inProg ? 'text-amber-400' : 'text-slate-500');
      const barCol = isDone ? 'bg-emerald-500' : (inProg ? 'bg-amber-500' : 'bg-slate-700');
      const icon = isDone ? '✓' : (inProg ? '⚙️' : '⏳');

      return `
        <div class="p-4 rounded-2xl bg-slate-900/80 border border-white/10 flex flex-col justify-between">
          <div>
            <div class="flex items-center justify-between gap-2">
              <h4 class="text-sm font-bold text-white">${st.title}</h4>
              <span class="text-xs font-black ${col}">${icon} ${st.pct}%</span>
            </div>
            <p class="text-[11px] text-slate-400 mt-1">${st.desc}</p>
          </div>
          <div class="w-full bg-slate-800 rounded-full h-1.5 mt-3 overflow-hidden">
            <div class="h-full ${barCol} transition-all duration-500" style="width: ${st.pct}%"></div>
          </div>
        </div>
      `;
    }).join('');
  }

  window.renderPortalMilestones = renderPortalMilestones;
})(window);
