/* eslint-disable react/forbid-dom-props, react/forbid-component-props, sonarjs/no-inline-styles, react-native/no-inline-styles, jsx-a11y/no-static-element-interactions, jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-nested-interactive, sonarjs/cognitive-complexity, sonarjs/no-nested-template-literals, sonarjs/no-inverted-boolean-check, no-empty, no-nested-ternary */
import React, { useState, useEffect, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { 
  Phone, RefreshCw, LogOut, Menu, X, Share2, Loader2, 
  ChevronDown, ChevronUp, MapPin, DollarSign, CheckSquare, FileText, 
  MessageSquare, BarChart3, FileCheck, Receipt, QrCode, Download, Clock,
  Shield, ArrowUpRight
} from 'lucide-react';
import { FinancialLedger } from './client-portal/FinancialLedger';
import { PdfVault } from './client-portal/PdfVault';
import { ClientPhotoUpload } from './client-portal/ClientPhotoUpload';
import { RoomApprovalSection } from './client-portal/RoomApprovalSection';
import { CeilingCostEstimator } from './client-portal/CeilingCostEstimator';
import { QRCodeCanvas } from 'qrcode.react';
import { WorkerList } from './client-portal/WorkerList';
import { GypsumProtopageVisualizer } from './GypsumProtopageVisualizer';
import { InAppChatBox } from './client-portal/InAppChatBox';
import { convertAreaToRoundedSqFt } from '../utils/ceilingCalculations';

interface ClientPortalProps {
  clientId: string;
}

interface ClientInfo {
  name: string;
  phone: string;
  location: string;
  unitNumber: string;
  totalAmount: number;
  paidAmount: number;
  balanceAmount: number;
  current_active_room?: string | null;
  projectStatus?: string;
  latitude?: number | null;
  longitude?: number | null;
  items?: any[];
}

const SUPABASE_URL = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

const fetchWithTimeout = async (url: string, options: RequestInit = {}, timeoutMs = 8000): Promise<Response> => {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    clearTimeout(id);
    return response;
  } catch (error: any) {
    clearTimeout(id);
    if (error.name === 'AbortError') {
      throw new Error('Connection timed out. Please check your network connection.');
    }
    throw error;
  }
};

const PortalLoading = () => (
  <div className="min-h-screen bg-slate-955 flex items-center justify-center p-6 max-w-md mx-auto">
    <div className="text-center space-y-4">
      <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto shadow-[0_0_15px_rgba(59,130,246,0.5)]"></div>
      <p className="text-xs font-bold text-slate-400 uppercase tracking-widest animate-pulse">Loading client portal...</p>
    </div>
  </div>
);

interface PortalErrorProps {
  errorMsg: string;
  onRetry: () => void;
}

const PortalError: React.FC<PortalErrorProps> = ({ errorMsg, onRetry }) => (
  <div className="min-h-screen bg-slate-955 flex items-center justify-center p-6 max-w-md mx-auto text-white">
    <div className="backdrop-blur-md bg-white/5 w-full rounded-3xl p-8 border border-white/10 shadow-2xl text-center space-y-5">
      <div className="w-16 h-16 bg-red-500/10 text-red-400 rounded-full border border-red-500/20 flex items-center justify-center mx-auto shadow-lg shadow-red-500/5">
        <span className="text-3xl font-black">!</span>
      </div>
      <h3 className="text-lg font-black tracking-wide text-white">Connection Error</h3>
      <p className="text-xs text-slate-400 leading-relaxed font-semibold">{errorMsg}</p>
      <button
        onClick={onRetry}
        className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3.5 rounded-2xl transition shadow-lg shadow-blue-600/20 cursor-pointer"
      >
        Retry Connection
      </button>
    </div>
  </div>
);

const ClientPortal: React.FC<ClientPortalProps> = ({ clientId }) => {
  const [client, setClient] = useState<ClientInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeView, setActiveView] = useState<'project' | 'workers' | 'visualizer'>('project');
  const [expandedCard, setExpandedCard] = useState<string | null>('project_status');

  // GPS pinning states
  const [pinningGps, setPinningGps] = useState(false);

  // Real-time site progress photos states
  const [progressPhotos, setProgressPhotos] = useState<string[]>([]);
  const [loadingPhotos, setLoadingPhotos] = useState(false);

  // Interactive Room Approvals state
  const [rooms, setRooms] = useState<any[]>([]);

  // ── T3: Advanced Workflow States ──────────────────────────────
  // Stage progress tracker
  const [stageProgress, setStageProgress] = useState<Record<string, number>>({});

  // Change orders
  const [changeOrders, setChangeOrders] = useState<any[]>([]);
  const [approvingOrderId, setApprovingOrderId] = useState<string | null>(null);

  // Payment receipts
  const [paymentReceipts, setPaymentReceipts] = useState<any[]>([]);

  // Client extensions (UPI/bank for QR code)
  const [clientExtensions, setClientExtensions] = useState<any>(null);

  useEffect(() => {
    fetchClientData();
    fetchProgressPhotos();
    fetchAdvancedWorkflowData();
  }, [clientId]);

  useEffect(() => {
    if (!clientId) return;

    const quoteSubscription = supabase
      .channel(`public:quotations:unitNumber=eq.${clientId}`)
      .on('postgres_changes', { 
          event: '*', 
          schema: 'public', 
          table: 'quotations',
          filter: `unitNumber=eq.${clientId}`
        }, (payload: any) => {
          fetchClientData();
          if (payload?.new?.items) {
            try {
              const newItems = payload.new.items;
              if (Array.isArray(newItems) && newItems.length > 0) {
                let totalPlain = 0;
                let totalDesign = 0;
                let totalCenter = 0;
                newItems.forEach((item: any) => {
                  const quantity = item.quantity || 1;
                  const rate = item.rate || 0;
                  const isCeiling = item.isCeilingDesign === 1 || item.isCeilingDesign === true || item.isCeilingDesign === '1';
                  const hasCove = item.hasCove === 1 || item.hasCove === true || item.hasCove === '1';
                  const hasCentral = item.hasCentralDesign === 1 || item.hasCentralDesign === true || item.hasCentralDesign === '1';

                  let ceilingArea = 0;
                  if (isCeiling) {
                    if (item.length === 0 && item.width === 0 && (item.area || 0) > 0) {
                      const mainArea = (item.area / quantity) - (item.coveRft || 0) - (item.centralArea || 0);
                      ceilingArea = Math.max(0, mainArea);
                    } else {
                      ceilingArea = (item.length || 0) * (item.width || 0);
                    }
                  }

                  // USE DEFINITIVE CALCULATION LOGIC v3.1
                  const roundedSqFt = convertAreaToRoundedSqFt(ceilingArea, item.unit);
                  totalPlain += isCeiling ? (roundedSqFt * quantity * rate) : 0;

                  const roundedCoveSqFt = convertAreaToRoundedSqFt(item.coveRft || 0, item.unit);
                  const coveRateVal = (item.coveRate || 0) > 0 ? item.coveRate : rate;
                  totalDesign += hasCove ? (roundedCoveSqFt * quantity * coveRateVal) : 0;

                  const roundedCentralSqFt = convertAreaToRoundedSqFt(item.centralArea || 0, item.unit);
                  const centralRateVal = (item.centralRate || 0) > 0 ? item.centralRate : rate;
                  totalCenter += hasCentral ? (roundedCentralSqFt * quantity * centralRateVal) : 0;
                });
                if ('Notification' in globalThis && Notification.permission === 'granted') {
                  new Notification("MARK GYPSUM - WORK PROGRESS UPDATE", {
                    body: `ROOM DETAILS UPDATED! PLAIN: ₹${Math.round(totalPlain).toLocaleString('en-IN')} | DESIGN: ₹${Math.round(totalDesign).toLocaleString('en-IN')} | CENTER DESIGN: ₹${Math.round(totalCenter).toLocaleString('en-IN')}. Tap to check your Client Hub.`,
                    icon: '/logo.png'
                  });
                }
              }
            } catch (err) {
              console.warn('Failed to dispatch background Web Notification:', err);
            }
          }
      })
      .subscribe();

    if (typeof globalThis !== 'undefined' && 'Notification' in globalThis) {
      if (Notification.permission === 'default') {
        Notification.requestPermission();
      }
    }

    const clientSubscription = supabase
      .channel(`public:clients:unitNumber=eq.${clientId}`)
      .on('postgres_changes', { 
          event: '*', 
          schema: 'public', 
          table: 'clients',
          filter: `unitNumber=eq.${clientId}`
        }, () => {
          fetchClientData();
      })
      .subscribe();

    const roomsSubscription = supabase
      .channel(`public:project_rooms:project_code=eq.${clientId}`)
      .on('postgres_changes', {
          event: '*',
          schema: 'public',
          table: 'project_rooms',
          filter: `project_code=eq.${clientId}`
        }, () => {
          fetchRooms();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(quoteSubscription);
      supabase.removeChannel(clientSubscription);
      supabase.removeChannel(roomsSubscription);
    };
  }, [clientId]);

  // ── Realtime subscriptions for T3 tables ──────────────────────
  useEffect(() => {
    if (!clientId) return;

    // Live stage progress updates
    const stagesChannel = supabase
      .channel(`project_stages:${clientId}`)
      .on('postgres_changes', {
        event: '*', schema: 'public', table: 'project_stages',
        filter: `unit_number=eq.${clientId}`
      }, () => fetchStages())
      .subscribe();

    // Change order updates
    const changeOrdersChannel = supabase
      .channel(`change_orders:${clientId}`)
      .on('postgres_changes', {
        event: '*', schema: 'public', table: 'change_orders',
        filter: `unit_number=eq.${clientId}`
      }, () => fetchChangeOrders())
      .subscribe();

    // Payment receipts pushed from admin
    const receiptsChannel = supabase
      .channel(`payment_receipts:${clientId}`)
      .on('postgres_changes', {
        event: '*', schema: 'public', table: 'payment_receipts',
        filter: `unit_number=eq.${clientId}`
      }, () => fetchPaymentReceipts())
      .subscribe();

    return () => {
      supabase.removeChannel(stagesChannel);
      supabase.removeChannel(changeOrdersChannel);
      supabase.removeChannel(receiptsChannel);
    };
  }, [clientId]);

  const fetchClientData = async () => {
    if (!navigator.onLine) {
      setErrorMsg('No internet connection. Please check your network connection.');
      setLoading(false);
      setRefreshing(false);
      return;
    }
    setLoading(true);
    setErrorMsg(null);
    try {
      const resQuote = await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/quotations?unitNumber=eq.${clientId}`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }
      }, 8000);
      
      if (resQuote.status === 401 || resQuote.status === 403) {
        throw new Error('Supabase database sync failed: Invalid API key or unauthorized client initialization.');
      }

      if (resQuote.ok) {
        const quoteData = await resQuote.json();
        if (quoteData && quoteData.length > 0) {
          setClient({
            name: quoteData[0].clientName || '',
            phone: quoteData[0].clientPhone || '',
            location: quoteData[0].clientLocation || '',
            unitNumber: quoteData[0].unitNumber || '',
            totalAmount: quoteData[0].totalAmount || 0,
            paidAmount: quoteData[0].paidAmount || 0,
            balanceAmount: quoteData[0].balanceAmount || 0,
            current_active_room: quoteData[0].current_active_room || null,
            projectStatus: quoteData[0].projectStatus || 'Planning',
            latitude: quoteData[0].latitude || null,
            longitude: quoteData[0].longitude || null,
            items: quoteData[0].items || []
          });
          await fetchRooms();
          setLoading(false);
          setRefreshing(false);
          return;
        }
      }

      const resClient = await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/clients?unitNumber=eq.${clientId}`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }
      }, 8000);
      
      if (resClient.status === 401 || resClient.status === 403) {
        throw new Error('Supabase database sync failed: Invalid API key or unauthorized client initialization.');
      }

      if (resClient.ok) {
        const clientData = await resClient.json();
        if (clientData && clientData.length > 0) {
          setClient({
            name: clientData[0].client_name || '',
            phone: clientData[0].phone_number || '',
            location: clientData[0].site_location || '',
            unitNumber: clientData[0].unitNumber || '',
            totalAmount: clientData[0].total_contract_amount || 0,
            paidAmount: clientData[0].advance_received || 0,
            balanceAmount: clientData[0].balance_amount || 0,
            current_active_room: clientData[0].current_active_room || null,
            projectStatus: clientData[0].project_status || 'Planning',
            latitude: clientData[0].latitude || null,
            longitude: clientData[0].longitude || null,
            items: []
          });
          await fetchRooms();
        } else {
          setErrorMsg('Project account details not found. Please verify the link or contact Admin.');
        }
      } else {
        setErrorMsg('Failed to load project details.');
      }
    } catch (e: any) {
      console.error(e);
      setErrorMsg(e.message || 'Network error. Check your connection.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const fetchRooms = async () => {
    try {
      const { data: roomList } = await supabase.from('project_rooms').select('*').eq('project_code', clientId);
      if (roomList) setRooms(roomList);
    } catch (err) {
      console.warn('Failed to load project rooms:', err);
    }
  };

  const fetchProgressPhotos = async () => {
    if (!clientId) return;
    setLoadingPhotos(true);
    try {
      const res = await fetch(`${SUPABASE_URL}/storage/v1/object/list/project-photos`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          prefix: '',
          limit: 50,
          sortBy: { column: 'name', order: 'desc' }
        })
      });

      if (res.ok) {
        const files = await res.json();
        if (Array.isArray(files)) {
          const lowerId = clientId.toLowerCase();
          const photoUrls = files
            .filter(f => f.name.toLowerCase().includes(lowerId))
            .map(f => `${SUPABASE_URL}/storage/v1/object/public/project-photos/${f.name}`);
          setProgressPhotos(photoUrls);
        }
      }
    } catch (err) {
      console.warn('Failed to load progress photos:', err);
    } finally {
      setLoadingPhotos(false);
    }
  };

  const handlePinGPS = async () => {
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser");
      return;
    }
    setPinningGps(true);
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        try {
          const { error: clientErr } = await supabase
            .from('clients')
            .update({ latitude, longitude })
            .eq('unitNumber', clientId);

          const { error: quoteErr } = await supabase
            .from('quotations')
            .update({ latitude, longitude })
            .eq('unitNumber', clientId);

          if (clientErr || quoteErr) {
            throw new Error(clientErr?.message || quoteErr?.message || "Failed to save GPS coordinates");
          }

          alert("Site GPS coordinates successfully pinned!");
          fetchClientData();
        } catch (err: any) {
          alert("Failed to save GPS coordinates: " + err.message);
        } finally {
          setPinningGps(false);
        }
      },
      (error) => {
        console.error(error);
        alert("Could not retrieve geolocation: " + error.message);
        setPinningGps(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  const handleShare = async () => {
    const shareUrl = `${globalThis.location.origin}${globalThis.location.pathname}?clientId=${clientId}`;
    if (globalThis.navigator?.share) {
      try {
        await globalThis.navigator.share({
          title: 'PCM Project Portal',
          text: `Track real-time progress for project ${clientId} on PCM portal.`,
          url: shareUrl
        });
      } catch (err) {
        console.warn('Share failed:', err);
      }
    } else {
      try {
        await globalThis.navigator?.clipboard?.writeText(shareUrl);
        alert('Portal sharing link copied to clipboard!');
      } catch (err) {
        console.warn('Clipboard copy failed:', err);
        alert('Sharing link: ' + shareUrl);
      }
    }
  };

  const handleLogOut = () => {
    globalThis.localStorage?.removeItem('pcm_client_session_id');
    globalThis.location.href = '/';
  };

  const handleRefresh = () => {
    setRefreshing(true);
    fetchClientData();
    fetchProgressPhotos();
    fetchAdvancedWorkflowData();
  };

  // ══════════════════════════════════════════════════════════════
  //  T3: ADVANCED WORKFLOW DATA FETCHING
  // ══════════════════════════════════════════════════════════════

  const fetchAdvancedWorkflowData = useCallback(() => {
    fetchStages();
    fetchChangeOrders();
    fetchPaymentReceipts();
    fetchClientExtensions();
  }, [clientId]);

  const fetchStages = async () => {
    try {
      const { data } = await supabase
        .from('project_stages')
        .select('stage_name, completion_percent')
        .eq('unit_number', clientId);
      if (data) {
        const map: Record<string, number> = {};
        data.forEach((s: any) => { map[s.stage_name] = s.completion_percent; });
        setStageProgress(map);
      }
    } catch (err) { console.warn('fetchStages error:', err); }
  };

  const fetchChangeOrders = async () => {
    try {
      const { data } = await supabase
        .from('change_orders')
        .select('*')
        .eq('unit_number', clientId)
        .order('created_at', { ascending: false });
      if (data) setChangeOrders(data);
    } catch (err) { console.warn('fetchChangeOrders error:', err); }
  };

  const fetchPaymentReceipts = async () => {
    try {
      const { data } = await supabase
        .from('payment_receipts')
        .select('*')
        .eq('unit_number', clientId)
        .order('created_at', { ascending: false });
      if (data) setPaymentReceipts(data);
    } catch (err) { console.warn('fetchPaymentReceipts error:', err); }
  };

  const fetchClientExtensions = async () => {
    try {
      const { data } = await supabase
        .from('client_extensions')
        .select('*')
        .eq('unit_number', clientId)
        .single();
      if (data) setClientExtensions(data);
    } catch (err) { /* eslint-disable-next-line no-empty */ }
  };

  // ── Approve Change Order ────────────────────────────────────
  const handleApproveChangeOrder = async (orderId: string) => {
    setApprovingOrderId(orderId);
    try {
      const { error } = await supabase
        .from('change_orders')
        .update({
          status: 'approved',
          client_approved_at: new Date().toISOString(),
        })
        .eq('id', orderId);

      if (!error) {
        fetchChangeOrders();
        if ('Notification' in globalThis && Notification.permission === 'granted') {
          new Notification('PCM WAYANAD — Change Order Approved', {
            body: 'You have approved the extra work. The cost is now locked into your contract.',
            icon: '/logo.png',
          });
        }
      }
    } catch (err) {
      console.error('Approve change order error:', err);
    } finally {
      setApprovingOrderId(null);
    }
  };

  const downloadQRCode = () => {
    const canvas = document.getElementById('qr-gen-canvas') as HTMLCanvasElement;
    if (!canvas) return;
    const pngUrl = canvas.toDataURL('image/png');
    const downloadLink = document.createElement('a');
    downloadLink.href = pngUrl;
    downloadLink.download = `pcm-portal-share-${clientId}.png`;
    document.body.appendChild(downloadLink);
    downloadLink.click();
    downloadLink.remove();
  };

  const getStageIndex = (status?: string): number => {
    const s = (status || '').toLowerCase();
    if (s.includes('putty') || s.includes('paint')) return 3;
    if (s.includes('taping') || s.includes('joint') || s.includes('finish')) return 2;
    if (s.includes('board') || s.includes('fix')) return 1;
    return 0; 
  };

  const currentStageIndex = getStageIndex(client?.projectStatus);
  const stages = [
    'Channel Framing',
    'Board Fixing',
    'Taping & Jointing',
    'Putty Finishing'
  ];

  const toggleCard = (cardId: string) => {
    setExpandedCard(prev => prev === cardId ? null : cardId);
  };

  const renderCard = (
    id: string, 
    title: string, 
    subtitle: string, 
    icon: React.ReactNode, 
    content: React.ReactNode
  ) => {
    const isExpanded = expandedCard === id;
    return (
      <div 
        className={`backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl overflow-hidden shadow-xl transition-all duration-300 ${
          isExpanded ? 'border-white/20 bg-white/10 scale-[1.01] shadow-2xl' : 'hover:bg-white/10 hover:border-white/15'
        }`}
      >
        <button 
          type="button"
          onClick={() => toggleCard(id)}
          className="w-full text-left p-5 flex items-center justify-between cursor-pointer select-none hover:opacity-95 focus:outline-none bg-transparent"
        >
          <div className="flex items-center gap-3">
            <div className={`p-2.5 rounded-2xl bg-white/5 border border-white/5 text-blue-400 transition-colors duration-300 ${
              isExpanded ? 'bg-blue-500/10 border-blue-500/20 text-blue-400' : ''
            }`}>
              {icon}
            </div>
            <div>
              <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">{title}</h4>
              <p className="text-[10px] text-slate-400 font-bold mt-0.5">{subtitle}</p>
            </div>
          </div>
          <div className="text-slate-400">
            {isExpanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </div>
        </button>

        <div 
          className={`transition-all duration-300 ease-in-out ${
            isExpanded ? 'max-h-[1400px] border-t border-white/10 p-5 opacity-100' : 'max-h-0 opacity-0 pointer-events-none'
          } overflow-hidden`}
        >
          {content}
        </div>
      </div>
    );
  };

  const renderActiveView = () => {
    if (activeView === 'workers') {
      return <WorkerList />;
    }
    if (activeView === 'visualizer') {
      return <GypsumProtopageVisualizer />;
    }

    let progressWidthClass = 'w-0';
    if (currentStageIndex === 1) progressWidthClass = 'w-1/3';
    else if (currentStageIndex === 2) progressWidthClass = 'w-2/3';
    else if (currentStageIndex === 3) progressWidthClass = 'w-full';

    let progressPhotosContent = (
      <div className="text-center py-6 border border-dashed border-white/10 bg-white/5 rounded-2xl">
        <p className="text-xs text-slate-300 font-bold">No progress photos yet.</p>
        <p className="text-[9px] text-slate-400 font-semibold mt-1">Uploaded construction progress photos will appear here.</p>
      </div>
    );

    if (loadingPhotos) {
      progressPhotosContent = (
        <div className="flex justify-center py-6">
          <Loader2 className="animate-spin text-blue-500" size={20} />
        </div>
      );
    } else if (progressPhotos.length > 0) {
      progressPhotosContent = (
        <div className="grid grid-cols-2 gap-3">
          {progressPhotos.map((url, idx) => (
            <button 
              key={url} 
              type="button"
              className="aspect-square rounded-2xl overflow-hidden border border-white/10 bg-slate-900 relative group cursor-pointer shadow-sm p-0 w-full"
              onClick={() => globalThis.open(url, '_blank')}
            >
              <img 
                src={url} 
                alt={`Site progress ${idx + 1}`} 
                className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
              />
              <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center">
                <span className="text-[9px] text-white font-black uppercase tracking-wider bg-white/20 px-3 py-1.5 rounded-xl backdrop-blur-sm">
                  Open View
                </span>
              </div>
            </button>
          ))}
        </div>
      );
    }

    return (
      <div className="space-y-4">
        {/* Definitive Precision Cost Estimator v3.1 */}
        <CeilingCostEstimator />

        {/* Card 1: Project Details & Live Status */}
        {renderCard(
          'project_status',
          'Project Status & Site Info',
          `Current Phase: ${stages[currentStageIndex]}`,
          <MapPin size={18} />,
          <div className="space-y-5 text-white">
            {/* Stepper Status */}
            <div>
              <span className="text-[9px] font-black tracking-widest uppercase text-slate-400 block mb-1">
                Gypsum Installation Stage
              </span>
              <p className="text-xs font-bold text-blue-400 uppercase">
                {stages[currentStageIndex]}
              </p>
            </div>

            {/* Stepper Steps UI */}
            <div className="relative flex justify-between items-center w-full mt-2 px-1">
              <div className="absolute left-0 right-0 h-0.5 bg-white/10 -translate-y-4 top-1/2 z-0"></div>
              <div 
                className={`absolute left-0 h-0.5 bg-gradient-to-r from-blue-500 to-indigo-600 -translate-y-4 top-1/2 z-0 transition-all duration-500 ${progressWidthClass}`}
              ></div>
              {stages.map((stage, idx) => {
                const active = idx <= currentStageIndex;
                const current = idx === currentStageIndex;
                
                let stepClass = 'bg-slate-900 border-white/10 text-slate-500';
                if (current) {
                  stepClass = 'bg-blue-600 border-blue-400 text-white scale-110 shadow-[0_0_15px_rgba(59,130,246,0.6)] animate-pulse';
                } else if (active) {
                  stepClass = 'bg-indigo-950 border-indigo-500 text-indigo-300';
                }

                let textClass = 'text-slate-600';
                if (current) {
                  textClass = 'text-blue-400 font-extrabold';
                } else if (active) {
                  textClass = 'text-slate-300';
                }

                return (
                  <div key={stage} className="flex flex-col items-center z-10 relative">
                    <div className={`w-8 h-8 rounded-full border flex items-center justify-center text-xs font-black transition-all duration-300 ${stepClass}`}>
                      {idx + 1}
                    </div>
                    <span className={`text-[8px] font-black uppercase tracking-wider text-center mt-2 w-16 leading-tight transition-all duration-300 ${textClass}`}>
                      {stage.split(' ').join('\n')}
                    </span>
                  </div>
                );
              })}
            </div>

            {/* GPS Pinning Section */}
            <div className="border-t border-white/10 pt-4">
              <span className="text-[9px] font-black tracking-widest uppercase text-slate-400 block mb-1">
                Site GPS Geolocation
              </span>
              
              {client.latitude && client.longitude ? (
                <div className="text-[10px] text-slate-400 font-bold bg-white/5 border border-white/5 rounded-xl px-4 py-3 flex items-center justify-between mt-2">
                  <span className="flex items-center gap-1.5">
                    <MapPin size={12} className="text-blue-400" /> 
                    Pinned: {client.latitude.toFixed(6)}, {client.longitude.toFixed(6)}
                  </span>
                  <button 
                    onClick={handlePinGPS} 
                    disabled={pinningGps}
                    className="text-[9px] text-blue-400 font-black uppercase tracking-wider hover:text-blue-300 cursor-pointer disabled:opacity-50"
                  >
                    {pinningGps ? 'Pinning...' : 'Update'}
                  </button>
                </div>
              ) : (
                <button 
                  onClick={handlePinGPS} 
                  disabled={pinningGps}
                  className="w-full flex items-center justify-center gap-2 py-3 mt-2 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white rounded-xl font-black text-xs transition uppercase tracking-wider shadow-md shadow-blue-600/10 active:scale-[0.98] border border-white/10 cursor-pointer disabled:opacity-50"
                >
                  <MapPin size={14} className={pinningGps ? "animate-bounce" : ""} />
                  <span>{pinningGps ? 'Pinning Site GPS...' : 'Pin Site GPS'}</span>
                </button>
              )}
            </div>

            {/* Site Photos Section */}
            <div className="border-t border-white/10 pt-4 space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-[9px] font-black tracking-widest uppercase text-slate-400">
                  Live Site Progress Photos
                </span>
                <button onClick={fetchProgressPhotos} className="text-[9px] font-black text-blue-400 uppercase tracking-wider hover:text-blue-300 transition">
                  Refresh
                </button>
              </div>
              {progressPhotosContent}
            </div>
          </div>
        )}

        {/* Card 2: Financial Ledger & Payments */}
        {renderCard(
          'financial_ledger',
          'Financial Ledger',
          `Balance Due: ₹${(client.totalAmount - client.paidAmount).toLocaleString()}`,
          <DollarSign size={18} />,
          <FinancialLedger
            totalAmount={client.totalAmount}
            paidAmount={client.paidAmount}
            balanceAmount={client.balanceAmount}
            items={client.items || []}
          />
        )}

        {/* Card 3: Room Approvals */}
        {renderCard(
          'room_approvals',
          'Room Signature Approvals',
          `${rooms.filter(r => r.is_approved).length} of ${rooms.length} Rooms Approved`,
          <CheckSquare size={18} />,
          <RoomApprovalSection 
            uniqueCode={clientId} 
            clientName={client.name} 
            rooms={rooms} 
            onRefresh={fetchClientData} 
          />
        )}

        {/* Card 4: Documents & Files */}
        {renderCard(
          'documents_files',
          'Documents & Reference Files',
          'PDF Reports & Reference Uploads',
          <FileText size={18} />,
          <div className="space-y-4">
            <PdfVault uniqueCode={clientId} />
            <div className="border-t border-white/10 pt-4">
              <span className="text-[9px] font-black tracking-widest uppercase text-slate-400 block mb-2">
                Upload Custom Reference / Selfie
              </span>
              <ClientPhotoUpload uniqueCode={clientId} />
            </div>
          </div>
        )}

        {/* Card 5: Real-Time Chat Log */}
        {renderCard(
          'support_chat',
          'Support & In-App Chat',
          'Chat with PCM Site Managers',
          <MessageSquare size={18} />,
          <InAppChatBox clientId={clientId} />
        )}

        {/* ── T3: Live Stage Progress Tracker ─────────────── */}
        {Object.keys(stageProgress).length > 0 && renderCard(
          'live_progress',
          'Live Project Progress',
          `Overall: ${Math.round((Object.values(stageProgress) as number[]).reduce((a, b) => a + b, 0) / Math.max(Object.keys(stageProgress).length, 1))}% Complete`,
          <BarChart3 size={18} />,
          <div className="space-y-4 text-white">
            {(Object.entries(stageProgress) as [string, number][]).map(([stage, pct]) => (
              <div key={stage}>
                <div className="flex justify-between items-center mb-1">
                  <span className="text-[10px] font-black uppercase tracking-wider text-slate-300">{stage}</span>
                  <span className={`text-xs font-black ${
                    pct >= 100 ? 'text-green-400' : pct > 50 ? 'text-blue-400' : 'text-orange-400'
                  }`}>{pct}%</span>
                </div>
                <div className="w-full h-2.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-700 ease-out ${
                      pct >= 100 ? 'bg-gradient-to-r from-green-500 to-emerald-400' :
                      pct > 50 ? 'bg-gradient-to-r from-blue-500 to-indigo-400' :
                      'bg-gradient-to-r from-orange-500 to-amber-400'
                    }`}
                    style={{ width: `${Math.min(pct, 100)}%` }}
                  />
                </div>
              </div>
            ))}
            {/* Overall bar */}
            <div className="border-t border-white/10 pt-3">
              <div className="flex justify-between items-center mb-1">
                <span className="text-[10px] font-black uppercase tracking-widest text-slate-400">Overall Progress</span>
                <span className="text-sm font-black text-blue-400">
                  {Math.round((Object.values(stageProgress) as number[]).reduce((a, b) => a + b, 0) / Math.max(Object.keys(stageProgress).length, 1))}%
                </span>
              </div>
              <div className="w-full h-3 bg-white/10 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-blue-600 via-indigo-500 to-purple-500 transition-all duration-700"
                  style={{ width: `${Math.min(Math.round((Object.values(stageProgress) as number[]).reduce((a, b) => a + b, 0) / Math.max(Object.keys(stageProgress).length, 1)), 100)}%` }}
                />
              </div>
            </div>
          </div>
        )}

        {/* ── T3: Change Order Approvals ───────────────────── */}
        {changeOrders.length > 0 && renderCard(
          'change_orders',
          'Change Order Approvals',
          `${changeOrders.filter((o: any) => o.status === 'pending_approval').length} Pending`,
          <FileCheck size={18} />,
          <div className="space-y-4 text-white">
            {changeOrders.map((order: any) => (
              <div
                key={order.id}
                className={`p-4 rounded-2xl border ${
                  order.status === 'approved'
                    ? 'bg-green-500/10 border-green-500/20'
                    : 'bg-orange-500/10 border-orange-500/20'
                }`}
              >
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <p className="text-xs font-bold text-slate-200">{order.description}</p>
                    <p className="text-[10px] text-slate-400 mt-0.5">
                      {new Date(order.created_at).toLocaleDateString('en-IN', {
                        day: '2-digit', month: 'short', year: 'numeric'
                      })}
                    </p>
                  </div>
                  <span className="text-sm font-black text-white">
                    ₹{Number(order.extra_amount).toLocaleString('en-IN')}
                  </span>
                </div>

                {order.pdf_url && (
                  <a
                    href={order.pdf_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 text-[10px] font-bold text-blue-400 hover:text-blue-300 mb-3 no-underline"
                  >
                    <Download size={11} /> View Change Order PDF
                  </a>
                )}

                {order.status === 'pending_approval' ? (
                  <button
                    onClick={() => handleApproveChangeOrder(order.id)}
                    disabled={approvingOrderId === order.id}
                    className="w-full py-3 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white text-xs font-black uppercase tracking-wider rounded-xl transition shadow-lg shadow-green-600/20 active:scale-[0.98] cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2"
                  >
                    {approvingOrderId === order.id ? (
                      <><Loader2 size={14} className="animate-spin" /> Processing...</>
                    ) : (
                      <><Shield size={14} /> ✅ APPROVE CHANGE ORDER</>
                    )}
                  </button>
                ) : (
                  <div className="flex items-center gap-2 text-green-400">
                    <Shield size={14} />
                    <span className="text-[10px] font-black uppercase tracking-wider">
                      ✅ Approved {order.client_approved_at && ` — ${
                        new Date(order.client_approved_at).toLocaleDateString('en-IN', {
                          day: '2-digit', month: 'short', year: 'numeric'
                        })
                      }`}
                    </span>
                  </div>
                )}

                {order.status === 'approved' && (
                  <p className="text-[9px] text-green-300/70 mt-2 font-semibold">
                    This extra cost of ₹{Number(order.extra_amount).toLocaleString('en-IN')} is now locked into your total contract.
                  </p>
                )}
              </div>
            ))}
          </div>
        )}

        {/* ── T3: Payment Receipts History + Dynamic UPI QR ──── */}
        {renderCard(
          'payment_receipts',
          'Payment Receipts & Pay Now',
          `${paymentReceipts.length} Receipt${paymentReceipts.length !== 1 ? 's' : ''} Issued`,
          <Receipt size={18} />,
          <div className="space-y-5 text-white">
            {/* Dynamic UPI QR Code */}
            {(() => {
              const upiId = clientExtensions?.upi_id;
              const balanceDue = (client?.totalAmount ?? 0) - (client?.paidAmount ?? 0) - (clientExtensions?.discount_amount ?? 0);
              const approvedChanges = changeOrders
                .filter((o: any) => o.status === 'approved')
                .reduce((sum: number, o: any) => sum + (Number(o.extra_amount) || 0), 0);
              const totalBalance = Math.max(balanceDue + approvedChanges, 0);

              if (upiId && totalBalance > 0) {
                const upiUrl = `upi://pay?pa=${upiId}&pn=PCM+WAYANAD&am=${totalBalance.toFixed(2)}&cu=INR&tn=Balance+${clientId}`;
                return (
                  <div className="bg-gradient-to-br from-indigo-900/40 to-purple-900/40 border border-indigo-500/20 rounded-2xl p-5 flex flex-col items-center gap-3">
                    <div className="flex items-center gap-2">
                      <QrCode size={16} className="text-indigo-400" />
                      <span className="text-[10px] font-black uppercase tracking-widest text-indigo-300">Scan to Pay via UPI</span>
                    </div>
                    <div className="bg-white p-3 rounded-xl shadow-lg">
                      <QRCodeCanvas
                        value={upiUrl}
                        size={160}
                        bgColor="#ffffff"
                        fgColor="#1e1b4b"
                        level="H"
                        includeMargin={false}
                      />
                    </div>
                    <div className="text-center">
                      <p className="text-lg font-black text-white">
                        ₹{totalBalance.toLocaleString('en-IN')}
                      </p>
                      <p className="text-[9px] text-slate-400 font-bold mt-0.5">
                        Open any UPI app → Scan → Pay instantly
                      </p>
                    </div>
                    {clientExtensions?.bank_name && (
                      <div className="w-full bg-white/5 rounded-xl p-3 space-y-1">
                        <p className="text-[9px] font-black text-slate-400 uppercase tracking-wider">Or Transfer to Bank</p>
                        <p className="text-[10px] text-slate-300 font-bold">🏦 {clientExtensions.bank_name}</p>
                        <p className="text-[10px] text-slate-300 font-bold">A/C: {clientExtensions.account_number}</p>
                        <p className="text-[10px] text-slate-300 font-bold">IFSC: {clientExtensions.ifsc_code}</p>
                        <p className="text-[10px] text-slate-300 font-bold">UPI: {upiId}</p>
                      </div>
                    )}
                  </div>
                );
              }
              return null;
            })()}

            {/* Receipts list */}
            {paymentReceipts.length === 0 ? (
              <div className="text-center py-4 border border-dashed border-white/10 bg-white/5 rounded-2xl">
                <Receipt size={24} className="text-slate-600 mx-auto mb-2" />
                <p className="text-xs text-slate-400 font-bold">No payment receipts yet.</p>
                <p className="text-[9px] text-slate-500 font-semibold mt-0.5">
                  Receipts will appear here automatically after payments are recorded.
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="flex items-center gap-2 mb-1">
                  <Clock size={12} className="text-slate-400" />
                  <span className="text-[9px] font-black uppercase tracking-widest text-slate-400">Receipt History</span>
                </div>
                {paymentReceipts.map((receipt: any) => (
                  <div
                    key={receipt.id}
                    className="flex items-center justify-between p-3 bg-white/5 border border-white/10 rounded-xl"
                  >
                    <div>
                      <p className="text-xs font-black text-green-400">
                        + ₹{Number(receipt.amount_received).toLocaleString('en-IN')}
                      </p>
                      <p className="text-[9px] text-slate-400 font-bold mt-0.5">
                        {receipt.payment_date} • {receipt.payment_mode}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="text-right">
                        <p className="text-[9px] text-slate-400 font-bold">Bal: ₹{Number(receipt.balance_remaining).toLocaleString('en-IN')}</p>
                      </div>
                      {receipt.receipt_pdf_url && (
                        <a
                          href={receipt.receipt_pdf_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="p-2 bg-purple-500/20 border border-purple-500/30 rounded-lg text-purple-400 hover:text-purple-300 transition"
                          title="Download Receipt PDF"
                        >
                          <ArrowUpRight size={14} />
                        </a>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Global Share QR Card */}
        <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl flex flex-col items-center justify-center text-center gap-4 text-white">
          <div>
            <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">
              Share Our Service
            </h4>
            <p className="text-[9px] text-slate-400 font-semibold mt-1">
              Have prospects scan this QR to view premium designs and register site
            </p>
          </div>
          
          <button 
            type="button"
            onClick={downloadQRCode}
            className="bg-white p-4 rounded-2xl border border-white/10 cursor-pointer transition-all duration-200 hover:opacity-90 active:scale-95 shadow-md flex items-center justify-center"
            title="Click to download QR Code"
          >
            <QRCodeCanvas
              id="qr-gen-canvas"
              value="https://pcm-wayanad-portal.surge.sh/"
              size={120}
              bgColor="#ffffff"
              fgColor="#0f172a"
              level="H"
              includeMargin={false}
            />
          </button>
          
          <span className="text-[8px] text-blue-400 font-black tracking-widest uppercase">
            PCM WAYANAD ONLINE PORTAL
          </span>
        </div>
      </div>
    );
  };

  if (loading && !refreshing) {
    return <PortalLoading />;
  }

  if (errorMsg) {
    return <PortalError errorMsg={errorMsg} onRetry={fetchClientData} />;
  }

  if (!client) return null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 text-white py-8 px-4 flex flex-col justify-start max-w-md mx-auto relative pb-20 no-scrollbar overflow-x-hidden">
      
      {/* Background Animated Glows */}
      <div className="absolute top-20 left-10 w-48 h-48 bg-blue-600/10 rounded-full blur-3xl pointer-events-none animate-pulse duration-[6000ms]"></div>
      <div className="absolute bottom-40 right-10 w-48 h-48 bg-purple-600/10 rounded-full blur-3xl pointer-events-none animate-pulse duration-[8000ms]"></div>

      {/* Top Bar / Header */}
      <div className="flex justify-between items-center mb-6 relative z-10">
        <div className="flex items-center space-x-3">
          <img src="/logo.png" alt="PCM Logo" className="w-10 h-10 object-contain rounded-xl border border-white/20 bg-white/5 p-1" />
          <div>
            <h2 className="text-lg font-black text-white leading-tight">PREMIUM CEILING MASTER</h2>
            <p className="text-[10px] text-blue-400 font-black tracking-wider uppercase">GYPSUM CEILING & INTERIOR WORKS | WAYANAD</p>
          </div>
        </div>
        <div className="flex items-center space-x-2 relative">
          <button
            onClick={handleShare}
            className="p-2.5 bg-white/5 rounded-xl border border-white/10 text-slate-300 hover:text-white transition hover:bg-white/10 shadow-lg cursor-pointer"
            title="Share Portal Link"
          >
            <Share2 size={18} />
          </button>
          
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="p-2.5 bg-white/5 rounded-xl border border-white/10 text-slate-300 hover:text-white transition hover:bg-white/10 shadow-lg cursor-pointer"
            aria-label="Menu"
          >
            {menuOpen ? <X size={18} /> : <Menu size={18} />}
          </button>

          {menuOpen && (
            <div className="absolute right-0 top-12 w-48 bg-slate-900/95 backdrop-blur-xl rounded-2xl border border-white/10 shadow-2xl py-2 z-50 animate-in fade-in slide-in-from-top-2 duration-200">
              <button
                onClick={() => { setMenuOpen(false); handleRefresh(); }}
                className="w-full px-4 py-2.5 text-left text-xs font-bold text-slate-300 hover:text-white hover:bg-white/10 flex items-center space-x-2 transition cursor-pointer"
              >
                <RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />
                <span>Refresh Status</span>
              </button>
              
              <a
                href="https://wa.me/919383406185"
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => setMenuOpen(false)}
                className="w-full px-4 py-2.5 text-left text-xs font-bold text-slate-300 hover:text-white hover:bg-white/10 flex items-center space-x-2 transition block no-underline"
              >
                <Phone size={14} className="text-green-400" />
                <span>WhatsApp Support</span>
              </a>

              <div className="h-px bg-white/10 my-1"></div>

              <button
                onClick={handleLogOut}
                className="w-full px-4 py-2.5 text-left text-xs font-bold text-red-400 hover:bg-red-500/10 flex items-center space-x-2 transition cursor-pointer"
              >
                <LogOut size={14} />
                <span>Log Out</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* View Selector (Tabs) */}
      <div className="flex bg-white/5 border border-white/10 p-1 rounded-2xl mb-6 relative z-10">
        <button 
          onClick={() => setActiveView('project')}
          className={`flex-1 py-2 text-center text-xs font-bold rounded-xl transition cursor-pointer ${activeView === 'project' ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/25' : 'text-slate-400 hover:text-white'}`}
        >
          Project Details
        </button>
        <button 
          onClick={() => setActiveView('workers')}
          className={`flex-1 py-2 text-center text-xs font-bold rounded-xl transition cursor-pointer ${activeView === 'workers' ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/25' : 'text-slate-400 hover:text-white'}`}
        >
          Worker Ledger
        </button>
        <button 
          onClick={() => setActiveView('visualizer')}
          className={`flex-1 py-2 text-center text-xs font-bold rounded-xl transition cursor-pointer ${activeView === 'visualizer' ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/25' : 'text-slate-400 hover:text-white'}`}
        >
          AI Visualizer
        </button>
      </div>

      <div className="space-y-6 relative z-10">
        {renderActiveView()}
      </div>

      <div className="absolute bottom-4 left-0 right-0 text-center pointer-events-none">
        <p className="text-[8px] text-slate-500 font-black tracking-widest uppercase">
          PREMIUM CEILING MASTER • GYPSUM CEILING & INTERIOR WORKS • WAYANAD
        </p>
      </div>

    </div>
  );
};

export default ClientPortal;
