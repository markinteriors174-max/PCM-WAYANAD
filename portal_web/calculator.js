/**
 * =========================================================================
 * PCM WAYANAD - REALTIME FALSE CEILING BUDGET CALCULATOR
 * =========================================================================
 */

let currentRates = {
  simple: 0,
  cove: 0,
  luxury: 0
};

let currentCeilingType = 'cove';

// Sync live rates from Supabase CMS
function applyCalculatorRates(ratesData) {
  if (!ratesData) return;

  // Support calculator_rates section (title: simple, subtitle: cove, content: luxury)
  if (ratesData.title && !Number.isNaN(Number(ratesData.title))) {
    currentRates.simple = Number.parseFloat(ratesData.title);
  }
  if (ratesData.subtitle && !Number.isNaN(Number(ratesData.subtitle))) {
    currentRates.cove = Number.parseFloat(ratesData.subtitle);
  }
  if (ratesData.content && !Number.isNaN(Number(ratesData.content))) {
    currentRates.luxury = Number.parseFloat(ratesData.content);
  }

  // Support live_config columns (rate_simple, rate_cove, rate_luxury)
  if (ratesData.rate_simple) currentRates.simple = Number(ratesData.rate_simple);
  if (ratesData.rate_cove) currentRates.cove = Number(ratesData.rate_cove);
  if (ratesData.rate_luxury) currentRates.luxury = Number(ratesData.rate_luxury);

  // Update rate card labels in UI
  const rSimpleEl = document.getElementById('rateCardSimple');
  const rCoveEl = document.getElementById('rateCardCove');
  const rLuxEl = document.getElementById('rateCardLuxury');

  if (rSimpleEl) rSimpleEl.textContent = `₹${currentRates.simple}/sq.ft`;
  if (rCoveEl) rCoveEl.textContent = `₹${currentRates.cove}/sq.ft`;
  if (rLuxEl) rLuxEl.textContent = `₹${currentRates.luxury}/sq.ft`;

  recalculateEstimate();
}

async function syncLiveCmsRates() {
  const client = window.supabase || (typeof supabase !== 'undefined' ? supabase : null);
  if (!client || typeof client.from !== 'function') return;

  try {
    // 1. Try calculator_rates
    const { data: calcRates } = await client
      .from('website_cms')
      .select('*')
      .eq('section_key', 'calculator_rates')
      .maybeSingle();

    if (calcRates) {
      applyCalculatorRates(calcRates);
      return;
    }

    // 2. Fallback to live_config (maybeSingle prevents 406 Not Acceptable when row is absent)
    const { data, error } = await client
      .from('website_cms')
      .select('rate_simple, rate_cove, rate_luxury')
      .eq('id', 'live_config')
      .maybeSingle();

    if (data && !error) {
      applyCalculatorRates(data);
    }
  } catch (e) {
    console.warn('Live rates sync notice:', e);
  }
}

// Select Ceiling Design Package
function selectCeilingType(type) {
  currentCeilingType = type;
  
  const types = ['simple', 'cove', 'luxury'];
  types.forEach(t => {
    const btn = document.getElementById(`btnType_${t}`);
    if (btn) {
      if (t === type) {
        btn.classList.add('border-amber-500', 'bg-amber-500/10', 'text-amber-400');
        btn.classList.remove('border-slate-700', 'bg-slate-900', 'text-slate-300');
      } else {
        btn.classList.remove('border-amber-500', 'bg-amber-500/10', 'text-amber-400');
        btn.classList.add('border-slate-700', 'bg-slate-900', 'text-slate-300');
      }
    }
  });

  recalculateEstimate();
}

function updateBreakdownUI(breakdown) {
  const mGyproc = document.getElementById('breakdownGyproc');
  const mPerimeter = document.getElementById('breakdownPerimeter');
  const mInter = document.getElementById('breakdownInter');
  const mScrews = document.getElementById('breakdownScrews');
  const mJoint = document.getElementById('breakdownJoint');
  const mLed = document.getElementById('breakdownLed');
  const mLabor = document.getElementById('breakdownLabor');

  if (mGyproc) mGyproc.textContent = `${breakdown.gyprocSheets} Sheets (Saint-Gobain 12.5mm)`;
  if (mPerimeter) mPerimeter.textContent = `${breakdown.perimeterChannel} R.Ft (0.50mm GI Perimeter)`;
  if (mInter) mInter.textContent = `${breakdown.intermediateChannel} R.Ft (GI Intermediate)`;
  if (mScrews) mScrews.textContent = `${breakdown.screwsAndFasteners} Nos (Anti-Rust Drywall Screws)`;
  if (mJoint) mJoint.textContent = `₹${breakdown.jointTapeCompound.toLocaleString('en-IN')} (Gyproc Joint Compound)`;
  if (mLed) mLed.textContent = currentCeilingType === 'simple' ? 'None (Simple Flat)' : `${breakdown.ledStripMeters}m (Warm White 3000K + Driver)`;
  if (mLabor) mLabor.textContent = `₹${breakdown.laborAndFinish.toLocaleString('en-IN')} (Laser Framing + 2-Coat Emulsion)`;
}

// Recalculate Square Footage & Cost Breakdown
function recalculateEstimate() {
  const lenEl = document.getElementById('calcLength');
  const widEl = document.getElementById('calcWidth');
  const lenValEl = document.getElementById('calcLengthVal');
  const widValEl = document.getElementById('calcWidthVal');
  const totalSqFtEl = document.getElementById('calcTotalSqFt');
  const totalCostEl = document.getElementById('calcTotalCost');

  const length = Number.parseFloat(lenEl ? lenEl.value : 12) || 12;
  const width = Number.parseFloat(widEl ? widEl.value : 11) || 11;

  if (lenValEl) lenValEl.textContent = `${length.toFixed(1)} ft`;
  if (widValEl) widValEl.textContent = `${width.toFixed(1)} ft`;

  const totalSqFt = Math.round(length * width);
  if (totalSqFtEl) totalSqFtEl.textContent = `${totalSqFt} sq.ft`;

  const rate = currentRates[currentCeilingType] || 135;
  const totalEstimate = totalSqFt * rate;

  if (totalCostEl) {
    totalCostEl.textContent = `₹${totalEstimate.toLocaleString('en-IN')}`;
  }

  // Material & Labor Breakdown
  updateBreakdownUI({
    gyprocSheets: Math.ceil((totalSqFt * 1.1) / 24),
    perimeterChannel: Math.round((length + width) * 2 * 1.05),
    intermediateChannel: Math.round((totalSqFt / 4) * 1.1),
    screwsAndFasteners: Math.round(totalSqFt * 4.5),
    jointTapeCompound: Math.round(totalSqFt * 14),
    ledStripMeters: currentCeilingType === 'simple' ? 0 : Math.round((length + width) * 2 * 0.3048),
    laborAndFinish: Math.round(totalEstimate * 0.42)
  });
}

const ROOM_PRESETS = {
  bedroom: { len: 14, wid: 12, type: 'cove' },
  living: { len: 20, wid: 16, type: 'luxury' },
  dining: { len: 14, wid: 10, type: 'cove' },
  kitchen: { len: 11, wid: 9, type: 'simple' }
};

// Preset Room Dimensions
function applyRoomPreset(room) {
  const preset = ROOM_PRESETS[room];
  if (!preset) return;

  const lenEl = document.getElementById('calcLength');
  const widEl = document.getElementById('calcWidth');

  if (lenEl) lenEl.value = preset.len;
  if (widEl) widEl.value = preset.wid;

  selectCeilingType(preset.type);
  recalculateEstimate();
}

function getCeilingTypeName(type) {
  const names = {
    simple: 'Simple Flat Ceiling',
    luxury: 'Multi-Tier Luxury Tray',
    cove: 'Single Concealed Cove Light'
  };
  return names[type] || 'Saint-Gobain Gyproc False Ceiling';
}

// Send detailed WhatsApp Quote
function sendWhatsAppQuote() {
  const lenEl = document.getElementById('calcLength');
  const widEl = document.getElementById('calcWidth');
  const length = lenEl ? lenEl.value : 12;
  const width = widEl ? widEl.value : 11;
  const sqFt = Math.round(Number(length) * Number(width));
  const rate = currentRates[currentCeilingType] || 135;
  const total = sqFt * rate;
  const clientName = localStorage.getItem('pcm_client_name') || 'Client';

  const typeName = getCeilingTypeName(currentCeilingType);

  const text = `*PCM WAYANAD - INSTANT BUDGET ESTIMATE*
👤 *Client:* ${clientName}
📐 *Dimensions:* ${length} ft x ${width} ft (${sqFt} sq.ft)
✨ *Design Type:* ${typeName}
💰 *Rate:* ₹${rate}/sq.ft
🏷️ *Estimated Total:* ₹${total.toLocaleString('en-IN')}

_Crafted with Saint-Gobain Gyproc & Warm 3000K LED Cove Lighting._
_Site: Padinjarathara, Wayanad._`;

  window.open(`https://wa.me/919383406185?text=${encodeURIComponent(text)}`, '_blank');
}

// Initialize on DOM load
window.addEventListener('DOMContentLoaded', () => {
  const lenEl = document.getElementById('calcLength');
  const widEl = document.getElementById('calcWidth');

  if (lenEl) lenEl.addEventListener('input', recalculateEstimate);
  if (widEl) widEl.addEventListener('input', recalculateEstimate);

  syncLiveCmsRates();
  recalculateEstimate();
});

// Expose functions globally
window.applyCalculatorRates = applyCalculatorRates;
window.syncLiveCmsRates = syncLiveCmsRates;
