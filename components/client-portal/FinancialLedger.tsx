import React, { useState } from 'react';
import { DollarSign, ClipboardList, Wallet, ShieldAlert, List, Eye } from 'lucide-react';
import { convertAreaToRoundedSqFt } from '../../utils/ceilingCalculations';

interface FinancialLedgerProps {
  totalAmount: number;
  paidAmount: number;
  balanceAmount: number;
  items?: any[];
}

export const FinancialLedger: React.FC<FinancialLedgerProps> = ({
  totalAmount,
  paidAmount,
  balanceAmount,
  items = [],
}) => {
  const [viewMode, setViewMode] = useState<'consolidated' | 'detailed'>('consolidated');

  const calculateItemCosts = (item: any) => {
    const quantity = item.quantity || 1;
    const rate = item.rate || 0;
    
    const isCeiling = item.isCeilingDesign === 1 || item.isCeilingDesign === true || item.isCeilingDesign === '1';
    const hasCove = item.hasCove === 1 || item.hasCove === true || item.hasCove === '1';
    const hasCentral = item.hasCentralDesign === 1 || item.hasCentralDesign === true || item.hasCentralDesign === '1';

    let ceilingArea = 0;
    if (isCeiling) {
      if (item.length === 0 && item.width === 0 && (item.area || 0) > 0) {
        const mainArea = (item.area / quantity) - (item.coveRft || 0) - (item.centralArea || 0);
        ceilingArea = Math.max(0, mainArea);
      } else {
        ceilingArea = (item.length || 0) * (item.width || 0);
      }
    }
    
    // DEFINITIVE CALCULATION LOGIC v3.1 (Meters to SqFt with CEIL)
    const roundedSqFt = convertAreaToRoundedSqFt(ceilingArea, item.unit);
    const plainCost = isCeiling ? (roundedSqFt * rate * quantity) : 0;
    
    const coveRateVal = (item.coveRate || 0) > 0 ? item.coveRate : rate;
    const roundedCoveSqFt = convertAreaToRoundedSqFt(item.coveRft || 0, item.unit);
    const designCost = hasCove ? (roundedCoveSqFt * quantity * coveRateVal) : 0;
    
    const centralRateVal = (item.centralRate || 0) > 0 ? item.centralRate : rate;
    const roundedCentralSqFt = convertAreaToRoundedSqFt(item.centralArea || 0, item.unit);
    const centerCost = hasCentral ? (roundedCentralSqFt * quantity * centralRateVal) : 0;
    
    return {
      plain: Math.round(plainCost),
      design: Math.round(designCost),
      center: Math.round(centerCost),
      total: Math.round(plainCost + designCost + centerCost)
    };
  };

  const cards = [
    {
      title: 'Total Contract Value',
      amount: totalAmount,
      icon: ClipboardList,
      gradient: 'from-blue-600/20 to-indigo-600/10 border-blue-500/20 border backdrop-blur-md shadow-lg shadow-blue-900/10',
      text: 'text-blue-100',
      labelColor: 'text-blue-300',
    },
    {
      title: 'Advance & Paid Amount',
      amount: paidAmount,
      icon: Wallet,
      gradient: 'from-emerald-600/20 to-teal-600/10 border-emerald-500/20 border backdrop-blur-md shadow-lg shadow-emerald-900/10',
      text: 'text-emerald-400',
      labelColor: 'text-emerald-300',
    },
    {
      title: 'Outstanding Balance',
      amount: balanceAmount,
      icon: ShieldAlert,
      gradient: 'from-rose-600/20 to-pink-600/10 border-rose-500/20 border backdrop-blur-md shadow-lg shadow-rose-900/10',
      text: 'text-rose-400',
      labelColor: 'text-rose-300',
    },
  ];

  return (
    <div className="space-y-4">
      {/* Header and Toggle Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-white/10 pb-3">
        <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
          <DollarSign size={14} className="text-blue-400" /> Financial Overview
        </h4>
        <div className="flex bg-slate-900/80 p-0.5 rounded-xl border border-white/10 self-start sm:self-auto">
          <button
            type="button"
            onClick={() => setViewMode('consolidated')}
            className={`px-3 py-1.5 text-[10px] font-black rounded-lg transition-all flex items-center gap-1 cursor-pointer ${
              viewMode === 'consolidated'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                : 'text-slate-400 hover:text-white bg-transparent'
            }`}
          >
            <Eye size={12} />
            CONSOLIDATED
          </button>
          <button
            type="button"
            onClick={() => setViewMode('detailed')}
            className={`px-3 py-1.5 text-[10px] font-black rounded-lg transition-all flex items-center gap-1 cursor-pointer ${
              viewMode === 'detailed'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                : 'text-slate-400 hover:text-white bg-transparent'
            }`}
          >
            <List size={12} />
            ROOM BREAKDOWN
          </button>
        </div>
      </div>

      {viewMode === 'consolidated' ? (
        <div className="grid grid-cols-1 gap-4">
          {cards.map((card) => {
            const Icon = card.icon;
            return (
              <div
                key={card.title}
                className={`p-5 rounded-3xl flex items-center justify-between transition hover:scale-[1.01] bg-gradient-to-br ${card.gradient}`}
              >
                <div>
                  <span className={`text-[10px] font-black uppercase tracking-wider block mb-1 ${card.labelColor}`}>
                    {card.title}
                  </span>
                  <span className={`text-2xl font-black ${card.text}`}>
                    ₹{card.amount.toLocaleString('en-IN')}
                  </span>
                </div>
                <div className={`p-3 rounded-2xl bg-white/5 border border-white/10 ${card.text}`}>
                  <Icon size={20} />
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="space-y-4">
          {items.length > 0 ? (
            items.map((item, index) => {
              const costs = calculateItemCosts(item);
              return (
                <div
                  key={item.id || index}
                  className="p-5 rounded-3xl bg-gradient-to-br from-slate-900/90 to-indigo-950/80 border border-white/10 shadow-lg space-y-3 transition-transform hover:scale-[1.005]"
                >
                  <div className="flex justify-between items-start border-b border-white/5 pb-2">
                    <div>
                      <h5 className="text-xs font-black text-blue-300 uppercase tracking-wider">
                        {item.roomName || 'General Room'}
                      </h5>
                      <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider">
                        {item.ceilingType || 'Gypsum'} • {item.designName || 'Standard Design'}
                      </span>
                    </div>
                    <span className="text-sm font-black text-emerald-400">
                      ₹{costs.total.toLocaleString('en-IN')}
                    </span>
                  </div>

                  <div className="space-y-2 text-[11px] font-semibold text-slate-300">
                    <div className="flex justify-between items-center bg-white/5 p-2 rounded-xl border border-white/5">
                      <span>Plain Work Cost</span>
                      <span className="font-bold text-slate-200">₹{costs.plain.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between items-center bg-white/5 p-2 rounded-xl border border-white/5">
                      <span>Design Work Cost</span>
                      <span className="font-bold text-slate-200">₹{costs.design.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="flex justify-between items-center bg-white/5 p-2 rounded-xl border border-white/5">
                      <span>Center Design Cost</span>
                      <span className="font-bold text-slate-200">₹{costs.center.toLocaleString('en-IN')}</span>
                    </div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="text-center py-8 bg-white/5 border border-dashed border-white/10 rounded-2xl">
              <p className="text-xs text-slate-400 font-bold">No room breakdown items available.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default FinancialLedger;
