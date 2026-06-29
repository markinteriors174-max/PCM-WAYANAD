import React, { useState, useEffect } from 'react';
import { supabase } from '../../supabaseClient';
import { User, ChevronDown, ChevronUp, Save, Plus, AlertCircle } from 'lucide-react';

export const WorkerList: React.FC = () => {
  const [workers, setWorkers] = useState<any[]>([]);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [days, setDays] = useState<{ [key: number]: string }>({});
  const [payments, setPayments] = useState<{ [key: number]: string }>({});

  const fetchWorkers = async () => {
    const { data } = await supabase.from('worker_ledger_view').select('*').order('worker_name');
    setWorkers(data || []);
  };

  useEffect(() => { fetchWorkers(); }, []);

  const handleUpdate = async (id: number, field: string, value: number) => {
    await supabase.from('workers').update({ [field]: value }).eq('id', id);
    fetchWorkers();
  };

  const cellCls = "flex flex-col p-3 bg-slate-900/60 rounded-xl border border-white/5";
  const labelCls = "text-[9px] font-black uppercase text-slate-400 tracking-wider";
  const btnCls = "bg-blue-600 hover:bg-blue-700 text-white font-bold px-3 py-2 rounded-xl transition flex items-center justify-center cursor-pointer";

  return (
    <div className="space-y-4">
      {workers.length === 0 ? (
        <div className="text-center py-12 bg-white/5 border border-dashed border-white/10 rounded-3xl">
          <AlertCircle className="mx-auto text-slate-500 mb-3" size={40} />
          <p className="text-xs font-bold text-slate-300">No Worker Data Available. Add a worker first.</p>
        </div>
      ) : (
        workers.map((w) => {
          const isExp = expandedId === w.id;
          const isNeg = (w.net_balance ?? 0) < 0;
          return (
            <div key={w.id} className="backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl overflow-hidden transition-all duration-300">
              <button 
                onClick={() => setExpandedId(isExp ? null : w.id)} 
                className="w-full flex items-center justify-between p-5 text-left cursor-pointer focus:outline-none hover:bg-white/5"
              >
                <div className="flex items-center space-x-3">
                  <div className={`p-2 rounded-full ${isNeg ? 'bg-red-500/10 text-red-400' : 'bg-blue-500/10 text-blue-400'}`}>
                    <User size={18} />
                  </div>
                  <div>
                    <h4 className="text-sm font-black text-slate-200 tracking-wide">{w.worker_name.toUpperCase()}</h4>
                    <p className="text-xs font-bold text-slate-400 mt-0.5">
                      Balance: <span className={isNeg ? 'text-red-400 font-extrabold' : 'text-blue-400 font-extrabold'}>
                        ₹{Math.abs(w.net_balance ?? 0).toFixed(2)}
                      </span>
                      <span className="ml-2 text-[10px] uppercase font-black tracking-wider px-2 py-0.5 rounded bg-white/5">{w.status_label}</span>
                    </p>
                  </div>
                </div>
                {isExp ? <ChevronUp size={18} className="text-slate-400" /> : <ChevronDown size={18} className="text-slate-400" />}
              </button>
              
              {isExp && (
                <div className="px-5 pb-5 border-t border-white/5 pt-4 space-y-4 animate-in fade-in duration-250">
                  <div className="grid grid-cols-3 gap-3">
                    <div className={cellCls}><span className={labelCls}>Total Days</span><span className="text-sm font-black mt-1 text-slate-200">{w.total_days} days</span></div>
                    <div className={cellCls}><span className={labelCls}>Daily Wage</span><span className="text-sm font-black mt-1 text-slate-200">₹{w.daily_wage}</span></div>
                    <div className={cellCls}><span className={labelCls}>Total Paid</span><span className="text-sm font-black mt-1 text-slate-200">₹{w.total_paid}</span></div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1">
                      <span className={labelCls}>Update Days</span>
                      <div className="flex space-x-2">
                        <input type="number" step="any" placeholder="Days" value={days[w.id] ?? ''} onChange={(e) => setDays({...days, [w.id]: e.target.value})} className="bg-slate-950/80 border border-white/10 rounded-xl px-3 py-2 text-xs font-bold w-full text-slate-200 focus:outline-none" />
                        <button onClick={() => { handleUpdate(w.id, 'total_days', Number.parseFloat(days[w.id] || '0')); setDays({...days, [w.id]: ''}); }} className={btnCls} title="Save Days" aria-label="Save Days"><Save size={14} /></button>
                      </div>
                    </div>
                    <div className="space-y-1">
                      <span className={labelCls}>Add Payment</span>
                      <div className="flex space-x-2">
                        <input type="number" step="any" placeholder="Amount" value={payments[w.id] ?? ''} onChange={(e) => setPayments({...payments, [w.id]: e.target.value})} className="bg-slate-950/80 border border-white/10 rounded-xl px-3 py-2 text-xs font-bold w-full text-slate-200 focus:outline-none" />
                        <button onClick={() => { handleUpdate(w.id, 'total_paid', (w.total_paid ?? 0) + Number.parseFloat(payments[w.id] || '0')); setPayments({...payments, [w.id]: ''}); }} className={btnCls} title="Add Payment" aria-label="Add Payment"><Plus size={14} /></button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })
      )}
    </div>
  );
};
