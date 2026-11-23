import React from 'react';
import { CreditCard, ChevronRight } from 'lucide-react';
import { FinancialChart } from '../FinancialChart';

interface FinancialDashboardProps {
  totalAmount: number;
  paidAmount: number;
  balanceAmount: number;
  unitNumber: string;
  company: {
    name: string;
    upi_id: string;
  };
}

export const FinancialDashboard: React.FC<FinancialDashboardProps> = ({
  totalAmount,
  paidAmount,
  balanceAmount,
  unitNumber,
  company,
}) => {
  const handleUpiPay = () => {
    if (balanceAmount <= 0) return;
    const payeeName = encodeURIComponent(company.name);
    const upiId = company.upi_id;
    const amount = balanceAmount.toFixed(2);
    const transactionNote = encodeURIComponent(`Payment for Project Site ${unitNumber}`);
    const upiUrl = `upi://pay?pa=${upiId}&pn=${payeeName}&am=${amount}&tn=${transactionNote}&cu=INR`;
    globalThis.location.href = upiUrl;
  };

  return (
    <div className="space-y-6">
      <FinancialChart total={totalAmount} paid={paidAmount} balance={balanceAmount} />

      {balanceAmount > 0 && (
        <div className="backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl p-5 text-white flex flex-col gap-3 shadow-xl">
          <div className="bg-red-500/10 p-5 rounded-2xl border border-red-500/20 flex justify-between items-center shadow-inner">
            <div>
              <span className="text-[9px] font-black text-red-400 block mb-1 uppercase tracking-wider">
                Outstanding Balance
              </span>
              <span className="text-2xl font-black text-red-500 leading-none">
                ₹{balanceAmount.toLocaleString('en-IN')}
              </span>
            </div>
            <div className="bg-red-500/10 p-2.5 rounded-xl text-red-400 border border-red-500/20">
              <CreditCard size={20} />
            </div>
          </div>

          <div className="space-y-2 pt-1">
            <button
              onClick={handleUpiPay}
              className="w-full bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white font-black py-4 rounded-2xl shadow-xl shadow-blue-500/10 active:scale-98 transition-all flex items-center justify-center space-x-2 text-sm uppercase tracking-wide border border-white/10 cursor-pointer animate-pulse"
            >
              <span>Pay Balance via UPI</span>
              <ChevronRight size={16} />
            </button>
            <p className="text-[9px] text-slate-400 font-bold text-center">
              Secure payments via BHIM UPI (GPay, PhonePe, Paytm supported)
            </p>
          </div>
        </div>
      )}
    </div>
  );
};
