import React from 'react';
import { AudioPlayerWithWaveform } from '../AudioPlayerWithWaveform';

interface ProjectMedia {
  url: string;
  name: string;
  createdAt: string;
  isAudio: boolean;
}

interface VoiceUpdatesProps {
  audioNotes: ProjectMedia[];
}

export const VoiceUpdates: React.FC<VoiceUpdatesProps> = ({ audioNotes }) => {
  const safeNotes = audioNotes || [];
  if (safeNotes.length === 0) return null;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between px-1">
        <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest font-extrabold">
          Voice Updates
        </span>
        <span className="text-[8px] font-black text-blue-400 uppercase tracking-widest bg-blue-500/10 border border-blue-500/20 px-2 py-0.5 rounded-md">
          {safeNotes.length} Notes
        </span>
      </div>
      <div className="space-y-3">
        {safeNotes.map((note) => {
          const dateLabel = new Date(note.createdAt).toLocaleDateString('en-IN', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          });
          return (
            <AudioPlayerWithWaveform key={note.url} audioUrl={note.url} dateStr={dateLabel} />
          );
        })}
      </div>
    </div>
  );
};
