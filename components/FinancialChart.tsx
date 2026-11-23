import React, { useEffect, useRef } from 'react';
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

interface FinancialChartProps {
  total: number;
  paid: number;
  balance: number;
}

export const FinancialChart: React.FC<FinancialChartProps> = ({ total, paid, balance }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const chartRef = useRef<Chart<'doughnut'> | null>(null);
  const paidPercent = total > 0 ? Math.min(100, Math.round((paid / total) * 100)) : 0;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    if (chartRef.current) {
      chartRef.current.destroy();
    }

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const chartInstance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Advance Received', 'Balance Due'],
        datasets: [{
          data: [paid, balance],
          backgroundColor: [
            '#10b981', // green-500
            '#ef4444'  // red-500
          ],
          borderColor: 'rgba(15, 23, 42, 0.8)',
          borderWidth: 2,
          hoverOffset: 4
        }]
      },
      options: {
        cutout: '75%',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(15, 23, 42, 0.95)',
            titleColor: '#fff',
            bodyColor: '#e2e8f0',
            bodyFont: {
              family: 'Inter',
              weight: 'bold'
            },
            padding: 10,
            cornerRadius: 12,
            callbacks: {
              label: function(context) {
                const val = context.raw as number;
                return ` ₹${val.toLocaleString('en-IN')}`;
              }
            }
          }
        },
        animation: {
          animateRotate: true,
          animateScale: true,
          duration: 1500,
          easing: 'easeOutQuart'
        }
      }
    });

    chartRef.current = chartInstance;

    return () => {
      if (chartRef.current) {
        chartRef.current.destroy();
      }
    };
  }, [paid, balance]);

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-6 text-white flex flex-col gap-5 shadow-xl">
      <div className="flex justify-between items-center border-b border-white/10 pb-3">
        <h4 className="text-xs font-black uppercase tracking-wider text-blue-300">
          Financial Progress
        </h4>
        <span className="text-[10px] font-black text-green-300 bg-green-500/10 border border-green-500/30 px-2.5 py-1 rounded-full">
          {paidPercent}% Cleared
        </span>
      </div>

      <div className="flex items-center gap-6">
        {/* Chart canvas wrap */}
        <div className="relative w-32 h-32 flex-shrink-0">
          <canvas ref={canvasRef} width={128} height={128} />
          {/* Centered label */}
          <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
            <span className="text-xl font-black leading-none text-white">{paidPercent}%</span>
            <span className="text-[8px] text-slate-400 font-extrabold uppercase tracking-widest mt-0.5">Cleared</span>
          </div>
        </div>

        {/* Financial info items */}
        <div className="flex-1 flex flex-col gap-3">
          <div className="bg-white/5 border border-white/15 px-3 py-2 rounded-xl">
            <span className="text-[8px] font-black text-slate-400 block uppercase tracking-wider">
              Total Contract Value
            </span>
            <span className="text-sm font-black text-white">
              ₹{total.toLocaleString('en-IN')}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 bg-green-500 rounded-full shrink-0" />
            <div className="flex-1">
              <span className="text-[8px] font-black text-slate-400 block uppercase tracking-wider">
                Paid (Advance)
              </span>
              <span className="text-xs font-extrabold text-green-400">
                ₹{paid.toLocaleString('en-IN')}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 bg-red-500 rounded-full shrink-0" />
            <div className="flex-1">
              <span className="text-[8px] font-black text-slate-400 block uppercase tracking-wider">
                Balance Due
              </span>
              <span className="text-xs font-extrabold text-red-400">
                ₹{balance.toLocaleString('en-IN')}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
