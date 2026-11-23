import React from 'react';
import { 
  X, Phone, MessageSquare, Image as ImageIcon, Camera, RefreshCw, Navigation 
} from 'lucide-react';
import { AutoSlideshow } from './AutoSlideshow';
import { InAppChatBox } from './client-portal/InAppChatBox';

interface ProjectMedia {
  url: string;
  name: string;
  createdAt: string;
  isAudio: boolean;
}

interface ProjectHubModalProps {
  isOpen: boolean;
  onClose: () => void;
  client: {
    name: string;
    phone: string;
    location: string;
    unitNumber: string;
    projectStatus?: string;
    latitude?: number;
    longitude?: number;
  };
  photos: ProjectMedia[];
  uploadingGallery: boolean;
  onGalleryUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
  galleryInputRef: React.RefObject<HTMLInputElement | null>;
}

export const ProjectHubModal: React.FC<ProjectHubModalProps> = ({
  isOpen,
  onClose,
  client,
  photos,
  uploadingGallery,
  onGalleryUpload,
  galleryInputRef,
}) => {
  if (!isOpen) return null;

  const cleanPhone = client.phone.replace(/\D/g, '');
  const phoneWithCountry = cleanPhone.startsWith('91') ? cleanPhone : `91${cleanPhone}`;
  const mapsUrl = client.latitude && client.longitude
    ? `https://www.google.com/maps/search/?api=1&query=${client.latitude},${client.longitude}`
    : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(client.location)}`;

  return (
    <div className="fixed inset-0 bg-slate-955/80 backdrop-blur-md z-[999] flex items-center justify-center p-4 overflow-y-auto no-scrollbar">
      {/* Modal Container */}
      <div className="w-full max-w-lg bg-slate-900/90 border border-white/10 rounded-[2rem] p-6 shadow-2xl flex flex-col gap-5 text-white max-h-[90vh] overflow-y-auto no-scrollbar relative animate-in fade-in zoom-in duration-200">
        
        {/* Header */}
        <div className="flex justify-between items-center border-b border-white/10 pb-4">
          <div>
            <span className="text-[10px] font-black text-blue-400 uppercase tracking-widest block">
              SITE: {client.unitNumber}
            </span>
            <h3 className="text-lg font-black tracking-wide uppercase">Project Hub</h3>
          </div>
          <button 
            onClick={onClose}
            title="Close"
            className="w-9 h-9 rounded-full bg-white/5 flex items-center justify-center text-slate-400 hover:text-white hover:bg-white/10 border border-white/10 transition cursor-pointer"
          >
            <X size={18} />
          </button>
        </div>

        {/* Quick Actions Toolbar */}
        <div className="grid grid-cols-3 gap-3 bg-white/5 border border-white/10 p-3 rounded-2xl">
          <a
            href={`tel:${client.phone}`}
            className="flex flex-col items-center justify-center py-2.5 bg-blue-600/10 border border-blue-500/20 hover:bg-blue-600/20 hover:border-blue-500/40 text-blue-300 rounded-xl transition text-center gap-1.5 no-underline"
          >
            <Phone size={18} />
            <span className="text-[10px] font-black uppercase tracking-wider">Call Admin</span>
          </a>

          <a
            href={`https://wa.me/${phoneWithCountry}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex flex-col items-center justify-center py-2.5 bg-green-600/10 border border-green-500/20 hover:bg-green-600/20 hover:border-green-500/40 text-green-300 rounded-xl transition text-center gap-1.5 no-underline"
          >
            <MessageSquare size={18} />
            <span className="text-[10px] font-black uppercase tracking-wider">WhatsApp</span>
          </a>

          <a
            href={mapsUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex flex-col items-center justify-center py-2.5 bg-indigo-600/10 border border-indigo-500/20 hover:bg-indigo-600/20 hover:border-indigo-500/40 text-indigo-300 rounded-xl transition text-center gap-1.5 no-underline"
          >
            <Navigation size={18} />
            <span className="text-[10px] font-black uppercase tracking-wider">Maps</span>
          </a>
        </div>

        {/* Tab content scrollable container */}
        <div className="flex flex-col gap-6 overflow-y-auto no-scrollbar pr-0.5">
          {/* Photo Vault Section */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl p-5 shadow-inner space-y-4">
            <div className="flex items-center justify-between border-b border-white/10 pb-2">
              <div className="flex items-center gap-2">
                <ImageIcon size={16} className="text-purple-400" />
                <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">
                  Photo Vault
                </h4>
              </div>
              
              <button 
                onClick={() => galleryInputRef.current?.click()}
                disabled={uploadingGallery}
                className="bg-purple-50/20 hover:bg-purple-55/35 text-purple-300 text-[9px] font-black uppercase tracking-wider px-2.5 py-1.5 rounded-xl transition flex items-center gap-1 disabled:opacity-50 border border-purple-500/30 cursor-pointer"
              >
                {uploadingGallery ? <RefreshCw size={10} className="animate-spin" /> : <Camera size={10} />}
                {uploadingGallery ? 'Uploading...' : 'Upload Design'}
              </button>
              
              <input 
                type="file" 
                ref={galleryInputRef} 
                id="camera-upload-modal"
                accept="image/*" 
                title="Upload Photo"
                className="hidden" 
                onChange={onGalleryUpload} 
              />
            </div>

            {/* Slideshow */}
            <AutoSlideshow images={photos.length > 0 ? photos.map(p => p.url) : []} />

            {/* Photo Grid */}
            {photos.length > 0 ? (
              <div className="grid grid-cols-3 gap-2">
                {photos.map((photo, idx) => (
                  <button 
                    key={photo.url} 
                    type="button"
                    className="aspect-square rounded-xl overflow-hidden border border-white/10 bg-slate-950 relative group cursor-pointer shadow-sm p-0 w-full"
                    onClick={() => globalThis.open(photo.url, '_blank')}
                  >
                    <img 
                      src={photo.url} 
                      alt={`Site Progress ${idx + 1}`} 
                      className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center">
                      <span className="text-[8px] text-white font-black uppercase tracking-wider bg-white/20 px-2 py-1 rounded-lg backdrop-blur-sm">
                        View
                      </span>
                    </div>
                  </button>
                ))}
              </div>
            ) : (
              <div className="text-center py-6 border border-dashed border-white/5 rounded-xl">
                <p className="text-[10px] text-slate-400 font-semibold">No project photos yet.</p>
              </div>
            )}
          </div>

          {/* Two-Way Chat Section */}
          <InAppChatBox clientId={client.unitNumber} />
        </div>
      </div>
    </div>
  );
};
