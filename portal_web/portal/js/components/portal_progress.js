/**
 * PCM WAYANAD PORTAL - PROGRESS COMPONENT (< 75 lines)
 */

window.PortalProgressComponent = {
  renderMount() {
    return `
      <div class="card">
        <div class="card-head-pill head-progress">
          <span>🔥 LIVE PROGRESS TRACKER</span>
          <span class="badge-realtime">REALTIME</span>
        </div>
        <div class="prog-item">
          <div class="prog-txt-row"><span>Framing / Channel Work</span><span class="prog-val-bold" id="txtFraming">0%</span></div>
          <div class="bar-bg"><div id="barFraming" class="bar-fill w-0"></div></div>
        </div>
        <div class="prog-item">
          <div class="prog-txt-row"><span>Boarding (Gypsum Sheet Fixing)</span><span class="prog-val-bold" id="txtBoarding">0%</span></div>
          <div class="bar-bg"><div id="barBoarding" class="bar-fill w-0"></div></div>
        </div>
        <div class="prog-item">
          <div class="prog-txt-row"><span>Finishing (Joint & Putty Work)</span><span class="prog-val-bold" id="txtFinishing">0%</span></div>
          <div class="bar-bg"><div id="barFinishing" class="bar-fill w-0"></div></div>
        </div>
        <div class="prog-item">
          <div class="prog-txt-row"><span>Painting & Surface Coat</span><span class="prog-val-bold" id="txtPainting">0%</span></div>
          <div class="bar-bg"><div id="barPainting" class="bar-fill w-0"></div></div>
        </div>
        <div class="prog-item">
          <div class="prog-txt-row"><span>Cleanup & Final Handover</span><span class="prog-val-bold" id="txtCleanup">0%</span></div>
          <div class="bar-bg"><div id="barCleanup" class="bar-fill w-0"></div></div>
        </div>
        <div class="overall-wrap">
          <div class="prog-txt-row overall-margin">
            <span class="overall-val">OVERALL COMPLETION</span>
            <span class="overall-val" id="txtOverall">0%</span>
          </div>
          <div class="bar-bg"><div id="barOverall" class="bar-fill w-0 bg-green-overall"></div></div>
        </div>
      </div>
    `;
  },

  setBar(barId, txtId, percent) {
    const p = Math.max(0, Math.min(100, Math.round(Number(percent) || 0)));
    const bar = document.getElementById(barId);
    const txt = document.getElementById(txtId);
    if (bar) bar.style.width = p + '%';
    if (txt) txt.innerText = p + '%';
  },

  sync(row) {
    if (!row) return;
    let f = Number(row.framing_progress ?? row.progress_framing) || 0;
    let b = Number(row.boarding_progress ?? row.progress_boarding) || 0;
    let fn = Number(row.finishing_progress ?? row.progress_finishing) || 0;
    let p = Number(row.painting_progress ?? row.progress_painting) || 0;
    let c = Number(row.cleanup_progress ?? row.progress_cleanup) || 0;

    if (f === 0 && b === 0 && fn === 0 && Array.isArray(row.rooms_data) && row.rooms_data.length > 0) {
      const tot = row.rooms_data.length;
      let fS = 0, bS = 0, fnS = 0, pS = 0;
      row.rooms_data.forEach(r => {
        if (r.is_finished) { fS += 100; bS += 100; fnS += 100; pS += 100; }
        else {
          fS += r.framing_done ? 100 : (Number(r.channel_work) || 0);
          bS += r.boarding_done ? 100 : (Number(r.board_work) || 0);
          fnS += r.finishing_done ? 100 : (Number(r.finishing_work) || 0);
          pS += r.painting_done ? 100 : 0;
        }
      });
      f = Math.round(fS / tot);
      b = Math.round(bS / tot);
      fn = Math.round(fnS / tot);
      p = Math.round(pS / tot);
    }

    this.setBar('barFraming', 'txtFraming', f);
    this.setBar('barBoarding', 'txtBoarding', b);
    this.setBar('barFinishing', 'txtFinishing', fn);
    this.setBar('barPainting', 'txtPainting', p);
    this.setBar('barCleanup', 'txtCleanup', c);

    const overall = Math.round((f + b + fn + p + c) / 5);
    this.setBar('barOverall', 'txtOverall', overall);
  }
};
