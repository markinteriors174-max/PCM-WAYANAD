import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { ShieldAlert, RefreshCw, Home } from 'lucide-react';
import FinancialLedger from './client-portal/FinancialLedger';
import RoomApprovalSection from './client-portal/RoomApprovalSection';
import PdfVault from './client-portal/PdfVault';
import ClientPhotoUpload from './client-portal/ClientPhotoUpload';

interface ClientTrustPortalProps {
  clientId?: string;
  onBack?: () => void;
}

export const ClientTrustPortal: React.FC<ClientTrustPortalProps> = ({ clientId: propClientId, onBack }) => {
  const [clientId] = useState(() => {
    if (propClientId) return propClientId;
    const params = new URLSearchParams(globalThis.location.search);
    return params.get('clientId') || params.get('unitNumber') || '';
  });
  
  const [financials, setFinancials] = useState({ totalAmount: 0, paidAmount: 0, balanceAmount: 0 });
  const [rooms, setRooms] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPortalData = async () => {
    if (!clientId) return;
    try {
      const { data: quote } = await supabase.from('quotations').select('totalAmount, paidAmount, balanceAmount').eq('unitNumber', clientId).single();
      if (quote) {
        setFinancials({
          totalAmount: quote.totalAmount || 0,
          paidAmount: quote.paidAmount || 0,
          balanceAmount: quote.balanceAmount || 0
        });
      }
      const { data: roomList } = await supabase.from('project_rooms').select('*').eq('project_code', clientId);
      if (roomList) setRooms(roomList);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPortalData();
    const channels = [
      supabase.channel(`public:quotations:unitNumber=eq.${clientId}`).on('postgres_changes', { event: '*', schema: 'public', table: 'quotations', filter: `unitNumber=eq.${clientId}` }, fetchPortalData).subscribe(),
      supabase.channel(`public:project_rooms:project_code=eq.${clientId}`).on('postgres_changes', { event: '*', schema: 'public', table: 'project_rooms', filter: `project_code=eq.${clientId}` }, fetchPortalData).subscribe()
    ];
    return () => {
      channels.forEach(ch => supabase.removeChannel(ch));
    };
  }, [clientId]);

  if (!clientId) {
    return (
      <div className="flex flex-col items-center justify-center p-8 bg-red-50 text-red-600 rounded-3xl border border-red-100 max-w-md mx-auto mt-12 text-center gap-3">
        <ShieldAlert size={36} />
        <p className="text-sm font-black">Unauthorized Access: Missing Unique Project Code</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 py-8 px-4 flex flex-col justify-start max-w-md mx-auto gap-6 pb-24">
      <div className="flex items-center justify-between border-b border-slate-200 pb-4">
        <div>
          <h2 className="text-xl font-black text-slate-800 leading-tight">Client Trust Portal</h2>
          <span className="text-[10px] bg-blue-100 text-blue-700 px-2 py-0.5 rounded font-black tracking-wider uppercase mt-1 inline-block">Code: {clientId}</span>
        </div>
        <button onClick={onBack || (() => globalThis.location.href = '/')} className="p-2.5 bg-slate-100 border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-200 transition" aria-label="Back to Home" title="Back to Home">
          <Home size={18} />
        </button>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-12 gap-2 text-slate-400 font-semibold text-xs">
          <RefreshCw className="animate-spin text-blue-600" size={24} /> Loading Secure Portal...
        </div>
      ) : (
        <>
          <FinancialLedger totalAmount={financials.totalAmount} paidAmount={financials.paidAmount} balanceAmount={financials.balanceAmount} />
          <RoomApprovalSection uniqueCode={clientId} rooms={rooms} onRefresh={fetchPortalData} />
          <PdfVault uniqueCode={clientId} />
          <ClientPhotoUpload uniqueCode={clientId} />
        </>
      )}
    </div>
  );
};
export default ClientTrustPortal;
