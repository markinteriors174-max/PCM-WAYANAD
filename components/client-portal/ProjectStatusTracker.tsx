import React, { useRef, useEffect } from 'react';

interface ProjectStatusTrackerProps {
  projectStatus: string;
}

const STAGES = ['Planning', 'Framing', 'Boarding', 'Finishing', 'Painting', 'Handover'];

export const ProjectStatusTracker: React.FC<ProjectStatusTrackerProps> = ({ projectStatus }) => {
  const currentStageIndex = STAGES.indexOf(projectStatus || 'Planning');
  const progressPercentage = STAGES.length > 1 
    ? (Math.max(0, currentStageIndex) / (STAGES.length - 1)) * 100 
    : 0;

  const progressRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (progressRef.current) {
      progressRef.current.style.width = `${progressPercentage}%`;
    }
  }, [progressPercentage]);

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-6 shadow-2xl space-y-4 text-white">
      <div className="flex justify-between items-center border-b border-white/10 pb-3">
        <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
          Project Status Tracker
        </h4>
        <span className="text-[9px] font-black text-blue-300 bg-blue-500/20 px-2.5 py-1 rounded-full border border-blue-500/30 uppercase">
          Stage: {projectStatus || 'Planning'}
        </span>
      </div>

      <div className="relative pt-4 pb-2">
        <div className="absolute top-7 left-3 right-3 h-1 bg-white/10 -translate-y-1/2 rounded-full z-0"></div>
        <div 
          ref={progressRef}
          className="absolute top-7 left-3 h-1 bg-gradient-to-r from-blue-500 to-indigo-500 -translate-y-1/2 rounded-full transition-all duration-500 z-0"
        ></div>

        <div className="relative flex justify-between z-10">
          {STAGES.map((stage, idx) => {
            const isCompleted = idx < currentStageIndex;
            const isActive = idx === currentStageIndex;
            
            let circleClass = 'bg-slate-900 border-white/20 text-slate-500';
            if (isCompleted) {
              circleClass = 'bg-blue-600 border-blue-600 text-white shadow-md shadow-blue-500/30';
            } else if (isActive) {
              circleClass = 'bg-slate-900 border-blue-400 text-blue-400 font-bold scale-110 shadow-lg shadow-blue-500/20 ring-4 ring-blue-500/20';
            }

            let textClass = 'text-slate-500 font-medium';
            if (isActive) {
              textClass = 'text-blue-400 font-black';
            } else if (isCompleted) {
              textClass = 'text-slate-300 font-bold';
            }
            
            return (
              <div key={stage} className="flex flex-col items-center group relative flex-1">
                <div className={`w-6 h-6 rounded-full flex items-center justify-center border-2 transition-all duration-300 ${circleClass}`}>
                  {isCompleted ? <span className="text-[10px] font-bold">✓</span> : <span className="text-[9px] font-extrabold">{idx + 1}</span>}
                </div>
                <span className={`text-[8px] font-black tracking-wider uppercase mt-2.5 text-center px-0.5 leading-tight ${textClass}`}>
                  {stage}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
