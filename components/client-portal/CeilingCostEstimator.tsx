import React, { useState, useEffect } from 'react';
import { Calculator, Zap, Info, ShieldCheck, Percent } from 'lucide-react';
import { calculateCeilingCost, CeilingCalcResult } from '../../utils/ceilingCalculations';

export const CeilingCostEstimator: React.FC = () => {
  const [length, setLength] = useState<string>('5.5');
  const [width, setWidth] = useState<string>('4.2');
  const [rate, setRate] = useState<string>('95');
  const [taxPercent, setTaxPercent] = useState<string>('18');
  const [includeTax, setIncludeTax] = useState<boolean>(false);
  const [result, setResult] = useState<CeilingCalcResult | null>(null);

  useEffect(() => {
    const l = parseFloat(length) || 0;
    const w = parseFloat(width) || 0;
    const r = parseFloat(rate) || 0;
    const t = parseFloat(taxPercent) || 0;

    const calcResult = calculateCeilingCost({
      lengthMeters: l,
      widthMeters: w,
      ratePerSqFt: r,
      taxPercentage: t,
      includeTax: includeTax
    });

    setResult(calcResult);
  }, [length, width, rate, taxPercent, includeTax]);

  return (
    <div className="backdrop-blur-xl bg-white/[0.03] border border-white/10 rounded-[2.5rem] p-8 shadow-2xl space-y-8 text-white relative overflow-hidden">
      {/* Background Glow */}
      <div className="absolute -top-24 -right-24 w-48 h-48 bg-blue-500/10 rounded-full blur-3xl pointer-events-none"></div>

      <div className="flex items-center justify-between border-b border-white/5 pb-6">
        <div className="flex items-center space-x-3">
          <div className="bg-blue-600/20 text-blue-400 p-3 rounded-2xl border border-blue-500/20 shadow-lg shadow-blue-900/20">
            <Calculator size={22} />
          </div>
          <div>
            <h4 className="text-sm font-black text-white uppercase tracking-[0.2em]">
              Precision Cost Estimator
            </h4>
            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-0.5">
              Strict Business Logic v3.1
            </p>
          </div>
        </div>
        <div className="bg-emerald-500/10 text-emerald-400 text-[10px] font-black px-3 py-1.5 rounded-xl border border-emerald-500/20 flex items-center gap-1.5 shadow-inner">
          <ShieldCheck size={12} />
          VERIFIED LOGIC
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* INPUTS */}
        <div className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="block text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">
                Length (Meters)
              </label>
              <input
                type="number"
                step="0.01"
                value={length}
                onChange={(e) => setLength(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-white focus:ring-2 focus:ring-blue-500/30 outline-none transition-all font-bold text-sm"
              />
            </div>
            <div className="space-y-2">
              <label className="block text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">
                Width (Meters)
              </label>
              <input
                type="number"
                step="0.01"
                value={width}
                onChange={(e) => setWidth(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-white focus:ring-2 focus:ring-blue-500/30 outline-none transition-all font-bold text-sm"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="block text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">
              Rate (Per Square Foot)
            </label>
            <div className="relative">
              <span className="absolute left-5 top-1/2 -translate-y-1/2 text-slate-500 font-bold">₹</span>
              <input
                type="number"
                value={rate}
                onChange={(e) => setRate(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-2xl pl-10 pr-5 py-4 text-white focus:ring-2 focus:ring-blue-500/30 outline-none transition-all font-bold text-sm"
              />
            </div>
          </div>

          <div className="flex items-center justify-between bg-white/5 p-4 rounded-2xl border border-white/10 group cursor-pointer" onClick={() => setIncludeTax(!includeTax)}>
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg transition-colors ${includeTax ? 'bg-blue-600/30 text-blue-400' : 'bg-white/5 text-slate-500'}`}>
                <Percent size={14} />
              </div>
              <div>
                <p className="text-[11px] font-black text-slate-300 uppercase tracking-wider">Apply GST / TAX</p>
                <p className="text-[9px] text-slate-500 font-bold uppercase mt-0.5">Add {taxPercent}% to final total</p>
              </div>
            </div>
            <div className={`w-10 h-6 rounded-full p-1 transition-colors ${includeTax ? 'bg-blue-600' : 'bg-slate-800'}`}>
              <div className={`w-4 h-4 bg-white rounded-full transition-transform ${includeTax ? 'translate-x-4' : 'translate-x-0'}`}></div>
            </div>
          </div>

          {includeTax && (
            <div className="space-y-2 animate-in fade-in slide-in-from-top-2 duration-300">
              <label className="block text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">
                Tax Percentage (%)
              </label>
              <input
                type="number"
                value={taxPercent}
                onChange={(e) => setTaxPercent(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-2xl px-5 py-4 text-white focus:ring-2 focus:ring-blue-500/30 outline-none transition-all font-bold text-sm"
              />
            </div>
          )}
        </div>

        {/* RESULTS */}
        <div className="bg-black/40 rounded-[2rem] border border-white/5 p-6 flex flex-col justify-between space-y-6">
          <div className="space-y-4">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-500 font-bold uppercase tracking-wider">Measured Area (sqm)</span>
              <span className="text-white font-black">{result?.sqm.toFixed(4)} m²</span>
            </div>
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-500 font-bold uppercase tracking-wider">Converted (sqft)</span>
              <span className="text-slate-300 font-bold">{result?.sqftRaw.toFixed(4)} ft²</span>
            </div>
            <div className="flex justify-between items-center bg-blue-500/5 p-3 rounded-xl border border-blue-500/10">
              <span className="text-blue-400 text-[10px] font-black uppercase tracking-widest flex items-center gap-1.5">
                <Zap size={12} /> Billed Area (CEIL)
              </span>
              <span className="text-white font-black text-sm">{result?.sqftRounded} ft²</span>
            </div>
          </div>

          <div className="pt-6 border-t border-white/5 space-y-4">
            <div className="flex justify-between items-end">
              <div>
                <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Base Estimate</p>
                <p className="text-2xl font-black text-white mt-1">₹{result?.baseAmount.toLocaleString('en-IN')}</p>
              </div>
              {includeTax && (
                <div className="text-right">
                  <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">GST ({taxPercent}%)</p>
                  <p className="text-sm font-black text-blue-400">+ ₹{result?.taxAmount.toLocaleString('en-IN')}</p>
                </div>
              )}
            </div>

            <div className="bg-gradient-to-r from-blue-600 to-indigo-700 p-6 rounded-2xl shadow-xl shadow-blue-900/20">
              <p className="text-[10px] font-black text-blue-200 uppercase tracking-[0.2em]">Final Total Amount</p>
              <p className="text-3xl font-black text-white mt-1">₹{result?.totalAmount.toLocaleString('en-IN')}</p>
            </div>
          </div>

          <div className="flex items-start gap-2 bg-amber-500/5 p-3 rounded-xl border border-amber-500/10">
            <Info size={14} className="text-amber-500 shrink-0 mt-0.5" />
            <p className="text-[9px] text-amber-500/70 font-bold leading-relaxed">
              Calculation uses standard 10.7639 factor with strict Ceiling [CEIL] rounding to protect against material loss.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
