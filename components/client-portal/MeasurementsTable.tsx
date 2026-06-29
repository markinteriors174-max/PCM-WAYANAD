import React from 'react';
import { FileText } from 'lucide-react';

interface MeasurementsTableProps {
  items: any[];
}

export const MeasurementsTable: React.FC<MeasurementsTableProps> = ({ items }) => {
  const safeItems = items || [];
  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-6 shadow-2xl space-y-4 text-white">
      <div className="flex items-center space-x-2 border-b border-white/10 pb-3">
        <div className="bg-blue-500/10 text-blue-400 p-2 rounded-xl border border-blue-500/20">
          <FileText size={18} />
        </div>
        <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest">
          Measurement Sheet
        </h4>
      </div>

      {safeItems.length > 0 ? (
        <div className="overflow-x-auto no-scrollbar -mx-6 px-6">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/10">
                <th className="pb-3 text-[10px] font-black text-slate-400 uppercase tracking-wider">Room</th>
                <th className="pb-3 text-[10px] font-black text-slate-400 uppercase tracking-wider">Dimensions</th>
                <th className="pb-3 text-[10px] font-black text-slate-400 uppercase tracking-wider">Area</th>
                <th className="pb-3 text-[10px] font-black text-slate-400 uppercase tracking-wider text-right">Total</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {safeItems.map((item, idx) => (
                <tr key={item.roomName || idx} className="hover:bg-white/5 transition">
                  <td className="py-3 pr-2">
                    <p className="text-xs font-black text-slate-200 leading-tight">{item.roomName}</p>
                    <p className="text-[9px] text-slate-400 font-bold mt-0.5">{item.ceilingType}</p>
                  </td>
                  <td className="py-3 text-xs font-semibold text-slate-300">
                    {item.length} × {item.width} {item.unit === 'Meters' ? 'm' : 'ft'}
                  </td>
                  <td className="py-3 text-xs font-bold text-slate-300">
                    {(item.area || 0).toFixed(1)} {item.unit === 'Meters' ? 'SqM' : 'SqFt'}
                  </td>
                  <td className="py-3 text-xs font-black text-slate-200 text-right">
                    ₹{(item.amount || 0).toLocaleString('en-IN')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="text-center py-8 border border-dashed border-white/10 rounded-2xl space-y-2">
          <p className="text-xs text-slate-300 font-bold">No measurements available yet.</p>
          <p className="text-[10px] text-slate-400 font-medium px-4">
            Once our design engineer completes measurements on site, details will appear here.
          </p>
        </div>
      )}
    </div>
  );
};
