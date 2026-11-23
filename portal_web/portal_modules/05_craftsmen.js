/**
 * PCM WAYANAD - Client Portal: Craftsmen Team Showcase Module
 */
(function (window) {
  'use strict';

  async function loadLiveCraftsmenTeam() {
    const grid = document.getElementById('craftsmenTeamGrid');
    if (!grid) return;
    const client = window.getSupabase ? window.getSupabase() : null;
    let members = [];

    if (client) {
      try {
        const { data } = await client.from('cms_craftsmen').select('*').order('display_order', { ascending: true });
        if (data && data.length > 0) members = data;
      } catch (_) {}
    }

    if (members.length === 0) {
      members = [
        { name: 'K. Sasi Master', role: 'Chief Gypsum Fabricator', experience_years: 18, rating: 4.9, avatar_url: '' },
        { name: 'Ratheesh K.', role: 'Senior Laser Grid Alignment Specialist', experience_years: 14, rating: 4.8, avatar_url: '' },
        { name: 'Shaji Wayanad', role: 'Acoustic & Cove Profile Master', experience_years: 12, rating: 4.9, avatar_url: '' }
      ];
    }

    grid.innerHTML = members.map((m, idx) => renderCraftsmanCard(m, idx === 0 ? 'Lead' : 'Specialist')).join('');
  }

  function renderCraftsmanCard(m, tierType) {
    const avatar = m.avatar_url && m.avatar_url.startsWith('http')
      ? `<img src="${m.avatar_url}" alt="${m.name}" class="w-12 h-12 rounded-full object-cover border-2 border-amber-500/50">`
      : `<div class="w-12 h-12 rounded-full bg-amber-500/20 border-2 border-amber-500/50 flex items-center justify-center font-black text-amber-400 text-base">👷</div>`;

    return `
      <div class="p-4 rounded-2xl bg-slate-900/80 border border-white/10 hover:border-amber-500/40 transition flex items-center gap-4 shadow-lg">
        ${avatar}
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-2">
            <h4 class="text-sm font-bold text-white truncate">${m.name}</h4>
            <span class="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 font-black text-[9px] uppercase">${tierType}</span>
          </div>
          <p class="text-xs text-slate-400 mt-0.5 truncate">${m.role}</p>
          <div class="mt-2 flex items-center gap-3 text-[11px] text-slate-400">
            <span>🎖️ ${m.experience_years}+ Yrs</span>
            <span>⭐ ${m.rating || '4.9'}</span>
          </div>
        </div>
      </div>
    `;
  }

  window.loadLiveCraftsmenTeam = loadLiveCraftsmenTeam;
  window.renderCraftsmanCard = renderCraftsmanCard;
})(window);
