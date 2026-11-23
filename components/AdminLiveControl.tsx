import React, { useState } from 'react';
import { supabase } from '../supabaseClient';
import { Settings, FileText, Image as ImageIcon, CheckCircle, UploadCloud } from 'lucide-react';

interface AdminLiveControlProps {
  uniqueCode: string;
  onSuccess?: () => void;
}

export const AdminLiveControl: React.FC<AdminLiveControlProps> = ({ uniqueCode, onSuccess }) => {
  const [roomName, setRoomName] = useState('');
  const [plainRate, setPlainRate] = useState('');
  const [designRate, setDesignRate] = useState('');
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [statusMsg, setStatusMsg] = useState('');

  const handleUpload = async (file: File, bucket: string, path: string) => {
    const { error } = await supabase.storage.from(bucket).upload(path, file, { upsert: true });
    if (error) throw error;
    return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
  };

  const handleSendApproval = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!roomName || !plainRate || !designRate || !photoFile) return alert('Fill all fields and pick a photo');
    setLoading(true);
    try {
      const photoUrl = await handleUpload(photoFile, 'project-photos', `rooms/${uniqueCode}_${Date.now()}_${photoFile.name}`);
      const { error } = await supabase.from('project_rooms').insert({
        project_code: uniqueCode,
        room_name: roomName,
        plain_rate: Number.parseFloat(plainRate),
        design_rate: Number.parseFloat(designRate),
        design_photo_url: photoUrl,
        approval_status: 'pending'
      });
      if (error) throw error;
      setStatusMsg('Room rate sent for approval successfully!');
      setRoomName(''); setPlainRate(''); setDesignRate(''); setPhotoFile(null);
      if (onSuccess) onSuccess();
    } catch (err: any) {
      alert('Error: ' + err.message);
    } finally { setLoading(false); }
  };

  const handlePdfUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setLoading(true);
    try {
      const path = `${uniqueCode}/${Date.now()}_${file.name}`;
      await handleUpload(file, 'project_documents', path);
      setStatusMsg('Manual PDF injected successfully!');
      if (onSuccess) onSuccess();
    } catch (err: any) {
      alert('PDF upload failed: ' + err.message);
    } finally { setLoading(false); }
  };

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-6 text-slate-800 shadow-2xl space-y-6">
      <h2 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-2">
        <Settings className="text-blue-600 animate-pulse" /> Admin Live Control Panel
      </h2>
      <form onSubmit={handleSendApproval} className="space-y-4">
        <input type="text" placeholder="Room Name (e.g. Living Room)" required value={roomName} onChange={e => setRoomName(e.target.value)} className="w-full bg-white/70 border border-slate-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 outline-none transition font-semibold" />
        <div className="grid grid-cols-2 gap-4">
          <input type="number" placeholder="Plain Rate" required value={plainRate} onChange={e => setPlainRate(e.target.value)} className="w-full bg-white/70 border border-slate-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 outline-none transition font-semibold" />
          <input type="number" placeholder="Design Rate" required value={designRate} onChange={e => setDesignRate(e.target.value)} className="w-full bg-white/70 border border-slate-200 rounded-xl px-4 py-3 focus:ring-2 focus:ring-blue-500 outline-none transition font-semibold" />
        </div>
        <label className="flex items-center gap-3 bg-blue-50/50 border border-dashed border-blue-200 p-4 rounded-2xl cursor-pointer hover:bg-blue-50 transition active:scale-[0.98]">
          <ImageIcon className="text-blue-500 shrink-0" />
          <span className="text-xs font-semibold text-blue-700 truncate">{photoFile ? photoFile.name : 'Choose Gypsum Design Photo'}</span>
          <input type="file" accept="image/*" className="hidden" onChange={e => setPhotoFile(e.target.files?.[0] || null)} />
        </label>
        <button type="submit" disabled={loading} className="w-full py-3.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold transition flex items-center justify-center gap-2 uppercase text-xs tracking-wider shadow-lg active:scale-95 cursor-pointer">
          {loading ? 'Processing...' : 'Send for Approval'}
        </button>
      </form>
      <div className="border-t border-slate-100 pt-4 flex flex-col gap-3">
        <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest flex items-center gap-1.5"><FileText size={14} /> Inject Manual Branded PDF</h3>
        <label className="flex items-center justify-center gap-2 py-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-xl font-bold text-xs text-slate-700 cursor-pointer transition active:scale-[0.98]">
          <UploadCloud size={16} className="text-slate-500" />
          <span>Inject PDF Document</span>
          <input type="file" accept="application/pdf" className="hidden" onChange={handlePdfUpload} />
        </label>
      </div>
      {statusMsg && <div className="p-3 bg-green-50 text-xs text-green-700 font-bold rounded-xl border border-green-100 flex items-center gap-1.5 justify-center"><CheckCircle size={14} /> {statusMsg}</div>}
    </div>
  );
};
export default AdminLiveControl;
