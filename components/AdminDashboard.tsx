import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import { 
  TrendingUp, CheckCircle, RefreshCw, LogOut, Loader2, 
  Settings, Play, Trash2, DollarSign
} from 'lucide-react';

interface ClientRecord {
  id: number;
  client_name: string;
  phone_number: string;
  site_location: string;
  unitNumber: string;
  total_contract_amount: number;
  advance_received: number;
  balance_amount: number;
  project_status: string;
  email: string | null;
  latitude: number | null;
  longitude: number | null;
}

interface QuotationRecord {
  id: number;
  unitNumber: string;
  clientName: string;
  totalAmount: number;
  paidAmount: number;
  balanceAmount: number;
  projectStatus: string;
  current_active_room?: string | null;
  room_costs?: Record<string, number>;
  total_updated_budget?: number;
}

export const AdminDashboard: React.FC = () => {
  const [clients, setClients] = useState<ClientRecord[]>([]);
  const [quotations, setQuotations] = useState<QuotationRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Settings
  const [resendApiKey, setResendApiKey] = useState('re_MockApiKey_123456789');
  const [adminEmail, setAdminEmail] = useState('admin@pcm.com');

  // Form states
  const [selectedSiteId, setSelectedSiteId] = useState<string>('');
  const [currentPhase, setCurrentPhase] = useState<string>('Channel Framing');
  const [currentActiveRoom, setCurrentActiveRoom] = useState<string>('');
  const [roomCosts, setRoomCosts] = useState<{ room: string; cost: number }[]>([]);
  const [newRoomName, setNewRoomName] = useState('');
  const [newRoomCost, setNewRoomCost] = useState('');

  // Site Expenses states
  const [expenseAmount, setExpenseAmount] = useState('');
  const [expenseRemarks, setExpenseRemarks] = useState('');
  const [expenseType, setExpenseType] = useState('Labor Wages');
  const [customCategory, setCustomCategory] = useState('');
  const [savingExpense, setSavingExpense] = useState(false);
  const [recentExpenses, setRecentExpenses] = useState<any[]>([]);

  // Archiving loading state
  const [archivingId, setArchivingId] = useState<string | null>(null);
  const [archiveStatus, setArchiveStatus] = useState<string>('');

  useEffect(() => {
    // Load settings from localStorage
    const savedKey = globalThis.localStorage?.getItem('pcm_resend_api_key');
    if (savedKey) setResendApiKey(savedKey);
    const savedAdmin = globalThis.localStorage?.getItem('pcm_admin_email');
    if (savedAdmin) setAdminEmail(savedAdmin);

    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const { data: clientsData } = await supabase.from('clients').select('*');
      const { data: quotesData } = await supabase.from('quotations').select('*');
      
      if (clientsData) setClients(clientsData);
      if (quotesData) setQuotations(quotesData);

      if (clientsData && clientsData.length > 0 && !selectedSiteId) {
        setSelectedSiteId(clientsData[0].unitNumber);
      }
    } catch (err) {
      console.error('Error fetching admin data:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const handleSaveSettings = () => {
    globalThis.localStorage?.setItem('pcm_resend_api_key', resendApiKey);
    globalThis.localStorage?.setItem('pcm_admin_email', adminEmail);
    alert('Admin Settings Saved!');
  };

  // Sync selected site info to local form states
  useEffect(() => {
    if (!selectedSiteId) return;
    const client = clients.find(c => c.unitNumber === selectedSiteId);
    const quote = quotations.find(q => q.unitNumber === selectedSiteId);

    if (client) {
      setCurrentPhase(client.project_status || 'Channel Framing');
    }
    if (quote) {
      setCurrentActiveRoom(quote.current_active_room || '');
      
      const parsedCosts = quote.room_costs || {};
      const costList = Object.keys(parsedCosts).map(room => ({
        room,
        cost: parsedCosts[room] || 0
      }));
      setRoomCosts(costList);
    } else {
      setRoomCosts([]);
      setCurrentActiveRoom('');
    }
  }, [selectedSiteId, clients, quotations]);

  // Form operations
  const handleAddRoomCost = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newRoomName.trim() || !newRoomCost) return;
    
    const cost = Number.parseFloat(newRoomCost);
    if (Number.isNaN(cost)) return;

    setRoomCosts(prev => {
      const existingIdx = prev.findIndex(item => item.room.toLowerCase() === newRoomName.trim().toLowerCase());
      if (existingIdx > -1) {
        const updated = [...prev];
        updated[existingIdx].cost = cost;
        return updated;
      }
      return [...prev, { room: newRoomName.trim(), cost }];
    });

    setNewRoomName('');
    setNewRoomCost('');
  };

  const handleRemoveRoomCost = (roomName: string) => {
    setRoomCosts(prev => prev.filter(r => r.room !== roomName));
  };

  const handleSaveRoomCosts = async () => {
    if (!selectedSiteId) return;
    
    // Construct room costs JSON object
    const costsObj: Record<string, number> = {};
    let totalBudget = 0;
    roomCosts.forEach(item => {
      costsObj[item.room] = item.cost;
      totalBudget += item.cost;
    });

    try {
      // Update quotations
      const { error: quoteErr } = await supabase
        .from('quotations')
        .update({
          room_costs: costsObj,
          total_updated_budget: totalBudget,
          current_active_room: currentActiveRoom || null,
          projectStatus: currentPhase
        })
        .eq('unitNumber', selectedSiteId);

      // Update clients
      const { error: clientErr } = await supabase
        .from('clients')
        .update({
          project_status: currentPhase
        })
        .eq('unitNumber', selectedSiteId);

      if (quoteErr || clientErr) {
        throw new Error(quoteErr?.message || clientErr?.message || 'Database update failed');
      }

      alert('Room costs and current phase synced successfully!');
      fetchData();
    } catch (err: any) {
      alert('Error updating costs: ' + err.message);
    }
  };

  const handleSaveExpense = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSiteId || !expenseAmount || Number(expenseAmount) <= 0) {
      alert('Please select a site and enter a valid amount');
      return;
    }

    if (expenseType === 'Other Expenses' && !customCategory.trim()) {
      alert('Please specify the custom category');
      return;
    }

    setSavingExpense(true);
    try {
      const { error } = await supabase.from('expenses').insert({
        project_id: selectedSiteId,
        expense_type: expenseType,
        custom_category: expenseType === 'Other Expenses' ? customCategory.trim() : null,
        amount: Number.parseFloat(expenseAmount),
        remarks: expenseRemarks,
        created_at: new Date().toISOString()
      });

      if (error) throw error;

      alert('Expense logged successfully!');
      setExpenseAmount('');
      setExpenseRemarks('');
      setCustomCategory('');
      fetchRecentExpenses(selectedSiteId);
    } catch (err: any) {
      console.error('Error saving expense:', err);
      alert('Failed to save expense: ' + err.message);
    } finally {
      setSavingExpense(false);
    }
  };

  const fetchRecentExpenses = async (siteId: string) => {
    try {
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .eq('project_id', siteId)
        .order('created_at', { ascending: false })
        .limit(5);

      if (error) throw error;
      setRecentExpenses(data || []);
    } catch (err) {
      console.error('Error fetching expenses:', err);
    }
  };

  const handleDeleteExpense = async (id: number) => {
    if (!globalThis.confirm('Delete this expense?')) return;
    try {
      const { error } = await supabase.from('expenses').delete().eq('id', id);
      if (error) throw error;
      fetchRecentExpenses(selectedSiteId);
    } catch (err: any) {
      alert('Error deleting: ' + err.message);
    }
  };

  useEffect(() => {
    if (selectedSiteId) {
      fetchRecentExpenses(selectedSiteId);
    }
  }, [selectedSiteId]);

  // Helper function for converting array buffer to base64
  const arrayBufferToBase64 = (buffer: Uint8Array) => {
    let binary = '';
    const len = buffer.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCodePoint(buffer[i]);
    }
    return globalThis.btoa(binary);
  };

  // Archive & Clean Up pipeline
  const handleArchiveProject = async (clientCode: string) => {
    const matchedClient = clients.find(c => c.unitNumber === clientCode);
    if (!matchedClient) return;

    if (!globalThis.confirm(`Are you sure you want to COMPLETE and ARCHIVE project ${clientCode}? This will generate a PDF summary, email it, delete the chat logs, and purge site-media files.`)) {
      return;
    }

    setArchivingId(clientCode);
    setArchiveStatus('Fetching project details...');
    try {
      // 1. Fetch data
      const { data: messages } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('site_id', clientCode)
        .order('created_at', { ascending: true });

      const { data: rooms } = await supabase
        .from('project_rooms')
        .select('*')
        .eq('project_code', clientCode);

      setArchiveStatus('Generating summary PDF report...');

      // 2. Generate PDF using pdf-lib
      const pdfDoc = await PDFDocument.create();
      let page = pdfDoc.addPage();
      const { height } = page.getSize();
      const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

      let y = height - 50;

      // Header Brand
      page.drawText('PREMIUM CEILING MASTER - WAYANAD', {
        x: 50,
        y,
        size: 16,
        font: fontBold,
        color: rgb(0.01, 0.52, 0.78),
      });
      y -= 15;
      page.drawText('PROJECT COMPLETION SUMMARY REPORT', {
        x: 50,
        y,
        size: 11,
        font: fontBold,
        color: rgb(0.4, 0.4, 0.4),
      });
      y -= 30;

      // Client & Project Information
      page.drawText(`Project Site ID: ${matchedClient.unitNumber}`, { x: 50, y, size: 9, font });
      page.drawText(`Client Name: ${matchedClient.client_name}`, { x: 300, y, size: 9, font });
      y -= 15;
      page.drawText(`Phone Number: ${matchedClient.phone_number}`, { x: 50, y, size: 9, font });
      page.drawText(`Location Address: ${matchedClient.site_location}`, { x: 300, y, size: 9, font });
      y -= 15;
      page.drawText(`Email Address: ${matchedClient.email || 'N/A'}`, { x: 50, y, size: 9, font });
      
      const geoText = matchedClient.latitude && matchedClient.longitude
        ? `${matchedClient.latitude.toFixed(5)}, ${matchedClient.longitude.toFixed(5)}`
        : 'Not pinned';
      page.drawText(`Site Geolocation: ${geoText}`, { x: 300, y, size: 9, font });
      y -= 25;

      // Financials Summary
      page.drawText('Financial Summary', { x: 50, y, size: 10, font: fontBold });
      y -= 15;
      page.drawText(`Contract Value: INR ${matchedClient.total_contract_amount.toLocaleString()}`, { x: 50, y, size: 9, font });
      page.drawText(`Advance Received: INR ${matchedClient.advance_received.toLocaleString()}`, { x: 220, y, size: 9, font });
      page.drawText(`Outstanding Balance: INR ${matchedClient.balance_amount.toLocaleString()}`, { x: 390, y, size: 9, font });
      y -= 25;

      // Rooms and Approvals
      page.drawText('Rooms & Sign-off Details', { x: 50, y, size: 10, font: fontBold });
      y -= 15;

      const projectRooms = rooms || [];
      if (projectRooms.length === 0) {
        page.drawText('No room layouts were sent for digital approval.', { x: 50, y, size: 8, font });
        y -= 15;
      } else {
        projectRooms.forEach((room: any, idx: number) => {
          if (y < 80) {
            page = pdfDoc.addPage();
            y = height - 50;
          }
          const text = `${idx + 1}. Room: ${room.room_name} | Plain: INR ${room.plain_rate}/sqft | Design: INR ${room.design_rate}/sqft | Sign-off: ${room.approval_status || 'Pending'}`;
          page.drawText(text, { x: 50, y, size: 8, font });
          y -= 15;
        });
      }
      y -= 15;

      // Chat Messages Log
      page.drawText('Real-time Project Chat Log', { x: 50, y, size: 10, font: fontBold });
      y -= 15;

      const chatMsgs = messages || [];
      if (chatMsgs.length === 0) {
        page.drawText('No support messages exchanged.', { x: 50, y, size: 8, font });
        y -= 15;
      } else {
        chatMsgs.forEach((m: any) => {
          if (y < 80) {
            page = pdfDoc.addPage();
            y = height - 50;
          }
          const sender = m.sender === 'client' ? 'Client' : 'Admin';
          const timeStr = new Date(m.created_at).toLocaleString();
          
          let msgContent = m.message || '';
          if (m.message_type === 'image') {
            msgContent = `📷 [IMAGE UPLOAD] ${m.message_content || ''}`;
          } else if (m.message_type === 'audio') {
            msgContent = `🎵 [AUDIO MESSAGE] ${m.message_content || ''}`;
          }
          
          const line = `[${timeStr}] ${sender}: ${msgContent}`;

          // Word-wrapping logic that splits lines safely by character count and words
          const lines: string[] = [];
          const words = line.split(' ');
          let currentLine = '';
          const maxChars = 90;
          
          words.forEach(word => {
            if ((currentLine + word).length > maxChars) {
              lines.push(currentLine.trim());
              currentLine = word + ' ';
            } else {
              currentLine += word + ' ';
            }
          });
          if (currentLine.trim()) {
            lines.push(currentLine.trim());
          }

          lines.forEach(l => {
            if (y < 80) {
              page = pdfDoc.addPage();
              y = height - 50;
            }
            page.drawText(l, { x: 50, y, size: 7.5, font });
            y -= 12;
          });
        });
      }

      const pdfBytes = await pdfDoc.save();
      const base64Pdf = arrayBufferToBase64(pdfBytes);

      setArchiveStatus('Blasting PDF emails via Resend transactional API...');

      // 3. Email PDF report to Admin & Client via Resend
      const emailsList = [adminEmail];
      if (matchedClient.email) {
        emailsList.push(matchedClient.email);
      }

      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from: 'PCM Archive System <archive@resend.dev>',
          to: emailsList,
          subject: `PCM Completion Report - Project ${clientCode}`,
          html: `
            <div style="font-family: sans-serif; padding: 25px; color: #1e293b; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; background-color: #ffffff;">
              <h2 style="color: #0284c7; margin-bottom: 10px;">Project Completed & Archived</h2>
              <p style="font-size: 14px; font-weight: bold; color: #475569;">Project site: ${clientCode}</p>
              <hr style="border: 0; border-top: 1px solid #f1f5f9; margin: 20px 0;"/>
              <p style="font-size: 14px; line-height: 1.6; color: #334155;">
                We are pleased to inform you that your ceiling installation project has been successfully completed. 
                A full project archive report has been generated containing:
              </p>
              <ul style="font-size: 13px; color: #475569; padding-left: 20px;">
                <li>Client and Site GPS Coordinates</li>
                <li>Digital Room Sign-off Signatures</li>
                <li>Financial Advance/Received ledgers</li>
                <li>Complete Support Chat records</li>
              </ul>
              <p style="font-size: 13px; color: #334155; line-height: 1.6;">Please find the official report attached to this email.</p>
              <div style="background-color: #f8fafc; border: 1px solid #cbd5e1; padding: 12px; border-radius: 8px; font-size: 12px; margin-top: 20px; color: #64748b; text-align: center;">
                PCM Wayanad Ceiling Master • Premium Quality Ceilings
              </div>
            </div>
          `,
          attachments: [
            {
              filename: `PCM_Summary_Report_${clientCode}.pdf`,
              content: base64Pdf
            }
          ]
        })
      });

      setArchiveStatus('Dropping chat logs & purging storage assets...');

      // 4. Extract site-media paths to delete
      const filesToDelete: string[] = [];
      chatMsgs.forEach((msg: any) => {
        if (msg.message_type === 'image' || msg.message_type === 'audio') {
          const contentUrl = msg.message_content || '';
          const parts = contentUrl.split('/site-media/');
          if (parts.length > 1) {
            filesToDelete.push(decodeURIComponent(parts[1]));
          }
        }
      });

      // 5. Delete heavy assets inside storage bucket
      if (filesToDelete.length > 0) {
        const { error: storageErr } = await supabase.storage
          .from('site-media')
          .remove(filesToDelete);
        
        if (storageErr) {
          console.warn('Storage purge skipped/failed:', storageErr.message);
        }
      }

      // 6. Delete chat messages
      await supabase
        .from('chat_messages')
        .delete()
        .eq('site_id', clientCode);

      // 7. Update status to completed in both clients and quotations tables
      await supabase
        .from('clients')
        .update({ project_status: 'completed' })
        .eq('unitNumber', clientCode);

      await supabase
        .from('quotations')
        .update({ projectStatus: 'completed' })
        .eq('unitNumber', clientCode);

      alert(`Project ${clientCode} successfully archived and cleaned! Report sent to registered emails.`);
      fetchData();

    } catch (err: any) {
      console.error(err);
      alert('Archiving pipeline encountered an error: ' + err.message);
    } finally {
      setArchivingId(null);
      setArchiveStatus('');
    }
  };

  // Financial statistics calculations
  const activeClients = clients.filter(c => c.project_status !== 'completed');
  
  const totalRevenueTarget = activeClients.reduce((acc, c) => acc + (c.total_contract_amount || 0), 0);
  const totalCashCollected = activeClients.reduce((acc, c) => acc + (c.advance_received || 0), 0);
  const totalBalanceDue = totalRevenueTarget - totalCashCollected;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 text-white py-8 px-4 flex flex-col justify-start max-w-4xl mx-auto relative pb-20 overflow-x-hidden">
      
      {/* Background Glows */}
      <div className="absolute top-10 left-10 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-20 right-10 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl pointer-events-none"></div>

      {/* Top Header */}
      <div className="flex justify-between items-center mb-8 relative z-10">
        <div className="flex items-center space-x-3">
          <img src="/logo.png" alt="PCM Logo" className="w-10 h-10 object-contain rounded-xl border border-white/20 bg-white/5 p-1" />
          <div>
            <h2 className="text-xl font-black text-white leading-tight">PCM ADMIN CONTROL</h2>
            <p className="text-[10px] text-blue-400 font-black tracking-wider uppercase">Operations & Financial Analytics</p>
          </div>
        </div>

        <div className="flex items-center space-x-2">
          <button 
            type="button"
            onClick={handleRefresh}
            className="p-2.5 bg-white/5 rounded-xl border border-white/10 text-slate-300 hover:text-white hover:bg-white/10 transition shadow-lg cursor-pointer"
            title="Refresh Data"
          >
            <RefreshCw size={16} className={refreshing ? 'animate-spin' : ''} />
          </button>
          
          <button 
            type="button"
            onClick={() => { globalThis.location.href = '/'; }}
            className="px-4 py-2.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-xl border border-red-500/20 text-xs font-bold transition flex items-center gap-1.5 cursor-pointer shadow-lg"
          >
            <LogOut size={14} />
            <span>Portal View</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex-1 flex flex-col items-center justify-center py-20 gap-4">
          <Loader2 className="animate-spin text-blue-500 w-10 h-10" />
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest animate-pulse">Loading Admin Center...</p>
        </div>
      ) : (
        <div className="space-y-8 relative z-10">
          
          {/* Section 1: Financial Analytics overview */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="backdrop-blur-md bg-white/5 border border-white/10 p-5 rounded-3xl shadow-xl space-y-2">
              <span className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Total Revenue Target</span>
              <p className="text-2xl font-black text-blue-400">₹{totalRevenueTarget.toLocaleString()}</p>
              <p className="text-[9px] text-slate-500 font-bold">Sum contract value of active projects</p>
            </div>
            
            <div className="backdrop-blur-md bg-white/5 border border-white/10 p-5 rounded-3xl shadow-xl space-y-2">
              <span className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Total Cash Collected</span>
              <p className="text-2xl font-black text-emerald-400">₹{totalCashCollected.toLocaleString()}</p>
              <p className="text-[9px] text-slate-500 font-bold">Sum advance paid across active projects</p>
            </div>

            <div className="backdrop-blur-md bg-white/5 border border-white/10 p-5 rounded-3xl shadow-xl space-y-2">
              <span className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Outstanding Balance</span>
              <p className="text-2xl font-black text-amber-400">₹{totalBalanceDue.toLocaleString()}</p>
              <p className="text-[9px] text-slate-500 font-bold">Balance yet to be collected</p>
            </div>
          </div>

          {/* Section 2: SVG Interactive Comparison Graph */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-4">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <TrendingUp size={14} className="text-blue-400" /> Active Revenue target vs. Cash Collected
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">Comparison charts compile total aggregate target revenue vs. cash collected</p>
            </div>

            {/* SVG Graph Component */}
            <div className="h-64 w-full flex items-center justify-center bg-slate-900/50 border border-white/5 rounded-2xl p-4">
              <svg className="w-full h-full" viewBox="0 0 500 220" preserveAspectRatio="none">
                {/* Y Axis Grid lines */}
                <line x1="45" y1="20" x2="480" y2="20" stroke="rgba(255,255,255,0.05)" strokeDasharray="3" />
                <line x1="45" y1="65" x2="480" y2="65" stroke="rgba(255,255,255,0.05)" strokeDasharray="3" />
                <line x1="45" y1="110" x2="480" y2="110" stroke="rgba(255,255,255,0.05)" strokeDasharray="3" />
                <line x1="45" y1="155" x2="480" y2="155" stroke="rgba(255,255,255,0.05)" strokeDasharray="3" />
                <line x1="45" y1="180" x2="480" y2="180" stroke="rgba(255,255,255,0.2)" />

                {/* Y Axis Labels */}
                <text x="35" y="24" fill="#64748b" fontSize="8" fontWeight="bold" textAnchor="end">100%</text>
                <text x="35" y="69" fill="#64748b" fontSize="8" fontWeight="bold" textAnchor="end">75%</text>
                <text x="35" y="114" fill="#64748b" fontSize="8" fontWeight="bold" textAnchor="end">50%</text>
                <text x="35" y="159" fill="#64748b" fontSize="8" fontWeight="bold" textAnchor="end">25%</text>
                <text x="35" y="184" fill="#64748b" fontSize="8" fontWeight="bold" textAnchor="end">0</text>

                {/* Draw 2 Side-by-Side Aggregated Columns */}
                {totalRevenueTarget > 0 ? (
                  <>
                    {/* Define Gradients */}
                    <defs>
                      <linearGradient id="targetGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#38bdf8" />
                        <stop offset="100%" stopColor="#0284c7" />
                      </linearGradient>
                      <linearGradient id="collectedGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#34d399" />
                        <stop offset="100%" stopColor="#059669" />
                      </linearGradient>
                    </defs>

                    {/* Column 1: Target Revenue */}
                    <rect 
                      x="160" 
                      y="20" 
                      width="50" 
                      height="160" 
                      rx="8" 
                      fill="url(#targetGrad)" 
                      className="transition-all duration-500 hover:opacity-90 cursor-pointer"
                    />
                    <text x="185" y="100" fill="#ffffff" fontSize="9" fontWeight="bold" textAnchor="middle">
                      ₹{(totalRevenueTarget / 1000).toFixed(0)}k
                    </text>
                    <text x="185" y="195" fill="#94a3b8" fontSize="8" fontWeight="bold" textAnchor="middle">Target Value</text>

                    {/* Column 2: Cash Collected */}
                    {/* Height proportional to cash collected percentage of target */}
                    {(() => {
                      const ratio = totalCashCollected / totalRevenueTarget;
                      const heightVal = 160 * ratio;
                      const yVal = 180 - heightVal;
                      return (
                        <>
                          <rect 
                            x="290" 
                            y={yVal} 
                            width="50" 
                            height={heightVal} 
                            rx="8" 
                            fill="url(#collectedGrad)" 
                            className="transition-all duration-500 hover:opacity-90 cursor-pointer"
                          />
                          <text x="315" y={yVal > 80 ? yVal - 8 : yVal + 18} fill={yVal > 80 ? "#34d399" : "#ffffff"} fontSize="9" fontWeight="bold" textAnchor="middle">
                            ₹{(totalCashCollected / 1000).toFixed(0)}k
                          </text>
                        </>
                      );
                    })()}
                    <text x="315" y="195" fill="#94a3b8" fontSize="8" fontWeight="bold" textAnchor="middle">Collected</text>
                  </>
                ) : (
                  <text x="250" y="100" fill="#64748b" fontSize="10" fontWeight="bold" textAnchor="middle">No active project financial data</text>
                )}
              </svg>
            </div>

            {/* Individual Client Progress lists */}
            <div className="space-y-3">
              <span className="text-[9px] font-black tracking-widest text-slate-500 uppercase">Individual Client Progress</span>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {activeClients.map(c => {
                  const percent = c.total_contract_amount > 0 ? (c.advance_received / c.total_contract_amount) * 100 : 0;
                  return (
                    <div key={c.id} className="bg-white/5 border border-white/5 rounded-2xl p-4 space-y-2">
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-xs font-bold text-slate-200">{c.client_name}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">{c.unitNumber} • {c.site_location}</p>
                        </div>
                        <span className="text-[10px] font-black text-blue-400">{percent.toFixed(0)}%</span>
                      </div>

                      {/* Horizontal progress bar */}
                      <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden border border-white/5">
                        <style>{`
                          .progress-bar-fill-${c.id} {
                            width: ${percent}%;
                          }
                        `}</style>
                        <div 
                          className={`h-full bg-gradient-to-r from-blue-500 to-emerald-500 transition-all duration-500 progress-bar-fill-${c.id}`}
                        ></div>
                      </div>

                      <div className="flex justify-between text-[8px] text-slate-500 font-bold uppercase">
                        <span>Coll: ₹{c.advance_received.toLocaleString()}</span>
                        <span>Target: ₹{c.total_contract_amount.toLocaleString()}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Section 3: Room Completion & Cost Updates Form */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-5">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <Settings size={14} className="text-blue-400" /> Room cost & progress manager
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">Select active project site to post updates and log room-specific costs.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Site and Status select form */}
              <div className="space-y-4">
                <div className="space-y-1">
                  <label htmlFor="activeSiteSelect" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Select Active Site</label>
                  <select 
                    id="activeSiteSelect"
                    title="Select Active Site"
                    value={selectedSiteId} 
                    onChange={e => setSelectedSiteId(e.target.value)}
                    className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-blue-500 transition font-semibold"
                  >
                    {clients.filter(c => c.project_status !== 'completed').map(c => (
                      <option key={c.id} value={c.unitNumber}>{c.client_name} ({c.unitNumber})</option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1">
                  <label htmlFor="stagePhaseSelect" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Overall Stage Phase</label>
                  <select 
                    id="stagePhaseSelect"
                    title="Overall Stage Phase"
                    value={currentPhase} 
                    onChange={e => setCurrentPhase(e.target.value)}
                    className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-blue-500 transition font-semibold"
                  >
                    <option value="Channel Framing">Channel Framing</option>
                    <option value="Board Fixing">Board Fixing</option>
                    <option value="Taping & Jointing">Taping & Jointing</option>
                    <option value="Putty Finishing">Putty Finishing</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label htmlFor="activeRoomInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Active Room in Progress</label>
                  <input 
                    id="activeRoomInput"
                    type="text"
                    placeholder="e.g. Master Bedroom"
                    value={currentActiveRoom}
                    onChange={e => setCurrentActiveRoom(e.target.value)}
                    className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-blue-500 transition font-semibold"
                  />
                </div>
              </div>

              {/* Room Cost logs */}
              <div className="space-y-4 bg-slate-900/50 border border-white/5 p-4 rounded-2xl flex flex-col">
                <span className="text-[9px] font-black tracking-widest text-slate-400 uppercase block mb-1">Room Budget & Cost Tracking</span>
                
                {/* Room list logs */}
                <div className="flex-1 max-h-36 overflow-y-auto space-y-2 pr-1 no-scrollbar">
                  {roomCosts.length > 0 ? roomCosts.map(item => (
                    <div key={item.room} className="flex justify-between items-center text-xs bg-white/5 border border-white/5 py-2 px-3 rounded-xl">
                      <div>
                        <span className="font-bold text-slate-200">{item.room}</span>
                        <span className="block text-[8px] text-slate-400">INR {item.cost.toLocaleString()}</span>
                      </div>
                      <button 
                        type="button"
                        onClick={() => handleRemoveRoomCost(item.room)}
                        className="text-red-400 hover:text-red-300 p-1 cursor-pointer"
                        title="Remove"
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  )) : (
                    <p className="text-[10px] text-slate-500 font-semibold text-center py-4">No room costs logged yet.</p>
                  )}
                </div>

                {/* Add new room cost form */}
                <div className="flex gap-2 border-t border-white/5 pt-3">
                  <label htmlFor="newRoomNameInput" className="sr-only">Room Name</label>
                  <input 
                    id="newRoomNameInput"
                    type="text" 
                    placeholder="Room Name"
                    value={newRoomName}
                    onChange={e => setNewRoomName(e.target.value)}
                    className="flex-1 bg-slate-955 border border-white/10 rounded-lg px-2.5 py-1.5 text-[10px] text-white focus:outline-none"
                  />
                  <label htmlFor="newRoomCostInput" className="sr-only">Cost (₹)</label>
                  <input 
                    id="newRoomCostInput"
                    type="number" 
                    placeholder="Cost (₹)"
                    value={newRoomCost}
                    onChange={e => setNewRoomCost(e.target.value)}
                    className="w-20 bg-slate-955 border border-white/10 rounded-lg px-2.5 py-1.5 text-[10px] text-white focus:outline-none"
                  />
                  <button 
                    type="button"
                    onClick={handleAddRoomCost}
                    className="px-3 bg-blue-600 hover:bg-blue-500 rounded-lg text-[9px] font-black uppercase text-white flex items-center justify-center cursor-pointer shadow"
                  >
                    Add
                  </button>
                </div>
              </div>
            </div>

            <button 
              type="button"
              onClick={handleSaveRoomCosts}
              className="w-full py-3.5 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white rounded-xl font-black text-xs transition uppercase tracking-wider shadow-lg shadow-blue-600/10 active:scale-[0.98] border border-white/10 cursor-pointer"
            >
              Sync & Deploy updates to client View
            </button>
          </div>

          {/* Section 4: Site Expenses Logging */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-5">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <DollarSign size={14} className="text-emerald-400" /> Site Expenses Logger
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">Log Labor, Transport, or Material expenses for the selected site.</p>
            </div>

            <form onSubmit={handleSaveExpense} className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="space-y-1">
                  <label htmlFor="expenseTypeSelect" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Expense Type</label>
                  <select
                    id="expenseTypeSelect"
                    value={expenseType}
                    title="Expense Type"
                    onChange={e => setExpenseType(e.target.value)}
                    className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-emerald-500 transition font-semibold"
                  >
                    <option value="Labor Wages">Labor Wages</option>
                    <option value="Vehicle / Transport Fare">Vehicle / Transport Fare</option>
                    <option value="Tools Rental">Tools Rental</option>
                    <option value="Other Expenses">Other Expenses</option>
                  </select>
                </div>

                {expenseType === 'Other Expenses' && (
                  <div className="space-y-1 animate-in fade-in zoom-in duration-200">
                    <label htmlFor="specifyCategoryInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Specify Category</label>
                    <input
                      id="specifyCategoryInput"
                      type="text"
                      placeholder="e.g. Cement, Paint, Food"
                      value={customCategory}
                      onChange={e => setCustomCategory(e.target.value)}
                      className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-emerald-500 transition font-semibold"
                    />
                  </div>
                )}

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label htmlFor="expenseAmountInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Amount (₹)</label>
                    <input
                      id="expenseAmountInput"
                      type="number"
                      placeholder="0.00"
                      value={expenseAmount}
                      onChange={e => setExpenseAmount(e.target.value)}
                      className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-emerald-500 transition font-semibold"
                    />
                  </div>
                  <div className="space-y-1">
                    <label htmlFor="expenseRemarksInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Remarks</label>
                    <input
                      id="expenseRemarksInput"
                      type="text"
                      placeholder="Optional notes"
                      value={expenseRemarks}
                      onChange={e => setExpenseRemarks(e.target.value)}
                      className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-emerald-500 transition font-semibold"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={savingExpense}
                  className="w-full py-3 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white rounded-xl font-black text-xs transition uppercase tracking-wider shadow-lg active:scale-[0.98] cursor-pointer"
                >
                  {savingExpense ? 'Saving...' : 'Save Site Expense'}
                </button>
              </div>

              <div className="bg-slate-900/50 border border-white/5 p-4 rounded-2xl flex flex-col">
                <span className="text-[9px] font-black tracking-widest text-slate-400 uppercase block mb-3">Recent Site Log</span>
                <div className="space-y-2 overflow-y-auto max-h-48 pr-1 no-scrollbar">
                  {recentExpenses.length > 0 ? recentExpenses.map(exp => (
                    <div key={exp.id} className="flex justify-between items-center bg-white/5 border border-white/5 p-2.5 rounded-xl">
                      <div className="flex-1">
                        <p className="text-[10px] font-black text-slate-200">
                          {exp.expense_type === 'Other Expenses' ? exp.custom_category?.toUpperCase() : exp.expense_type?.toUpperCase()}
                        </p>
                        <p className="text-[8px] text-slate-500 font-bold">
                          {new Date(exp.created_at).toLocaleDateString()} {exp.remarks && `• ${exp.remarks}`}
                        </p>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className="text-[11px] font-black text-emerald-400">₹{exp.amount}</span>
                        <button 
                          onClick={() => handleDeleteExpense(exp.id)} 
                          title="Delete Expense"
                          aria-label="Delete Expense"
                          className="text-red-400/60 hover:text-red-400 cursor-pointer"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  )) : (
                    <p className="text-[10px] text-slate-500 font-semibold text-center py-8">No expenses logged for this site yet.</p>
                  )}
                </div>
              </div>
            </form>
          </div>

          {/* Section 5: Project Archiving Control Pipeline */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-4">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <CheckCircle size={14} className="text-blue-400" /> Active project completion & archiving
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">Completing status auto-generates a PDF digest summary report, emails copy, and purges logs.</p>
            </div>

            <div className="space-y-3">
              {clients.filter(c => c.project_status !== 'completed').map(c => {
                const isArchiving = archivingId === c.unitNumber;
                return (
                  <div key={c.id} className="bg-slate-900/50 border border-white/5 p-4 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                      <span className="text-[10px] font-black text-slate-300 block">{c.client_name} ({c.unitNumber})</span>
                      <span className="text-[9px] text-slate-400 font-semibold block mt-0.5">Location: {c.site_location} | Status: <span className="text-blue-400 font-bold uppercase">{c.project_status}</span></span>
                      {c.email && <span className="text-[8px] text-slate-500 font-bold block mt-0.5">Registered Email: {c.email}</span>}
                    </div>

                    <div>
                      <button 
                        type="button"
                        onClick={() => handleArchiveProject(c.unitNumber)}
                        disabled={archivingId !== null}
                        className="px-4 py-2 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white rounded-xl font-black text-[10px] transition uppercase tracking-wider shadow border border-white/10 disabled:opacity-50 cursor-pointer flex items-center gap-1"
                      >
                        {isArchiving ? (
                          <>
                            <Loader2 className="animate-spin w-3 h-3" />
                            <span>Archiving...</span>
                          </>
                        ) : (
                          <>
                            <Play size={10} />
                            <span>Complete & Archive</span>
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                );
              })}

              {clients.filter(c => c.project_status !== 'completed').length === 0 && (
                <p className="text-xs text-slate-500 font-semibold text-center py-6">No active projects to archive.</p>
              )}
            </div>

            {archivingId && (
              <div className="p-3.5 bg-blue-500/10 border border-blue-500/20 text-xs text-blue-400 font-bold rounded-2xl flex items-center justify-center gap-2">
                <Loader2 className="animate-spin w-4 h-4" />
                <span>{archiveStatus}</span>
              </div>
            )}
          </div>

          {/* Section 5: Contracts & Advanced Workflows Overview */}
          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-5">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <TrendingUp size={14} className="text-purple-400" /> Contracts & Advanced Workflows
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">
                Live overview of contract signing, change orders, and payment receipts across all projects.
              </p>
            </div>

            {/* Summary stats */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
                <p className="text-[9px] font-black uppercase tracking-wider text-slate-400">Active Projects</p>
                <p className="text-xl font-black text-blue-400 mt-1">{clients.filter(c => c.project_status !== 'completed').length}</p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
                <p className="text-[9px] font-black uppercase tracking-wider text-slate-400">Total Revenue</p>
                <p className="text-xl font-black text-green-400 mt-1">
                  ₹{(quotations.reduce((sum, q) => sum + (q.totalAmount || 0), 0) / 100000).toFixed(1)}L
                </p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
                <p className="text-[9px] font-black uppercase tracking-wider text-slate-400">Total Collected</p>
                <p className="text-xl font-black text-emerald-400 mt-1">
                  ₹{(quotations.reduce((sum, q) => sum + (q.paidAmount || 0), 0) / 100000).toFixed(1)}L
                </p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-xl p-3 text-center">
                <p className="text-[9px] font-black uppercase tracking-wider text-slate-400">Outstanding</p>
                <p className="text-xl font-black text-red-400 mt-1">
                  ₹{(quotations.reduce((sum, q) => sum + ((q.totalAmount || 0) - (q.paidAmount || 0)), 0) / 100000).toFixed(1)}L
                </p>
              </div>
            </div>

            {/* Per-project workflow status list */}
            <div className="space-y-2.5 max-h-[300px] overflow-y-auto pr-1">
              <span className="text-[9px] font-black uppercase tracking-widest text-slate-400 block mb-1">
                Project Workflow Status
              </span>
              {clients.filter(c => c.project_status !== 'completed').map((c) => {
                const q = quotations.find(q => q.unitNumber === c.unitNumber);
                const balance = (q?.totalAmount || c.total_contract_amount || 0) - (q?.paidAmount || c.advance_received || 0);
                return (
                  <div
                    key={c.unitNumber}
                    className="flex items-center justify-between p-3 bg-white/5 border border-white/10 rounded-xl"
                  >
                    <div>
                      <p className="text-xs font-bold text-white">{c.client_name}</p>
                      <p className="text-[9px] text-slate-400 font-bold">
                        {c.unitNumber} • {c.site_location}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-wider ${
                        balance <= 0
                          ? 'bg-green-500/20 text-green-400 border border-green-500/30'
                          : 'bg-orange-500/20 text-orange-400 border border-orange-500/30'
                      }`}>
                        {balance <= 0 ? '✅ PAID' : `₹${Math.round(balance).toLocaleString('en-IN')} DUE`}
                      </span>
                      <span className={`px-2 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-blue-500/20 text-blue-400 border border-blue-500/30`}>
                        {c.project_status || 'Planning'}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>

            <p className="text-[9px] text-slate-500 font-semibold text-center pt-2">
              💡 Open the Flutter app → Client Hub → Overview tab for per-project contract signing, change orders, GPS logs, and receipt generation.
            </p>
          </div>

          {/* Section 6: API Settings / Configuration (Developer Friendly) */}

          <div className="backdrop-blur-md bg-white/5 border border-white/10 p-6 rounded-3xl shadow-xl space-y-4">
            <div>
              <h3 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
                <Settings size={14} className="text-blue-400" /> Admin API Integrations Settings
              </h3>
              <p className="text-[9px] text-slate-400 font-semibold mt-1">Configure Resend API parameters for transactional email reports.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1">
                <label htmlFor="resendApiKeyInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Resend API Key</label>
                <input 
                  id="resendApiKeyInput"
                  type="password"
                  placeholder="e.g. re_xxxxxxxxx"
                  value={resendApiKey}
                  onChange={e => setResendApiKey(e.target.value)}
                  className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-blue-500 transition font-semibold"
                />
              </div>

              <div className="space-y-1">
                <label htmlFor="adminEmailInput" className="text-[9px] font-black tracking-widest text-slate-400 uppercase">Admin Notification Email</label>
                <input 
                  id="adminEmailInput"
                  type="email"
                  placeholder="admin@pcm.com"
                  value={adminEmail}
                  onChange={e => setAdminEmail(e.target.value)}
                  className="w-full bg-slate-900 border border-white/10 rounded-xl px-4 py-3 text-xs text-white focus:outline-none focus:border-blue-500 transition font-semibold"
                />
              </div>
            </div>

            <button 
              type="button"
              onClick={handleSaveSettings}
              className="w-full py-3 bg-white/5 hover:bg-white/10 text-slate-200 rounded-xl font-black text-[10px] transition uppercase tracking-wider border border-white/10 cursor-pointer shadow"
            >
              Save Admin Configuration API Keys
            </button>
          </div>

        </div>
      )}

      {/* Footer info */}
      <div className="absolute bottom-4 left-0 right-0 text-center pointer-events-none">
        <p className="text-[9px] text-slate-500 font-black tracking-widest uppercase">
          PCM SYSTEM ADMIN CONSOLE v3.0
        </p>
      </div>

    </div>
  );
};

export default AdminDashboard;
