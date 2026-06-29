import React, { useRef, useState } from 'react';
import { supabase } from '../../supabaseClient';
import { Check, RotateCcw } from 'lucide-react';

interface ClientSignaturePadProps {
  clientId: string;
  onSuccess: () => void;
}

export const ClientSignaturePad: React.FC<ClientSignaturePadProps> = ({ clientId, onSuccess }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [loading, setLoading] = useState(false);

  const getPos = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    return { x: clientX - rect.left, y: clientY - rect.top };
  };

  const start = (e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault();
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const pos = getPos(e);
    ctx.beginPath();
    ctx.moveTo(pos.x, pos.y);
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.strokeStyle = '#60a5fa';
    setIsDrawing(true);
  };

  const draw = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDrawing) return;
    e.preventDefault();
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (canvas && ctx) {
      const pos = getPos(e);
      ctx.lineTo(pos.x, pos.y);
      ctx.stroke();
    }
  };

  const clear = () => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (canvas && ctx) ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  const submit = async () => {
    const canvas = canvasRef.current;
    if (!canvas || loading) return;
    setLoading(true);
    try {
      const base64 = canvas.toDataURL('image/png');
      const blob = await (await fetch(base64)).blob();
      const path = `${clientId}_client.png`;

      await supabase.storage.from('project_signatures').upload(path, blob, { contentType: 'image/png', upsert: true });
      const { data: { publicUrl } } = supabase.storage.from('project_signatures').getPublicUrl(path);

      const updateData: any = { 
        approvalSignature: base64,
        client_signature_url: publicUrl
      };

      const { error } = await supabase.from('quotations').update(updateData).eq('unitNumber', clientId);
      if (error) {
        alert('Failed to save signature: ' + error.message);
      } else {
        onSuccess();
      }
    } catch (err: any) {
      alert('Error: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="backdrop-blur-md bg-white/5 border border-white/20 rounded-3xl p-6 text-white shadow-2xl space-y-4 animate-in fade-in slide-in-from-top-2 duration-300">
      <div className="border-b border-white/10 pb-2">
        <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">Sign to Approve Quotation</h4>
        <p className="text-[10px] text-slate-400 font-semibold mt-1">Please sign within the box below to approve this quotation.</p>
      </div>
      <div className="bg-slate-950 border border-white/15 rounded-2xl overflow-hidden relative h-40">
        <canvas
          ref={canvasRef}
          width={350}
          height={160}
          className="w-full h-full cursor-crosshair touch-none"
          onMouseDown={start}
          onMouseMove={draw}
          onMouseUp={() => setIsDrawing(false)}
          onMouseLeave={() => setIsDrawing(false)}
          onTouchStart={start}
          onTouchMove={draw}
          onTouchEnd={() => setIsDrawing(false)}
        />
      </div>
      <div className="flex gap-3">
        <button onClick={clear} disabled={loading} className="flex-1 py-3 bg-white/5 hover:bg-white/10 border border-white/10 text-slate-300 rounded-xl font-bold text-xs uppercase transition flex items-center justify-center gap-1.5 cursor-pointer">
          <RotateCcw size={14} /> Clear
        </button>
        <button onClick={submit} disabled={loading} className="flex-1 py-3 bg-gradient-to-r from-blue-500 to-indigo-600 hover:scale-[1.02] text-white rounded-xl font-bold text-xs uppercase transition flex items-center justify-center gap-1.5 cursor-pointer">
          {loading ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div> : <Check size={14} />} Approve & Sign
        </button>
      </div>
    </div>
  );
};
