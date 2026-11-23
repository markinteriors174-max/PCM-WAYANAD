import React, { useState, useEffect } from 'react';

interface AutoSlideshowProps {
  images: string[];
}

export const AutoSlideshow: React.FC<AutoSlideshowProps> = ({ images }) => {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    if (!images || images.length <= 1) return;
    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % images.length);
    }, 3000); // 3 seconds interval
    return () => clearInterval(interval);
  }, [images]);

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-48 md:h-64 rounded-3xl overflow-hidden relative shadow-2xl border border-white/10 mb-6 flex flex-col items-center justify-center bg-white/5 backdrop-blur-md">
        <div className="w-10 h-10 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin mb-3"></div>
        <p className="text-xs text-slate-400 font-bold uppercase tracking-widest animate-pulse">Loading gallery...</p>
      </div>
    );
  }

  const customStyles = `
    @keyframes slideFadeIn {
      0% { opacity: 0; transform: scale(1.03); filter: blur(5px); }
      100% { opacity: 1; transform: scale(1); filter: blur(0); }
    }
    .slide-enter {
      animation: slideFadeIn 1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
    }
  `;

  return (
    <div className="w-full h-48 md:h-64 rounded-3xl overflow-hidden relative shadow-2xl border border-white/10 mb-6 group bg-slate-950">
      <style>{customStyles}</style>
      {images.map((img, idx) => {
        const isActive = idx === currentIndex;
        return (
          <div
            key={img}
            className={`absolute inset-0 transition-all duration-1000 ${
              isActive ? 'opacity-100 z-10 slide-enter' : 'opacity-0 z-0 pointer-events-none'
            }`}
          >
            <img src={img} alt="Project Slide" className="w-full h-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-transparent pointer-events-none"></div>
          </div>
        );
      })}
      
      {images.length > 1 && (
        <div className="absolute bottom-4 left-0 right-0 flex justify-center space-x-2 z-20">
          {images.map((img, idx) => (
            <button
              key={`dot-${img}`}
              onClick={() => setCurrentIndex(idx)}
              className={`w-2 h-2 rounded-full transition-all duration-300 cursor-pointer border-0 p-0 outline-none ${
                idx === currentIndex ? 'bg-blue-400 w-6 shadow-[0_0_8px_rgba(96,165,250,0.8)]' : 'bg-white/40 hover:bg-white/70'
              }`}
              aria-label={`Go to slide ${idx + 1}`}
            ></button>
          ))}
        </div>
      )}
    </div>
  );
};
