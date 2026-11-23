import React, { useState, useRef } from 'react';
import { supabase } from '../../supabaseClient';
import { CheckSquare, Edit3 } from 'lucide-react';

interface Room {
  id: number;
  room_name: string;
  plain_rate: number;
  design_rate: number;
  design_photo_url: string;
  approval_status: string;
}

interface RoomApprovalSectionProps {
  uniqueCode: string;
  clientName: string;
  rooms: Room[];
  onRefresh: () => void;
}

export const RoomApprovalSection: React.FC<RoomApprovalSectionProps> = ({ uniqueCode, clientName, rooms, onRefresh }) => {
  const [activeRoomId, setActiveRoomId] = useState<number | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const getXY = (e: any, canvas: HTMLCanvasElement) => {
    const rect = canvas.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    return { x: clientX - rect.left, y: clientY - rect.top };
  };

  const startDraw = (e: any) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const { x, y } = getXY(e, canvas);
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#2563eb';
    setIsDrawing(true);
  };

  const draw = (e: any) => {
    if (!isDrawing || !canvasRef.current) return;
    const ctx = canvasRef.current.getContext('2d');
    if (!ctx) return;
    const { x, y } = getXY(e, canvasRef.current);
    ctx.lineTo(x, y);
    ctx.stroke();
  };

  const handleApprove = async (roomId: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    try {
      const base64 = canvas.toDataURL('image/png');
      const blob = await (await fetch(base64)).blob();
      const path = `rooms/${uniqueCode}_room_${roomId}.png`;
      await supabase.storage.from('project_signatures').upload(path, blob, { contentType: 'image/png', upsert: true });
      const { data: { publicUrl } } = supabase.storage.from('project_signatures').getPublicUrl(path);

      await supabase.from('project_rooms').update({
        approval_status: 'approved',
        client_signature_url: publicUrl
      }).eq('id', roomId);

      setActiveRoomId(null);
      onRefresh();
    } catch (err: any) {
      alert('Error: ' + err.message);
    }
  };

  const getFormattedTimestamp = (room: any) => {
    const timeVal = room.updated_at || room.created_at;
    if (!timeVal) {
      const now = new Date();
      return now.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      });
    }
    try {
      const date = new Date(timeVal);
      return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      });
    } catch (e) {
      console.error('Error formatting timestamp:', e);
      return new Date().toLocaleString();
    }
  };

  return (
    <div className="space-y-4">
      <h4 className="text-xs font-black text-slate-400 uppercase tracking-widest flex items-center gap-1.5"><CheckSquare size={14} /> Interactive Room Approval</h4>
      <div className="space-y-3">
        {rooms.map(room => (
          <div key={room.id} className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm space-y-3 relative overflow-hidden">
            <div className="flex justify-between items-start">
              <div>
                <p className="font-bold text-slate-800 leading-tight">{room.room_name}</p>
                <p className="text-xs text-slate-400 font-semibold mt-1">Plain: ₹{room.plain_rate}/sqft | Design: ₹{room.design_rate}/sqft</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wide ${room.approval_status === 'approved' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>{room.approval_status}</span>
            </div>
            {room.design_photo_url && (
              <img src={room.design_photo_url} alt={room.room_name} className="w-full h-32 object-cover rounded-xl border border-slate-100" />
            )}
            {room.approval_status === 'approved' && (
              <div className="relative overflow-hidden border-2 border-dashed border-emerald-500 bg-emerald-50/30 p-4 rounded-xl flex flex-col items-center justify-center text-center select-none shadow-sm mt-2">
                <div className="absolute -right-6 -bottom-6 w-20 h-20 border border-emerald-500/20 rounded-full flex items-center justify-center pointer-events-none">
                  <div className="w-14 h-14 border border-emerald-500/10 rounded-full"></div>
                </div>
                
                <span className="text-[9px] font-black tracking-widest text-emerald-500 uppercase">
                  ✓ Verification Confirmed
                </span>
                
                <p className="text-xs font-bold text-emerald-800 uppercase mt-1.5 tracking-wide leading-relaxed">
                  Digitally Approved by {clientName} on {getFormattedTimestamp(room)}
                </p>
                
                {room.client_signature_url && (
                  <div className="mt-2 p-1 bg-white/80 rounded border border-emerald-200">
                    <img 
                      src={room.client_signature_url} 
                      alt="Client Signature" 
                      className="h-10 object-contain mix-blend-multiply" 
                    />
                  </div>
                )}
              </div>
            )}
            {room.approval_status !== 'approved' && activeRoomId !== room.id && (
              <button onClick={() => setActiveRoomId(room.id)} className="w-full py-2 bg-blue-50 text-blue-600 rounded-xl text-xs font-bold uppercase tracking-wider flex items-center justify-center gap-1 hover:bg-blue-100 active:scale-95 transition">
                <Edit3 size={12} /> Approve / ✍️
              </button>
            )}
            {room.approval_status !== 'approved' && activeRoomId === room.id && (
              <div className="space-y-2 border border-slate-200 p-3 rounded-xl bg-slate-50">
                <p className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Draw Client Signature:</p>
                <canvas ref={canvasRef} width={300} height={100} onMouseDown={startDraw} onMouseMove={draw} onMouseUp={() => setIsDrawing(false)} onTouchStart={startDraw} onTouchMove={draw} onTouchEnd={() => setIsDrawing(false)} className="w-full h-24 bg-white border border-slate-200 rounded-lg cursor-crosshair touch-none" />
                <div className="flex gap-2">
                  <button onClick={() => setActiveRoomId(null)} className="flex-1 py-2 bg-slate-100 text-slate-500 rounded-lg text-xs font-bold uppercase tracking-wider">Cancel</button>
                  <button onClick={() => handleApprove(room.id)} className="flex-1 py-2 bg-blue-600 text-white rounded-lg text-xs font-bold uppercase tracking-wider shadow">Submit</button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
export default RoomApprovalSection;
