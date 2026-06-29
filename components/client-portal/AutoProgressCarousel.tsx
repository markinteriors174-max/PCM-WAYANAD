import React, { useState, useEffect } from 'react';
import { supabase } from '../../supabaseClient';

const DEF_IMGS = [
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80',
  'https://images.unsplash.com/photo-1600607687920-4e2a09be1587?auto=format&fit=crop&w=800&q=80'
];

export const AutoProgressCarousel: React.FC<{ clientId: string }> = ({ clientId }) => {
  const [images, setImages] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    let active = true;
    const fetchImages = async () => {
      try {
        setLoading(true);
        const { data: files } = await supabase.storage.from('project-photos').list(clientId, { limit: 100, sortBy: { column: 'name', order: 'desc' } });
        let urls: string[] = [];
        if (files && files.length > 0) {
          const filtered = files.filter(f => f.name !== '.emptyFolderPlaceholder' && !/\.(mp3|wav|m4a|ogg|amr|3gp)$/i.test(f.name));
          urls = filtered.map(f => supabase.storage.from('project-photos').getPublicUrl(`${clientId}/${f.name}`).data.publicUrl);
        }
        if (urls.length === 0) {
          const { data: rootFiles } = await supabase.storage.from('project-photos').list('', { limit: 100, sortBy: { column: 'name', order: 'desc' } });
          if (rootFiles) {
            const filtered = rootFiles.filter(f => f.name.toLowerCase().includes(clientId.toLowerCase()) && f.name !== '.emptyFolderPlaceholder' && !/\.(mp3|wav|m4a|ogg|amr|3gp)$/i.test(f.name));
            urls = filtered.map(f => supabase.storage.from('project-photos').getPublicUrl(f.name).data.publicUrl);
          }
        }
        if (active) setImages(urls.length > 0 ? urls : DEF_IMGS);
      } catch (err) {
        console.error('Carousel fetch error:', err);
        if (active) setImages(DEF_IMGS);
      } finally {
        if (active) setLoading(false);
      }
    };
    fetchImages();
    return () => { active = false; };
  }, [clientId]);

  useEffect(() => {
    if (images.length <= 1) return;
    const interval = setInterval(() => setCurrentIndex((prev) => (prev + 1) % images.length), 3000);
    return () => clearInterval(interval);
  }, [images]);

  if (loading) {
    return (
      <div className="w-full h-48 md:h-64 rounded-3xl overflow-hidden relative shadow-2xl border border-white/10 mb-6 flex flex-col items-center justify-center bg-white/5 backdrop-blur-md">
        <div className="w-10 h-10 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin mb-3"></div>
        <p className="text-xs text-slate-400 font-bold uppercase tracking-widest animate-pulse">Loading gallery...</p>
      </div>
    );
  }

  return (
    <div className="w-full h-48 md:h-64 rounded-3xl overflow-hidden relative shadow-2xl border border-white/10 mb-6 group bg-slate-950">
      {images.map((img, idx) => (
        <div
          key={img}
          className={`absolute inset-0 transition-all duration-1000 ${idx === currentIndex ? 'opacity-100 z-10' : 'opacity-0 z-0 pointer-events-none'}`}
        >
          <img src={img} alt="Project Slide" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent pointer-events-none"></div>
        </div>
      ))}
      {images.length > 1 && (
        <div className="absolute bottom-4 left-0 right-0 flex justify-center space-x-2 z-20">
          {images.map((img, idx) => (
            <button
              key={`dot-${img}`}
              onClick={() => setCurrentIndex(idx)}
              className={`w-2 h-2 rounded-full transition-all duration-300 cursor-pointer border-0 p-0 outline-none ${idx === currentIndex ? 'bg-blue-400 w-6 shadow-[0_0_8px_rgba(96,165,250,0.8)]' : 'bg-white/40 hover:bg-white/70'}`}
              aria-label={`Go to slide ${idx + 1}`}
            ></button>
          ))}
        </div>
      )}
    </div>
  );
};
