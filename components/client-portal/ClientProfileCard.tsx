/* eslint-disable react/forbid-dom-props, react/forbid-component-props, sonarjs/no-inline-styles, react-native/no-inline-styles, jsx-a11y/no-static-element-interactions, jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-nested-interactive, sonarjs/cognitive-complexity, sonarjs/no-nested-template-literals, sonarjs/no-inverted-boolean-check, no-empty, no-nested-ternary */
import React, { useRef, useState } from 'react';
import { MapPin, Phone, Camera } from 'lucide-react';

interface ClientInfo {
  name: string;
  phone: string;
  location: string;
  unitNumber: string;
  client_selfie?: string;
}

interface ClientProfileCardProps {
  client: ClientInfo;
  setSelectedProject: (client: any) => void;
  uploadingPhoto: boolean;
  onPhotoUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
}

export const ClientProfileCard: React.FC<ClientProfileCardProps> = ({
  client,
  setSelectedProject,
  uploadingPhoto,
  onPhotoUpload,
}) => {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [showToast, setShowToast] = useState(false);

  const handleCopy = (text: string, e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(text)
      .then(() => {
        setShowToast(true);
        setTimeout(() => setShowToast(false), 2000);
      })
      .catch(err => {
        console.error('Failed to copy: ', err);
      });
  };

  const handlePhotoUploadClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    fileInputRef.current?.click();
  };

  return (
    <div 
      role="button"
      tabIndex={0}
      onClick={() => setSelectedProject(client)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          setSelectedProject(client);
        }
      }}
      className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-6 text-white shadow-2xl relative overflow-hidden group/card cursor-pointer hover:bg-white/15 transition-all outline-none focus:ring-2 focus:ring-blue-500"
    >
      <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 rounded-full -mr-10 -mt-10 blur-xl"></div>
      
      <div className="flex justify-between items-start gap-4">
        <div className="flex-1">
          {/* Header text container */}
          <div className="flex items-center gap-2 mb-1">
            <span className="text-[10px] font-black text-blue-300 uppercase tracking-widest block">
              PROJECT OWNER
            </span>
            <span className="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse" />
            <span className="text-[8px] font-bold text-slate-400 uppercase tracking-wider">
              Tap Card to Open Hub
            </span>
          </div>
          <h3 className="text-xl font-black leading-tight tracking-wide group-hover/card:text-blue-300 transition-colors">
            {client.name.toUpperCase()}
          </h3>

          {/* Details copyable fields */}
          <div className="mt-3 space-y-1.5">
            <p className="text-xs text-slate-300 font-semibold flex items-center gap-2">
              <MapPin size={13} className="text-blue-400 shrink-0" />
              <button
                type="button"
                onClick={(e) => handleCopy(client.location, e)}
                className="hover:text-blue-300 transition-colors bg-transparent border-0 p-0 cursor-pointer outline-none font-semibold text-xs text-left"
                title="Click to copy Location"
              >
                {client.location}
              </button>
            </p>

            <p className="text-xs text-slate-300 font-semibold flex items-center gap-2">
              <Phone size={13} className="text-blue-400 shrink-0" />
              <button
                type="button"
                onClick={(e) => handleCopy(client.phone, e)}
                className="hover:text-blue-300 transition-colors bg-transparent border-0 p-0 cursor-pointer outline-none font-semibold text-xs text-left"
                title="Click to copy Phone"
              >
                {client.phone}
              </button>
            </p>
          </div>
        </div>

        <div className="flex flex-col items-end gap-3 shrink-0">
          <button
            type="button"
            onClick={(e) => handleCopy(client.unitNumber.toUpperCase(), e)}
            className="bg-blue-500/20 border border-blue-500/30 text-blue-300 text-[10px] font-black tracking-wider px-3 py-1.5 rounded-xl uppercase hover:bg-blue-500/30 transition cursor-pointer z-10"
            title="Click to copy ID"
          >
            ID: {client.unitNumber.toUpperCase()}
          </button>
          
          <button
            type="button"
            className="relative w-16 h-16 rounded-full overflow-hidden border-2 border-blue-400/50 cursor-pointer group bg-slate-800 p-0 shadow-lg z-10"
            onClick={handlePhotoUploadClick}
            title="Upload Profile Photo"
          >
            {client.client_selfie ? (
              <img src={client.client_selfie} alt="Profile" className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-blue-300">
                <Camera size={20} />
              </div>
            )}
            <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
              {uploadingPhoto ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              ) : (
                <Camera size={16} className="text-white" />
              )}
            </div>
          </button>
          
          <input
            type="file"
            ref={fileInputRef}
            id="camera-upload-profile"
            title="Upload profile picture"
            accept="image/*"
            className="hidden"
            onChange={onPhotoUpload}
          />
        </div>
      </div>

      {showToast && (
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-slate-900/90 border border-emerald-500/30 text-emerald-400 text-[10px] font-black tracking-widest uppercase px-4 py-2 rounded-xl shadow-lg transition-all duration-300 animate-in fade-in slide-in-from-bottom-2 whitespace-nowrap z-20">
          Copied to Clipboard!
        </div>
      )}
    </div>
  );
};
export default ClientProfileCard;
