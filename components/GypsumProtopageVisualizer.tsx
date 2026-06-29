import React, { useState, useEffect, useRef } from 'react';

// --- SUB-COMPONENTS FOR EACH STEP ---

interface CalcStepProps {
  length: number;
  width: number;
  centralDia: number;
  material: string;
  onSave: (l: number, w: number, c: number, m: string) => void;
}

const CalcStep: React.FC<CalcStepProps> = ({ length, width, centralDia, material, onSave }) => {
  const handleSave = () => {
    const lVal = Number.parseFloat((document.getElementById('calcL') as HTMLInputElement)?.value) || length;
    const wVal = Number.parseFloat((document.getElementById('calcW') as HTMLInputElement)?.value) || width;
    const cVal = Number.parseFloat((document.getElementById('calcCentral') as HTMLInputElement)?.value) || centralDia;
    const mVal = (document.getElementById('calcMat') as HTMLSelectElement)?.value || material;
    onSave(lVal, wVal, cVal, mVal);
  };

  return (
    <div className="space-y-3">
      <div className="bg-black/20 p-3 rounded-xl border border-white/5 space-y-2">
        <span className="text-xs font-semibold text-[#d4af37] uppercase tracking-wider">
          1. CALC Page (Manual Entry)
        </span>
        <div className="grid grid-cols-2 gap-2 pt-1">
          <div>
            <label htmlFor="calcL" className="block text-[10px] text-gray-400 mb-0.5">Length (L) - Feet</label>
            <input
              type="number"
              id="calcL"
              title="Length in Feet"
              placeholder="20.3"
              defaultValue={length}
              className="w-full bg-[#1c1814] border border-[#d4af37]/30 text-white text-xs rounded-lg p-2 focus:outline-none"
            />
          </div>
          <div>
            <label htmlFor="calcW" className="block text-[10px] text-gray-400 mb-0.5">Width (W) - Feet</label>
            <input
              type="number"
              id="calcW"
              title="Width in Feet"
              placeholder="15.7"
              defaultValue={width}
              className="w-full bg-[#1c1814] border border-[#d4af37]/30 text-white text-xs rounded-lg p-2 focus:outline-none"
            />
          </div>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div>
            <label htmlFor="calcCentral" className="block text-[10px] text-gray-400 mb-0.5">Central Dia (Feet)</label>
            <input
              type="number"
              id="calcCentral"
              title="Central Recess Diameter in Feet"
              placeholder="6.0"
              defaultValue={centralDia}
              className="w-full bg-[#1c1814] border border-[#d4af37]/30 text-white text-xs rounded-lg p-2 focus:outline-none"
            />
          </div>
          <div>
            <label htmlFor="calcMat" className="block text-[10px] text-gray-400 mb-0.5">Material Select</label>
            <select
              id="calcMat"
              title="Material Selection"
              defaultValue={material}
              className="w-full bg-[#1c1814] border border-[#d4af37]/30 text-[#d4af37] text-xs rounded-lg p-2 focus:outline-none"
            >
              <option value="gypsum">Gypsum Board Ceiling</option>
              <option value="pvc">PVC Ceiling Panels</option>
              <option value="vboard">V-Board Ceiling</option>
            </select>
          </div>
        </div>
      </div>
      <button
        onClick={handleSave}
        className="w-full py-2.5 rounded-xl font-bold text-xs bg-gradient-to-r from-[#d4af37] to-[#aa8421] text-black shadow-lg tracking-wide hover:opacity-90 active:scale-95 transition-all flex items-center justify-center gap-1 cursor-pointer"
      >
        Save Data & Open Visualizer (Next)
      </button>
    </div>
  );
};

interface SketchStepProps {
  length: number;
  width: number;
  isCircleLocked: boolean;
  canvasRef: React.RefObject<HTMLCanvasElement | null>;
  clearCanvasDraw: () => void;
  onNext: () => void;
}

const SketchStep: React.FC<SketchStepProps> = ({ length, width, isCircleLocked, canvasRef, clearCanvasDraw, onNext }) => {
  return (
    <div className="space-y-3">
      <div className="bg-black/20 p-3 rounded-xl border border-white/5 space-y-2">
        <span className="text-xs font-semibold text-[#d4af37] uppercase tracking-wider">
          2. 2D Canvas Sketching Layout
        </span>
        <div
          className="relative w-full h-44 bg-[#0a0806] rounded-xl border border-[#d4af37]/20 overflow-hidden cursor-crosshair flex flex-col items-center justify-center sketch-grid-bg"
          id="sketchPad"
        >
          <canvas id="liveSketchCanvas" ref={canvasRef} className="absolute inset-0 w-full h-full z-10" />
          {!isCircleLocked && (
            <div
              id="sketchOverlayTxt"
              className="absolute z-20 text-center text-gray-600 text-[10px] font-mono bg-black/50 px-2 py-1 rounded"
            >
              [ Tap & Hold 1 Sec to Snap Circle Shape ]
            </div>
          )}
          <div className="absolute top-2 left-2 z-20 font-mono text-[9px] text-[#d4af37]/60" id="matrixDimensionsDisplay">
            Grid Matrix Size: {length} x {width} Ft
          </div>
        </div>
      </div>
      <div className="flex gap-2">
        <button
          onClick={clearCanvasDraw}
          className="w-1/3 py-2 rounded-xl text-gray-400 border border-white/10 text-xs hover:text-white cursor-pointer"
        >
          Clear
        </button>
        <button
          onClick={onNext}
          className="w-2/3 py-2 rounded-xl font-bold text-xs bg-neutral-800 text-[#d4af37] border border-[#d4af37]/30 tracking-wide hover:bg-neutral-700 cursor-pointer"
        >
          Lock & Go to 360 Room
        </button>
      </div>
    </div>
  );
};

interface Orbit360StepProps {
  centralDia: number;
  fanType: string;
  acType: string;
  roomRef: React.RefObject<HTMLDivElement | null>;
  setFanType: (t: string) => void;
  setAcType: (t: string) => void;
  handleRoomMouseDown: (e: React.MouseEvent) => void;
  handleRoomMouseMove: (e: React.MouseEvent) => void;
  handleRoomMouseUp: () => void;
  handleRoomTouchStart: (e: React.TouchEvent) => void;
  handleRoomTouchMove: (e: React.TouchEvent) => void;
  saveAndTransferToMaterials: () => void;
}

const Orbit360Step: React.FC<Orbit360StepProps> = ({
  centralDia,
  fanType,
  acType,
  roomRef,
  setFanType,
  setAcType,
  handleRoomMouseDown,
  handleRoomMouseMove,
  handleRoomMouseUp,
  handleRoomTouchStart,
  handleRoomTouchMove,
  saveAndTransferToMaterials,
}) => {
  return (
    <div className="space-y-3">
      <div className="bg-black/20 p-3 rounded-xl border border-white/5 space-y-2">
        <span className="text-xs font-semibold text-[#d4af37] uppercase tracking-wider">
          3. 360 Orbit & Appliance Selector
        </span>
        
        {/* Using native button to avoid non-interactive listener & tabIndex warnings */}
        <button
          type="button"
          onMouseDown={handleRoomMouseDown}
          onMouseMove={handleRoomMouseMove}
          onMouseUp={handleRoomMouseUp}
          onMouseLeave={handleRoomMouseUp}
          onTouchStart={handleRoomTouchStart}
          onTouchMove={handleRoomTouchMove}
          onTouchEnd={handleRoomMouseUp}
          aria-label="3D Orbit ceiling view preview"
          className="relative w-full h-44 bg-[#0d0a08] rounded-xl border border-[#d4af37]/20 overflow-hidden flex items-center justify-center cursor-grab active:cursor-grabbing select-none perspective-600 focus:outline-none block text-left w-full"
        >
          {/* Using spans to avoid nesting div tags inside button tag */}
          <span
            id="mock3dRoom"
            ref={roomRef}
            className="block text-center space-y-2 z-10 p-3 transition-transform duration-75 dynamic-rotate mx-auto"
          >
            <span
              className="mx-auto w-24 h-24 rounded-full border-4 border-dashed border-[#d4af37]/60 flex items-center justify-center bg-amber-500/5 shadow-[0_0_15px_rgba(212,175,55,0.15)] block"
              id="previewCeilingCircle"
            >
              <span className="text-[9px] font-mono text-[#d4af37]" id="previewCircleText">
                Central Dia: {centralDia} Ft
              </span>
            </span>
            <span className="flex justify-center gap-3 text-[10px] font-mono text-gray-400 block">
              <span id="applianceFanLabel" className={fanType === 'ceiling' ? 'text-emerald-400' : 'text-amber-400'}>
                {fanType === 'ceiling' ? ' Ceiling_Fan' : ' Wall_Side_Fan'}
              </span>
              <span id="applianceAcLabel" className={acType === 'cassette' ? 'text-cyan-400' : 'text-blue-400'}>
                {acType === 'cassette' ? ' Central_Cassette_AC' : ' Normal_Split_AC'}
              </span>
            </span>
          </span>
          <span className="absolute bottom-2 right-2 bg-black/60 px-1.5 py-0.5 rounded text-[8px] font-mono text-gray-500 block">
            Drag to Rotate 360
          </span>
        </button>
        
        <div className="grid grid-cols-2 gap-2 pt-1">
          <div className="bg-black/40 p-2 rounded-lg border border-white/5 flex flex-col justify-between">
            <span className="text-[10px] text-gray-400 block mb-1">Fan Selection</span>
            <div className="flex gap-1">
              <button
                onClick={() => setFanType('ceiling')}
                id="btnFanC"
                className={`text-[9px] flex-1 py-1 rounded cursor-pointer ${
                  fanType === 'ceiling' ? 'bg-[#d4af37] text-black font-bold' : 'bg-neutral-800 text-gray-400'
                }`}
              >
                Ceiling
              </button>
              <button
                onClick={() => setFanType('wall')}
                id="btnFanW"
                className={`text-[9px] flex-1 py-1 rounded cursor-pointer ${
                  fanType === 'wall' ? 'bg-[#d4af37] text-black font-bold' : 'bg-neutral-800 text-gray-400'
                }`}
              >
                Wall
              </button>
            </div>
          </div>
          <div className="bg-black/40 p-2 rounded-lg border border-white/5 flex flex-col justify-between">
            <span className="text-[10px] text-gray-400 block mb-1">AC Type Selection</span>
            <div className="flex gap-1">
              <button
                onClick={() => setAcType('cassette')}
                id="btnAcC"
                className={`text-[9px] flex-1 py-1 rounded cursor-pointer ${
                  acType === 'cassette' ? 'bg-[#d4af37] text-black font-bold' : 'bg-neutral-800 text-gray-400'
                }`}
              >
                Central
              </button>
              <button
                onClick={() => setAcType('split')}
                id="btnAcS"
                className={`text-[9px] flex-1 py-1 rounded cursor-pointer ${
                  acType === 'split' ? 'bg-[#d4af37] text-black font-bold' : 'bg-neutral-800 text-gray-400'
                }`}
              >
                Split
              </button>
            </div>
          </div>
        </div>
      </div>
      <button
        onClick={saveAndTransferToMaterials}
        className="w-full py-2.5 rounded-xl font-bold text-xs bg-[#d4af37] text-black shadow-lg tracking-wide hover:opacity-90 active:scale-95 transition-all flex items-center justify-center gap-1 cursor-pointer"
      >
        Auto-Save Data to Materials Page
      </button>
    </div>
  );
};

interface DispatchStepProps {
  materialLabel: string;
  calculatedArea: number;
  qtyCross: number;
  qtyMain: number;
  qtyPeri: number;
  applianceNotes: string;
  onReset: () => void;
}

const DispatchStep: React.FC<DispatchStepProps> = ({
  materialLabel,
  calculatedArea,
  qtyCross,
  qtyMain,
  qtyPeri,
  applianceNotes,
  onReset,
}) => {
  return (
    <div className="space-y-3">
      <div className="bg-black/20 p-3 rounded-xl border border-white/5 space-y-2">
        <div className="flex justify-between items-center">
          <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
            4. MATERIALS Page (Dispatch List View)
          </span>
          <span className="bg-emerald-500/10 text-emerald-400 text-[8px] font-mono px-1.5 py-0.5 rounded border border-emerald-500/20">
            AUTO_SAVED_OK
          </span>
        </div>
        <div className="bg-[#261f17] rounded-xl border border-[#d4af37]/30 overflow-hidden shadow-lg">
          <div className="p-3 flex justify-between items-center border-b border-[#d4af37]/10 bg-[#32281d]">
            <span className="text-xs font-bold text-white uppercase tracking-wide" id="targetCategoryTitle">
              {materialLabel}
            </span>
          </div>
          <div className="p-3 space-y-2.5 text-xs font-mono bg-black/40">
            <div className="flex justify-between items-center text-gray-400 border-b border-white/5 pb-1">
              <span>Calculated Area:</span>
              <span className="text-white font-bold" id="lblFinalArea">
                {calculatedArea.toFixed(2)} SQFT
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span>Cross Channel (12ft):</span>
              <span className="text-[#d4af37] font-bold" id="lblQtyCross">
                {qtyCross} Nos
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span>Main Channel (12ft):</span>
              <span className="text-[#d4af37] font-bold" id="lblQtyMain">
                {qtyMain} Nos
              </span>
            </div>
            <div className="flex justify-between items-center border-b border-white/5 pb-1.5">
              <span>Wall Perimeter:</span>
              <span className="text-[#d4af37] font-bold" id="lblQtyPeri">
                {qtyPeri} Nos
              </span>
            </div>
            <div className="flex justify-between items-center text-emerald-400 font-sans text-[11px] pt-0.5">
              <span id="lblApplianceNotes">{applianceNotes}</span>
            </div>
          </div>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <button
          onClick={() => alert('PDF Generated with Dashboard Sync!')}
          className="py-2.5 rounded-xl font-bold text-xs bg-emerald-700 hover:bg-emerald-600 text-white text-center cursor-pointer"
        >
          Generate Layout PDF
        </button>
        <button
          onClick={onReset}
          className="py-2.5 rounded-xl font-bold text-xs bg-neutral-800 text-gray-400 hover:text-white border border-white/5 text-center cursor-pointer"
        >
          Test Again
        </button>
      </div>
    </div>
  );
};

// --- MAIN WRAPPER CONTAINER ---

export const GypsumProtopageVisualizer: React.FC = () => {
  // Step navigation (1: CALC, 2: SKETCH, 3: 360, 4: DISPATCH)
  const [step, setStep] = useState<number>(1);

  // Form parameters
  const [length, setLength] = useState<number>(20.3);
  const [width, setWidth] = useState<number>(15.7);
  const [centralDia, setCentralDia] = useState<number>(6); // Warning fix: no zero fractions
  const [material, setMaterial] = useState<string>('gypsum');

  // Appliance states
  const [fanType, setFanType] = useState<string>('ceiling');
  const [acType, setAcType] = useState<string>('cassette');

  // Canvas circle lock state
  const [isCircleLocked, setIsCircleLocked] = useState<boolean>(false);

  // 3D rotation state for Step 3 Orbit
  const [rotation, setRotation] = useState({ x: 10, y: -20 });
  const isDraggingRoom = useRef(false);
  const prevMousePos = useRef({ x: 0, y: 0 });

  // Calculation output state
  const [calculatedArea, setCalculatedArea] = useState<number>(318.71);
  const [qtyCross, setQtyCross] = useState<number>(24);
  const [qtyMain, setQtyMain] = useState<number>(8);
  const [qtyPeri, setQtyPeri] = useState<number>(7);
  const [applianceNotes, setApplianceNotes] = useState<string>('Appliance support channels added.');

  // References for elements
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const roomRef = useRef<HTMLDivElement | null>(null);
  const touchTimeoutRef = useRef<any>(null);
  const isDrawingRef = useRef(false);

  // Initialize Canvas events on Step 2
  useEffect(() => {
    if (step !== 2) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Set canvas dimensions based on its bounding box
    const rect = canvas.parentElement?.getBoundingClientRect();
    const widthVal = rect?.width || 350;
    const heightVal = rect?.height || 176; // h-44 = 176px
    canvas.width = widthVal;
    canvas.height = heightVal;

    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 2;
    ctx.lineCap = 'round';

    const drawPerfectCircle = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.strokeStyle = '#d4af37';
      ctx.shadowColor = '#d4af37';
      ctx.shadowBlur = 8;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(canvas.width / 2, canvas.height / 2, 45, 0, 2 * Math.PI);
      ctx.stroke();
      ctx.shadowBlur = 0;
      ctx.fillStyle = '#ffffff';
      ctx.font = '10px monospace';
      ctx.fillText(` SHAPE SNAP: ${centralDia} FT FIXED`, (canvas.width / 2) - 65, (canvas.height / 2) + 5);
    };

    if (isCircleLocked) {
      drawPerfectCircle();
    }

    const startDraw = (offsetX: number, offsetY: number) => {
      isDrawingRef.current = true;
      ctx.beginPath();
      ctx.moveTo(offsetX, offsetY);
      
      const overlay = document.getElementById('sketchOverlayTxt');
      if (overlay) overlay.style.display = 'none';

      if (touchTimeoutRef.current) clearTimeout(touchTimeoutRef.current);
      touchTimeoutRef.current = setTimeout(() => {
        if (isDrawingRef.current) {
          setIsCircleLocked(true);
          drawPerfectCircle();
          isDrawingRef.current = false;
        }
      }, 900);
    };

    const drawing = (offsetX: number, offsetY: number) => {
      if (!isDrawingRef.current) return;
      ctx.lineTo(offsetX, offsetY);
      ctx.stroke();
    };

    const endDraw = () => {
      isDrawingRef.current = false;
      if (touchTimeoutRef.current) clearTimeout(touchTimeoutRef.current);
    };

    // Mouse handlers
    const handleMouseDown = (e: MouseEvent) => {
      startDraw(e.offsetX, e.offsetY);
    };
    const handleMouseMove = (e: MouseEvent) => {
      drawing(e.offsetX, e.offsetY);
    };
    const handleMouseUp = () => {
      endDraw();
    };

    // Touch handlers
    const handleTouchStart = (e: TouchEvent) => {
      if (e.touches.length === 0) return;
      const t = e.touches[0];
      const r = canvas.getBoundingClientRect();
      startDraw(t.clientX - r.left, t.clientY - r.top);
    };
    const handleTouchMove = (e: TouchEvent) => {
      if (e.touches.length === 0) return;
      e.preventDefault();
      const t = e.touches[0];
      const r = canvas.getBoundingClientRect();
      drawing(t.clientX - r.left, t.clientY - r.top);
    };
    const handleTouchEnd = () => {
      endDraw();
    };

    canvas.addEventListener('mousedown', handleMouseDown);
    canvas.addEventListener('mousemove', handleMouseMove);
    canvas.addEventListener('mouseup', handleMouseUp);
    canvas.addEventListener('touchstart', handleTouchStart, { passive: false });
    canvas.addEventListener('touchmove', handleTouchMove, { passive: false });
    canvas.addEventListener('touchend', handleTouchEnd);

    return () => {
      canvas.removeEventListener('mousedown', handleMouseDown);
      canvas.removeEventListener('mousemove', handleMouseMove);
      canvas.removeEventListener('mouseup', handleMouseUp);
      canvas.removeEventListener('touchstart', handleTouchStart);
      canvas.removeEventListener('touchmove', handleTouchMove);
      canvas.removeEventListener('touchend', handleTouchEnd);
      if (touchTimeoutRef.current) clearTimeout(touchTimeoutRef.current);
    };
  }, [step, centralDia, isCircleLocked]);

  // Set rotation custom properties on mock3dRoom element to avoid inline JSX styling
  useEffect(() => {
    if (step === 3 && roomRef.current) {
      roomRef.current.style.setProperty('--rot-x', `${rotation.x}deg`);
      roomRef.current.style.setProperty('--rot-y', `${rotation.y}deg`);
    }
  }, [rotation, step]);

  // Step 1 Save Action Delegate
  const handleCalcSave = (lVal: number, wVal: number, cVal: number, mVal: string) => {
    setLength(lVal);
    setWidth(wVal);
    setCentralDia(cVal);
    setMaterial(mVal);
    setStep(2);
  };

  // Canvas Clear Action
  const clearCanvasDraw = () => {
    setIsCircleLocked(false);
    const canvas = canvasRef.current;
    if (canvas) {
      const ctx = canvas.getContext('2d');
      if (ctx) ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
    const overlay = document.getElementById('sketchOverlayTxt');
    if (overlay) overlay.style.display = 'block';
  };

  // Drag orbit handlers for Step 3 Orbit
  const handleRoomMouseDown = (e: React.MouseEvent) => {
    isDraggingRoom.current = true;
    prevMousePos.current = { x: e.clientX, y: e.clientY };
  };

  const handleRoomMouseMove = (e: React.MouseEvent) => {
    if (!isDraggingRoom.current) return;
    const deltaX = e.clientX - prevMousePos.current.x;
    const deltaY = e.clientY - prevMousePos.current.y;
    setRotation(prev => ({
      x: Math.max(-30, Math.min(30, prev.x - deltaY * 0.5)),
      y: prev.y + deltaX * 0.5
    }));
    prevMousePos.current = { x: e.clientX, y: e.clientY };
  };

  const handleRoomMouseUp = () => {
    isDraggingRoom.current = false;
  };

  const handleRoomTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 0) return;
    isDraggingRoom.current = true;
    prevMousePos.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  };

  const handleRoomTouchMove = (e: React.TouchEvent) => {
    if (!isDraggingRoom.current || e.touches.length === 0) return;
    const deltaX = e.touches[0].clientX - prevMousePos.current.x;
    const deltaY = e.touches[0].clientY - prevMousePos.current.y;
    setRotation(prev => ({
      x: Math.max(-30, Math.min(30, prev.x - deltaY * 0.5)),
      y: prev.y + deltaX * 0.5
    }));
    prevMousePos.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  };

  // Step 3 Material save and transition calculation
  const saveAndTransferToMaterials = () => {
    const area = length * width;
    setCalculatedArea(area);
    setQtyCross(Math.ceil(area / 13.5));
    setQtyMain(Math.ceil(area / 40));
    setQtyPeri(Math.ceil((length * 2 + width * 2) / 11));
    setApplianceNotes(`Framework sync ready for Fan (${fanType}) and AC (${acType}).`);
    setStep(4);
  };

  // Material text helper
  const getMaterialLabel = () => {
    const labels: Record<string, string> = {
      gypsum: 'GYPSUM BOARD CEILING',
      pvc: 'PVC CEILING (GYPSUM CHANNEL FRAME SETUP)',
      vboard: 'GRID CEILING (2X2 FRAMEWORK)',
    };
    return labels[material] || 'GYPSUM BOARD CEILING';
  };

  return (
    <div className="max-w-md mx-auto text-gray-200 rounded-3xl shadow-2xl overflow-hidden p-4 space-y-4 border border-[#d4af37]/30 custom-gradient-bg">
      {/* Local Stylesheet to avoid inline styles */}
      <style>{`
        .custom-gradient-bg {
          background-image: linear-gradient(180deg, #16120e 0%, #0c0a07 100%);
        }
        .sketch-grid-bg {
          background-image: radial-gradient(#d4af37 0.5px, transparent 0.5px);
          background-size: 16px 16px;
        }
        .perspective-600 {
          perspective: 600px;
        }
        .dynamic-rotate {
          transform: rotateX(var(--rot-x)) rotateY(var(--rot-y));
          transform-style: preserve-3d;
        }
      `}</style>

      {/* Header */}
      <div className="flex justify-between items-center border-b border-[#d4af37]/10 pb-2">
        <div>
          <span className="text-[10px] uppercase tracking-widest text-[#d4af37] font-bold">
            MARK GYPSUM PROTOPAGE
          </span>
          <h2 className="text-base font-bold text-white">AI Visualizer & Dispatch Test-Link</h2>
        </div>
        <span className="bg-amber-500/10 text-[#d4af37] text-[9px] font-mono px-2 py-0.5 rounded-full border border-[#d4af37]/30 animate-pulse">
          TEST_MODE_ACTIVE
        </span>
      </div>

      {/* Tabs / Step navigation indicator */}
      <div className="grid grid-cols-4 gap-1 bg-black/40 p-1 rounded-xl border border-white/5">
        <button
          onClick={() => setStep(1)}
          id="stepBtn1"
          className={`text-[10px] py-1.5 rounded-lg transition-all ${
            step === 1 ? 'font-bold bg-[#d4af37] text-black shadow-md' : 'font-medium text-gray-400 hover:text-white'
          }`}
        >
          1. CALC
        </button>
        <button
          onClick={() => setStep(2)}
          id="stepBtn2"
          className={`text-[10px] py-1.5 rounded-lg transition-all ${
            step === 2 ? 'font-bold bg-[#d4af37] text-black shadow-md' : 'font-medium text-gray-400 hover:text-white'
          }`}
        >
          2. SKETCH
        </button>
        <button
          onClick={() => setStep(3)}
          id="stepBtn3"
          className={`text-[10px] py-1.5 rounded-lg transition-all ${
            step === 3 ? 'font-bold bg-[#d4af37] text-black shadow-md' : 'font-medium text-gray-400 hover:text-white'
          }`}
        >
          3. 360
        </button>
        <button
          onClick={() => setStep(4)}
          id="stepBtn4"
          className={`text-[10px] py-1.5 rounded-lg transition-all ${
            step === 4 ? 'font-bold bg-[#d4af37] text-black shadow-md' : 'font-medium text-gray-400 hover:text-white'
          }`}
        >
          4. DISPATCH
        </button>
      </div>

      {/* Step Render delegates to standalone components to keep Cognitive Complexity low */}
      {step === 1 && (
        <CalcStep
          length={length}
          width={width}
          centralDia={centralDia}
          material={material}
          onSave={handleCalcSave}
        />
      )}

      {step === 2 && (
        <SketchStep
          length={length}
          width={width}
          isCircleLocked={isCircleLocked}
          canvasRef={canvasRef}
          clearCanvasDraw={clearCanvasDraw}
          onNext={() => setStep(3)}
        />
      )}

      {step === 3 && (
        <Orbit360Step
          centralDia={centralDia}
          fanType={fanType}
          acType={acType}
          rotation={rotation}
          roomRef={roomRef}
          setFanType={setFanType}
          setAcType={setAcType}
          handleRoomMouseDown={handleRoomMouseDown}
          handleRoomMouseMove={handleRoomMouseMove}
          handleRoomMouseUp={handleRoomMouseUp}
          handleRoomTouchStart={handleRoomTouchStart}
          handleRoomTouchMove={handleRoomTouchMove}
          saveAndTransferToMaterials={saveAndTransferToMaterials}
        />
      )}

      {step === 4 && (
        <DispatchStep
          materialLabel={getMaterialLabel()}
          calculatedArea={calculatedArea}
          qtyCross={qtyCross}
          qtyMain={qtyMain}
          qtyPeri={qtyPeri}
          applianceNotes={applianceNotes}
          onReset={() => setStep(1)}
        />
      )}
    </div>
  );
};
