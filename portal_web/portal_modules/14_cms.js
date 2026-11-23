/**
 * PCM WAYANAD - Client Portal: Website CMS & Founder Memorial Module
 */
(function (window) {
  'use strict';

  async function syncLiveCmsData() {
    const client = window.getSupabase ? window.getSupabase() : null;
    if (!client) return;

    try {
      const { data } = await client.from('website_cms').select('*');
      if (data && data.length > 0) applyCmsData(data);
    } catch (_) {}
    loadFounderMemorial();
  }

  function applyCmsData(cmsList) {
    cmsList.forEach(item => {
      const k = item.section_key;
      if (k === 'hero_tag' && document.getElementById('heroTag')) document.getElementById('heroTag').textContent = item.title;
      if (k === 'hero_headline' && document.getElementById('heroHeadline')) document.getElementById('heroHeadline').textContent = item.title;
      if (k === 'calc_gypsum_rate' && typeof window.applyCalculatorRates === 'function') {
        window.applyCalculatorRates(Number(item.price_value || item.title || 125));
      }
    });
  }

  async function loadFounderMemorial() {
    const imgEl = document.getElementById('memorialFounderImg');
    const nameEl = document.getElementById('memorialFounderName');
    const quoteEl = document.getElementById('memorialFounderQuote');
    if (!nameEl) return;

    const client = window.getSupabase ? window.getSupabase() : null;
    if (client) {
      try {
        const { data } = await client.from('website_cms').select('*').eq('section_key', 'founder_memorial').maybeSingle();
        if (data) {
          if (nameEl && data.title) nameEl.textContent = data.title;
          if (quoteEl && data.subtitle) quoteEl.textContent = `"${data.subtitle}"`;
          if (imgEl && data.image_url) imgEl.src = data.image_url;
        }
      } catch (_) {}
    }
  }

  window.syncLiveCmsData = syncLiveCmsData;
  window.applyCmsData = applyCmsData;
  window.loadFounderMemorial = loadFounderMemorial;
})(window);
