import React, { useEffect, useState } from 'react';
import { supabase } from '../../supabaseClient';
import { Camera, CheckCircle, Upload, Loader2, Image as ImageIcon } from 'lucide-react';

interface ClientPhotoUploadProps {
  uniqueCode: string;
}

interface InquiryFile {
  name: string;
  url: string;
}

export const ClientPhotoUpload: React.FC<ClientPhotoUploadProps> = ({ uniqueCode }) => {
  const [uploading, setUploading] = useState(false);
  const [statusMsg, setStatusMsg] = useState('');
  const [inquiries, setInquiries] = useState<InquiryFile[]>([]);
  const [loadingList, setLoadingList] = useState(true);

  const fetchInquiries = async () => {
    setLoadingList(true);
    try {
      const { data, error } = await supabase.storage.from('client_inquiries').list(uniqueCode, {
        limit: 50,
        sortBy: { column: 'name', order: 'desc' }
      });
      if (error) throw error;

      if (data) {
        const mapped = data.map(f => {
          const { data: { publicUrl } } = supabase.storage.from('client_inquiries').getPublicUrl(`${uniqueCode}/${f.name}`);
          return {
            name: f.name,
            url: publicUrl
          };
        });
        setInquiries(mapped);
      }
    } catch (err) {
      console.warn('Inquiry files list error:', err);
    } finally {
      setLoadingList(false);
    }
  };

  useEffect(() => {
    fetchInquiries();
  }, [uniqueCode]);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    setStatusMsg('');
    try {
      const path = `${uniqueCode}/${Date.now()}_${file.name}`;
      const { error } = await supabase.storage.from('client_inquiries').upload(path, file, { upsert: true });
      if (error) throw error;

      // Automatically trigger database row update to alert admin
      await supabase
        .from('quotations')
        .update({ revisionNote: 'REFERENCE_PHOTO_UPLOADED: Price quote requested.' })
        .eq('unitNumber', uniqueCode);

      setStatusMsg('Reference photo uploaded successfully! Our admin will review and send a quote.');
      fetchInquiries();
    } catch (err: any) {
      alert('Upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  const renderInquiriesContent = () => {
    if (loadingList) {
      return (
        <div className="flex justify-center py-4">
          <Loader2 className="animate-spin text-blue-500" size={16} />
        </div>
      );
    }
    if (inquiries.length > 0) {
      return (
        <div className="grid grid-cols-3 gap-2">
          {inquiries.map(img => (
            <button
              key={img.name}
              type="button"
              onClick={() => globalThis.open(img.url, '_blank')}
              className="aspect-square rounded-xl overflow-hidden border border-white/10 bg-slate-900 shadow-sm relative group cursor-pointer p-0 w-full"
            >
              <img src={img.url} alt="Inquiry design" className="w-full h-full object-cover group-hover:scale-105 transition" />
            </button>
          ))}
        </div>
      );
    }
    return (
      <div className="text-center py-4 bg-white/5 border border-dashed border-white/10 rounded-xl">
        <ImageIcon className="text-slate-600 mx-auto mb-1" size={18} />
        <p className="text-[9px] text-slate-400 font-semibold">No reference images submitted yet.</p>
      </div>
    );
  };

  return (
    <div className="space-y-4">
      <div className="border-b border-white/10 pb-2">
        <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
          <Camera size={14} className="text-blue-400" /> Request Live Price Quote
        </h4>
      </div>

      <div className="backdrop-blur-md bg-white/5 p-5 rounded-3xl border border-white/10 shadow-sm space-y-4">
        <p className="text-[10px] text-slate-400 font-bold leading-normal">
          Upload reference photos of design styles or room layouts you want quoted for your site.
        </p>

        <label className="flex flex-col items-center justify-center gap-2 py-6 border-2 border-dashed border-white/15 hover:border-blue-500/30 rounded-2xl cursor-pointer hover:bg-white/5 transition active:scale-[0.98]">
          <div className="bg-blue-500/10 p-3 rounded-full text-blue-400 border border-blue-500/20">
            <Upload size={20} />
          </div>
          <span className="text-xs font-bold text-slate-200">
            {uploading ? 'Uploading reference image...' : 'Choose or Capture Photo'}
          </span>
          <input type="file" accept="image/*" className="hidden" onChange={handleUpload} disabled={uploading} />
        </label>

        {statusMsg && (
          <div className="p-3 bg-green-500/10 text-xs text-green-400 font-bold rounded-xl border border-green-500/20 flex items-center gap-1.5 justify-center text-center">
            <CheckCircle size={14} className="shrink-0" />
            <span>{statusMsg}</span>
          </div>
        )}

        {/* Refreshless Inquiries List */}
        <div className="space-y-3 pt-2">
          <span className="text-[9px] font-black tracking-wider uppercase text-slate-400 block border-b border-white/5 pb-1">
            Submitted Reference Designs
          </span>
          
          {renderInquiriesContent()}
        </div>
      </div>
    </div>
  );
};
export default ClientPhotoUpload;
