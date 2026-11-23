import React, { useState, useEffect, useRef, useMemo } from 'react';
import { Volume2, Calendar, Play, Pause } from 'lucide-react';

interface AudioPlayerProps {
  audioUrl: string;
  dateStr: string;
}

export const AudioPlayerWithWaveform: React.FC<AudioPlayerProps> = ({ audioUrl, dateStr }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // Generate deterministic bar heights for the file
  const barHeights = useMemo(() => {
    const heights = [];
    let hash = 0;
    for (let i = 0; i < audioUrl.length; i++) {
      hash = (audioUrl.codePointAt(i) || 0) + ((hash << 5) - hash);
    }
    for (let i = 0; i < 40; i++) {
      const val = Math.abs(Math.sin(hash + i) * 25) + 5; // 5 to 30px height
      heights.push(val);
    }
    return heights;
  }, [audioUrl]);

  useEffect(() => {
    const audio = new Audio(audioUrl);
    audioRef.current = audio;

    const onTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };
    const onLoadedMetadata = () => {
      setDuration(audio.duration || 0);
    };
    const onEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
    };

    audio.addEventListener('timeupdate', onTimeUpdate);
    audio.addEventListener('loadedmetadata', onLoadedMetadata);
    audio.addEventListener('ended', onEnded);

    return () => {
      audio.pause();
      audio.removeEventListener('timeupdate', onTimeUpdate);
      audio.removeEventListener('loadedmetadata', onLoadedMetadata);
      audio.removeEventListener('ended', onEnded);
    };
  }, [audioUrl]);

  const togglePlay = () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().catch(err => console.warn('Audio playback failed:', err));
      setIsPlaying(true);
    }
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const width = canvas.width;
    const height = canvas.height;
    ctx.clearRect(0, 0, width, height);

    const progress = duration > 0 ? currentTime / duration : 0;
    const barWidth = 4;
    const gap = 3;
    const totalBars = barHeights.length;
    const startX = (width - (totalBars * (barWidth + gap) - gap)) / 2;

    barHeights.forEach((barHeight, idx) => {
      const x = startX + idx * (barWidth + gap);
      const isPlayed = (idx / totalBars) <= progress;
      const barY = (height - barHeight) / 2;

      ctx.beginPath();
      if (isPlayed) {
        const grad = ctx.createLinearGradient(0, barY, 0, barY + barHeight);
        grad.addColorStop(0, '#60a5fa'); // blue-400
        grad.addColorStop(1, '#3b82f6'); // blue-500
        ctx.fillStyle = grad;
        ctx.shadowBlur = 4;
        ctx.shadowColor = '#60a5fa';
      } else {
        ctx.fillStyle = 'rgba(255, 255, 255, 0.25)';
        ctx.shadowBlur = 0;
      }

      ctx.roundRect ? ctx.roundRect(x, barY, barWidth, barHeight, 2) : ctx.rect(x, barY, barWidth, barHeight);
      ctx.fill();
    });

    // Reset shadow
    ctx.shadowBlur = 0;
  }, [currentTime, duration, barHeights]);

  const handleScrub = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    const audio = audioRef.current;
    if (!canvas || !audio || duration === 0) return;

    const rect = canvas.getBoundingClientRect();
    let clientX = 0;
    if ('touches' in e) {
      if (e.touches.length > 0) {
        clientX = e.touches[0].clientX;
      } else return;
    } else {
      clientX = e.clientX;
    }

    const clickX = clientX - rect.left;
    const progress = Math.max(0, Math.min(1, clickX / rect.width));
    audio.currentTime = progress * duration;
    setCurrentTime(audio.currentTime);
  };

  const formatTime = (time: number) => {
    if (Number.isNaN(time)) return '0:00';
    const mins = Math.floor(time / 60);
    const secs = Math.floor(time % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-5 text-white flex flex-col gap-4 shadow-xl">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="bg-blue-500/20 text-blue-400 p-2.5 rounded-2xl border border-blue-500/30 shadow-inner">
            <Volume2 size={18} />
          </div>
          <div>
            <h5 className="text-xs font-black uppercase tracking-wider text-slate-200">Verbal Site Progress Update</h5>
            <p className="text-[10px] text-slate-400 font-semibold flex items-center gap-1 mt-0.5">
              <Calendar size={11} />
              <span>{dateStr}</span>
            </p>
          </div>
        </div>
        <span className="text-[9px] bg-blue-500/10 border border-blue-500/30 px-2 py-0.5 rounded-md font-black uppercase tracking-widest text-blue-300">
          Audio Note
        </span>
      </div>

      <div className="flex items-center gap-4">
        <button
          onClick={togglePlay}
          className="w-12 h-12 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white rounded-full flex items-center justify-center shadow-lg shadow-blue-500/25 hover:scale-105 active:scale-95 transition-all shrink-0 border border-white/15 cursor-pointer"
        >
          {isPlaying ? <Pause size={20} fill="currentColor" /> : <Play size={20} className="ml-1" fill="currentColor" />}
        </button>

        <div className="flex-1 flex flex-col gap-1.5">
          <canvas
            ref={canvasRef}
            width={240}
            height={40}
            onClick={handleScrub}
            onTouchStart={handleScrub}
            className="w-full h-10 cursor-pointer rounded"
          />
          <div className="flex justify-between text-[9px] text-slate-400 font-extrabold px-1">
            <span>{formatTime(currentTime)}</span>
            <span>{formatTime(duration)}</span>
          </div>
        </div>
      </div>
    </div>
  );
};
