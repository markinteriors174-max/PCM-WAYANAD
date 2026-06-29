import React from 'react';

interface RoomDetail {
  cost: number;
  finished: boolean;
}

interface LiveProgressTrackerProps {
  currentActiveRoom: string | null;
  roomCosts: Record<string, RoomDetail>;
  items: any[];
  totalUpdatedBudget: number;
}

export const LiveProgressTracker: React.FC<LiveProgressTrackerProps> = ({
  currentActiveRoom,
  roomCosts,
  items,
  totalUpdatedBudget,
}) => {
  const safeCosts = roomCosts || {};
  const safeItems = items || [];

  const allFinished =
    safeItems.length > 0 &&
    safeItems.every((item) => {
      const room = safeCosts[item.roomName];
      return room?.finished;
    });

  return (
    <div className="space-y-6">
      {currentActiveRoom && (
        <div className="bg-blue-600/20 border border-blue-500/30 text-blue-300 px-4 py-3 rounded-2xl flex items-center justify-between shadow-md animate-pulse">
          <span className="text-[10px] font-black uppercase tracking-widest text-slate-300">
            Current Work Status
          </span>
          <span className="text-xs font-black text-white uppercase bg-blue-600 px-3 py-1 rounded-xl">
            Fixing {currentActiveRoom}
          </span>
        </div>
      )}

      <div className="backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl p-5 text-white flex flex-col gap-4 shadow-xl">
        <div className="border-b border-white/10 pb-2">
          <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">
            Live Room Budget Tracker
          </h4>
        </div>

        {safeItems.length > 0 ? (
          <div className="space-y-3">
            {safeItems.map((item) => {
              const detail = safeCosts[item.roomName];
              const cost = detail?.cost || 0;
              const finished = detail?.finished || false;

              return (
                <div
                  key={item.roomName}
                  className="bg-white/5 border border-white/10 px-4 py-3 rounded-2xl flex justify-between items-center"
                >
                  <div>
                    <span className="text-xs font-black text-slate-200 block uppercase tracking-wide">
                      {item.roomName}
                    </span>
                    <span
                      className={`text-[8px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md mt-1 inline-block ${
                        finished
                          ? 'bg-green-500/20 text-green-300 border border-green-500/30'
                          : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                      }`}
                    >
                      {finished ? 'Finished' : 'In Progress'}
                    </span>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-black text-white">
                      ₹{cost.toLocaleString('en-IN')}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="text-center py-6 border border-dashed border-white/10 rounded-2xl">
            <p className="text-xs text-slate-400 font-semibold">No room entries to track.</p>
          </div>
        )}

        <div className="bg-slate-950/40 p-4 rounded-2xl border border-white/10 flex justify-between items-center mt-2">
          <div>
            <span className="text-[9px] font-black text-slate-400 block uppercase tracking-wider">
              {allFinished ? 'Final Combined Total' : 'Grand Total (Accumulated)'}
            </span>
            {allFinished && (
              <span className="text-[7px] font-black text-green-400 uppercase tracking-widest block mt-0.5 animate-pulse">
                All Rooms Finished
              </span>
            )}
          </div>
          <span className={`text-xl font-black ${allFinished ? 'text-green-400' : 'text-slate-300'}`}>
            ₹{totalUpdatedBudget.toLocaleString('en-IN')}
          </span>
        </div>
      </div>
    </div>
  );
};
