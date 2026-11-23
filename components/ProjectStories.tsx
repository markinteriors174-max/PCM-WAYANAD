import React, { useState, useEffect, useRef } from 'react';
import { X } from 'lucide-react';

interface ProjectMedia {
  url: string;
  name: string;
  createdAt: string;
  isAudio: boolean;
}

interface StoryViewerProps {
  stories: ProjectMedia[];
  initialIndex: number;
  onClose: () => void;
  clientName: string;
}

const StoryViewer: React.FC<StoryViewerProps> = ({ stories, initialIndex, onClose, clientName }) => {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [progress, setProgress] = useState(0);
  const progressIntervalRef = useRef<number | null>(null);

  const activeStory = stories[currentIndex];

  useEffect(() => {
    setProgress(0);

    if (progressIntervalRef.current) {
      clearInterval(progressIntervalRef.current);
    }

    const duration = 5000; // 5s slide duration
    const intervalTime = 50;
    const totalSteps = duration / intervalTime;
    let step = 0;

    progressIntervalRef.current = globalThis.setInterval(() => {
      step++;
      const currentProgress = (step / totalSteps) * 100;
      setProgress(currentProgress);

      if (step >= totalSteps) {
        if (progressIntervalRef.current) {
          clearInterval(progressIntervalRef.current);
        }
        if (currentIndex < stories.length - 1) {
          setCurrentIndex(prev => prev + 1);
        } else {
          onClose();
        }
      }
    }, intervalTime);

    return () => {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
      }
    };
  }, [currentIndex, stories.length, onClose]);

  const handleNext = () => {
    if (currentIndex < stories.length - 1) {
      setCurrentIndex(prev => prev + 1);
    } else {
      onClose();
    }
  };

  const handlePrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex(prev => prev - 1);
    }
  };

  const handleTap = (e: React.MouseEvent<HTMLButtonElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const width = rect.width;
    if (clickX < width * 0.3) {
      handlePrev();
    } else {
      handleNext();
    }
  };

  const formatDate = (isoStr: string) => {
    try {
      const date = new Date(isoStr);
      return date.toLocaleDateString('en-IN', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return '';
    }
  };

  return (
    <div className="fixed inset-0 bg-black/95 z-[9999] flex flex-col justify-between select-none">
      {/* Top Controls Overlay */}
      <div className="absolute top-4 left-0 right-0 z-[10000] px-4 py-2 space-y-3 bg-gradient-to-b from-black/85 to-transparent">
        {/* Progress Bar Indicators */}
        <div className="flex gap-1.5 w-full">
          {stories.map((story, idx) => {
            return (
              <div key={story.url} className="h-1 flex-1 bg-white/30 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-white rounded-full"
                  ref={(el) => {
                    if (el) {
                      if (idx === currentIndex) {
                        el.style.width = `${progress}%`;
                        el.style.transition = 'width 50ms linear';
                      } else if (idx < currentIndex) {
                        el.style.width = '100%';
                        el.style.transition = 'none';
                      } else {
                        el.style.width = '0%';
                        el.style.transition = 'none';
                      }
                    }
                  }}
                />
              </div>
            );
          })}
        </div>

        {/* Story Header */}
        <div className="flex justify-between items-center text-white">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-blue-600/30 flex items-center justify-center border border-white/20 overflow-hidden">
              <img src="/logo.png" alt="PCM Logo" className="w-6 h-6 object-contain" />
            </div>
            <div>
              <h4 className="text-xs font-black tracking-wide">{clientName.toUpperCase()}</h4>
              <p className="text-[8px] text-slate-300 font-bold uppercase tracking-wider">
                {formatDate(activeStory.createdAt)}
              </p>
            </div>
          </div>
          <button 
            onClick={onClose}
            title="Close"
            className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-white/80 hover:text-white hover:bg-white/20 transition-all border border-white/10 cursor-pointer"
          >
            <X size={16} />
          </button>
        </div>
      </div>

      {/* Main Image View Button */}
      <button 
        type="button"
        onClick={handleTap}
        className="flex-1 w-full flex items-center justify-center cursor-pointer p-4 bg-transparent border-0 outline-none"
      >
        <img 
          src={activeStory.url} 
          alt={`Story ${currentIndex + 1}`}
          className="max-h-[75vh] w-auto max-w-full object-contain rounded-2xl shadow-2xl border border-white/5"
          onDragStart={(e) => e.preventDefault()}
        />
      </button>

      {/* Caption footer */}
      <div className="absolute bottom-6 left-0 right-0 text-center px-6 z-50 py-4 bg-gradient-to-t from-black/85 to-transparent text-white">
        <p className="text-xs font-extrabold tracking-wide uppercase text-blue-400 mb-1">
          Daily Site Work Update
        </p>
        <p className="text-[9px] text-slate-400 font-semibold uppercase tracking-widest truncate max-w-xs mx-auto">
          {activeStory.name.replace(/^(gallery_|profile_|audio_)/, '')}
        </p>
      </div>
    </div>
  );
};

interface ProjectStoriesProps {
  stories: ProjectMedia[];
  clientName: string;
}

export const ProjectStories: React.FC<ProjectStoriesProps> = ({ stories, clientName }) => {
  const [activeStoryIndex, setActiveStoryIndex] = useState<number | null>(null);

  if (!stories || stories.length === 0) return null;

  const formatDateLabel = (isoStr: string) => {
    try {
      const date = new Date(isoStr);
      return date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' });
    } catch {
      return 'Update';
    }
  };

  return (
    <div className="flex flex-col gap-2 mb-2 relative z-10">
      <div className="flex items-center justify-between px-1">
        <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">
          Daily Site Stories
        </span>
        <span className="text-[8px] font-black text-blue-400 uppercase tracking-widest bg-blue-500/10 border border-blue-500/20 px-2 py-0.5 rounded-md">
          {stories.length} Live
        </span>
      </div>

      {/* Scrolling Stories Row */}
      <div className="flex items-center gap-4 overflow-x-auto no-scrollbar py-2">
        {stories.map((story, idx) => (
          <button
            key={story.url}
            onClick={() => setActiveStoryIndex(idx)}
            className="flex flex-col items-center gap-1.5 shrink-0 select-none group p-0 bg-transparent border-0 cursor-pointer"
          >
            {/* Story Ring */}
            <div className="w-16 h-16 rounded-full p-0.5 bg-gradient-to-tr from-blue-500 via-indigo-500 to-purple-500 group-hover:scale-105 transition-transform duration-200 shadow-lg shadow-blue-500/10">
              <div className="w-full h-full rounded-full bg-slate-950 p-0.5">
                <img 
                  src={story.url} 
                  alt={`Story thumbnail ${idx}`} 
                  className="w-full h-full object-cover rounded-full"
                />
              </div>
            </div>
            {/* Date label */}
            <span className="text-[9px] text-slate-300 font-extrabold uppercase tracking-wide group-hover:text-white transition-colors">
              {formatDateLabel(story.createdAt)}
            </span>
          </button>
        ))}
      </div>

      {activeStoryIndex !== null && (
        <StoryViewer 
          stories={stories}
          initialIndex={activeStoryIndex}
          onClose={() => setActiveStoryIndex(null)}
          clientName={clientName}
        />
      )}
    </div>
  );
};
