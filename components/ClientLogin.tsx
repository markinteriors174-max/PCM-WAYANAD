import React, { useState, useEffect } from 'react';
import { ArrowRight, Lock, UserCheck, Phone, MapPin } from 'lucide-react';
import { supabase } from '../supabaseClient';

interface ClientLoginProps {
  onLoginSuccess: (clientId: string) => void;
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

const fetchQuotation = async (cleanId: string, cleanPhone: string): Promise<any> => {
  const resQuote = await fetchWithTimeout(
    `${SUPABASE_URL}/rest/v1/quotations?unitNumber=eq.${cleanId}`,
    {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
      }
    },
    8000
  );

  if (resQuote.status === 401 || resQuote.status === 403) {
    throw new Error('Supabase database sync failed: Invalid API key or unauthorized client initialization.');
  }

  if (resQuote.ok) {
    const quoteData = await resQuote.json();
    if (quoteData && quoteData.length > 0) {
      return quoteData.find(
        (row: any) => (row?.clientPhone || '').replace(/\D/g, '') === cleanPhone
      ) || null;
    }
  }
  return null;
};

const fetchClient = async (cleanId: string, cleanPhone: string): Promise<any> => {
  const resClient = await fetchWithTimeout(
    `${SUPABASE_URL}/rest/v1/clients?unitNumber=eq.${cleanId}`,
    {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
      }
    },
    8000
  );

  if (resClient.status === 401 || resClient.status === 403) {
    throw new Error('Supabase database sync failed: Invalid API key or unauthorized client initialization.');
  }

  if (resClient.ok) {
    const clientData = await resClient.json();
    if (clientData && clientData.length > 0) {
      return clientData.find(
        (row: any) => (row?.phone_number || '').replace(/\D/g, '') === cleanPhone
      ) || null;
    }
  }
  return null;
};

const handleClientLogin = async (
  matchedQuoteRecord: any,
  matchedClientRecord: any,
  cleanId: string
): Promise<string | null> => {
  const localToken = globalThis.localStorage?.getItem('pcm_client_session_id') || Math.random().toString(36).substring(2);
  globalThis.localStorage?.setItem('pcm_client_session_id', localToken);

  let dbDeviceToken: string | null = null;
  if (matchedQuoteRecord) {
    dbDeviceToken = matchedQuoteRecord.device_token || null;
  }
  if (!dbDeviceToken && matchedClientRecord) {
    dbDeviceToken = matchedClientRecord.device_token || null;
  }

  if (dbDeviceToken) {
    if (dbDeviceToken !== localToken) {
      return 'This Project ID is already registered and active on another device. Please contact support.';
    }
  } else {
    if (matchedQuoteRecord) {
      await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/quotations?unitNumber=eq.${cleanId}`, {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ device_token: localToken })
      }, 8000).catch(err => console.warn('Failed to bind device in quotations:', err));
    }
    if (matchedClientRecord) {
      await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/clients?unitNumber=eq.${cleanId}`, {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ device_token: localToken })
      }, 8000).catch(err => console.warn('Failed to bind device in clients:', err));
    }
  }
  return null;
};

const ClientLogin: React.FC<ClientLoginProps> = ({ onLoginSuccess }) => {
  const [projectId, setProjectId] = useState('');
  const [clientName, setClientName] = useState('');
  const [phone, setPhone] = useState('');
  const [location, setLocation] = useState('');
  const [isRegisterMode, setIsRegisterMode] = useState(false);
  const [registeredId, setRegisteredId] = useState<string | null>(null);

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // PREDICTIVE SEARCH STATES
  const [allClients, setAllClients] = useState<any[]>([]);
  const [suggestions, setSuggestions] = useState<any[]>([]);
  const [activeSearchField, setActiveSearchField] = useState<string | null>(null);

  // Auto-generate ID suffix for new registrations
  const [generatedSuffix, setGeneratedSuffix] = useState('');

  useEffect(() => {
    const url = new URL(globalThis.location.href);
    if (url.searchParams.get('onboard') === 'true') {
      setIsRegisterMode(true);
    }
    if (url.searchParams.has('clientId') || url.searchParams.has('unitNumber')) {
      url.searchParams.delete('clientId');
      url.searchParams.delete('unitNumber');
      globalThis.history.replaceState({}, '', url.toString());
    }

    // FETCH ALL CLIENTS FOR AUTO-COMPLETE ON MOUNT
    fetchAllClients();
  }, []);

  const fetchAllClients = async () => {
    try {
      const { data } = await supabase.from('clients').select('client_name, phone_number, site_location, unitNumber');
      if (data) setAllClients(data);
    } catch (e) {
      console.warn('Failed to fetch clients for autocomplete:', e);
    }
  };

  useEffect(() => {
    if (isRegisterMode && !generatedSuffix) {
      setGeneratedSuffix(Math.floor(1000 + Math.random() * 9000).toString());
    }
  }, [isRegisterMode, generatedSuffix]);

  // AUTO-COMPLETE UI LOGIC
  const handlePredictiveSearch = (val: string, field: string) => {
    if (field === 'name') setClientName(val);
    else if (field === 'phone') setPhone(val.replace(/\D/g, '').slice(0, 10));
    else if (field === 'location') setLocation(val);

    if (val.length < 2) {
      setSuggestions([]);
      setActiveSearchField(null);
      return;
    }

    const filtered = allClients.filter(c => {
      const target = field === 'name' ? (c.client_name || '') :
                    field === 'phone' ? (c.phone_number || '') :
                    (c.site_location || '');
      return target.toLowerCase().includes(val.toLowerCase());
    }).slice(0, 5); // Limit suggestions

    setSuggestions(filtered);
    setActiveSearchField(field);
  };

  const selectSuggestion = (client: any) => {
    setClientName(client.client_name || '');
    setPhone(client.phone_number || '');
    setLocation(client.site_location || '');

    // LOCK EXISTING CLIENT ID
    if (client.unitNumber) {
      const suffix = client.unitNumber.replace('pcm-ms-', '');
      if (suffix.length === 4) {
        setGeneratedSuffix(suffix);
      }
    }

    setSuggestions([]);
    setActiveSearchField(null);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    const rawInput = projectId.trim().toLowerCase();
    const cleanPhone = phone.replace(/\D/g, '');

    if (cleanPhone.length !== 10) {
      setErrorMsg('Please enter a valid 10-digit Phone Number.');
      return;
    }

    if (rawInput.length === 0) {
      setErrorMsg('Please enter your 4-digit Project ID.');
      return;
    }

    // Fixed prefix is pcm-ms-
    const cleanId = `pcm-ms-${rawInput}`;

    if (!navigator.onLine) {
      setErrorMsg('No internet connection. Please check your network connection.');
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    try {
      const quoteRecord = await fetchQuotation(cleanId, cleanPhone);
      const clientRecord = await fetchClient(cleanId, cleanPhone);

      const matchedClient = !!(quoteRecord || clientRecord);

      if (!matchedClient) {
        setErrorMsg('Invalid Phone Number or Project ID.');
        setLoading(false);
        return;
      }

      const error = await handleClientLogin(quoteRecord, clientRecord, cleanId);
      if (error) {
        setErrorMsg(error);
        setLoading(false);
        return;
      }

      const actualUnitNumber = quoteRecord?.unitNumber || clientRecord?.unitNumber || cleanId;
      onLoginSuccess(actualUnitNumber);

    } catch (err: any) {
      console.error(err);
      setErrorMsg(err.message || 'Network error. Check your connection and try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanName = clientName.trim();
    const cleanPhone = phone.replace(/\D/g, '');
    const cleanLocation = location.trim();

    if (cleanName.length === 0) {
      setErrorMsg('Please enter your Client Name.');
      return;
    }
    if (cleanPhone.length !== 10) {
      setErrorMsg('Please enter a valid 10-digit Phone Number.');
      return;
    }
    if (cleanLocation.length === 0) {
      setErrorMsg('Please enter your Site Location.');
      return;
    }

    if (!navigator.onLine) {
      setErrorMsg('No internet connection. Please check your network connection.');
      return;
    }

    setLoading(true);
    setErrorMsg(null);

    try {
      const generatedId = `pcm-ms-${generatedSuffix}`;

      const localToken = globalThis.localStorage?.getItem('pcm_client_session_id') || Math.random().toString(36).substring(2);
      globalThis.localStorage?.setItem('pcm_client_session_id', localToken);

      // UPSERT LOGIC: Uses Prefer: resolution=merge-duplicates (handled via POST usually in PostgREST but we use representing REPRESENTATION for representation)
      // Actually standard PostgREST UPSERT is POST with Prefer: resolution=merge-duplicates or PUT.
      // We'll use the existing POST pattern but ensure it hits Supabase correctly.

      await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/clients`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates'
        },
        body: JSON.stringify({
          client_name: cleanName,
          phone_number: cleanPhone,
          site_location: cleanLocation,
          unitNumber: generatedId,
          login_pin: generatedId,
          device_token: localToken,
          total_contract_amount: 0,
          advance_received: 0,
          balance_amount: 0,
          project_status: 'Planning'
        })
      }, 8000);

      await fetchWithTimeout(`${SUPABASE_URL}/rest/v1/quotations`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates'
        },
        body: JSON.stringify({
          unitNumber: generatedId,
          clientName: cleanName,
          clientPhone: cleanPhone,
          clientLocation: cleanLocation,
          totalAmount: 0,
          paidAmount: 0,
          balanceAmount: 0,
          projectStatus: 'Planning',
          device_token: localToken
        })
      }, 8000);

      setRegisteredId(generatedId);

    } catch (err: any) {
      console.error(err);
      setErrorMsg(err.message || 'Network error. Registration failed.');
    } finally {
      setLoading(false);
    }
  };

  const renderSuggestions = (field: string) => {
    if (activeSearchField !== field || suggestions.length === 0) return null;

    return (
      <div className="absolute z-[100] left-0 right-0 top-full mt-1 bg-[#1a1a1e] border border-white/10 rounded-xl shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
        {suggestions.map((client, idx) => (
          <button
            key={idx}
            type="button"
            onClick={() => selectSuggestion(client)}
            className="w-full text-left px-4 py-3 hover:bg-blue-600/20 transition-colors border-b border-white/5 last:border-0 group"
          >
            <p className="text-xs font-black text-white group-hover:text-blue-400">{client.client_name}</p>
            <p className="text-[10px] text-slate-500 font-bold mt-0.5">
              {client.phone_number} • {client.site_location}
            </p>
          </button>
        ))}
      </div>
    );
  };


  if (registeredId) {
    return (
      <div className="min-h-screen bg-[#0d0d11] flex items-center justify-center p-6 text-white relative overflow-hidden">
        {/* Glowing Cove Lighting Effects */}
        <div className="absolute top-0 left-1/4 w-[50%] h-[2px] bg-blue-500/30 blur-md shadow-[0_0_20px_rgba(59,130,246,0.5)]"></div>
        <div className="absolute bottom-0 right-1/4 w-[50%] h-[2px] bg-blue-500/30 blur-md shadow-[0_0_20px_rgba(59,130,246,0.5)]"></div>
        <div className="absolute top-20 left-10 w-48 h-48 bg-blue-600/10 rounded-full blur-3xl pointer-events-none"></div>
        <div className="absolute bottom-40 right-10 w-48 h-48 bg-purple-600/10 rounded-full blur-3xl pointer-events-none"></div>

        <div className="backdrop-blur-2xl bg-white/[0.03] border border-white/10 w-full max-w-md rounded-[2.5rem] p-10 shadow-2xl relative z-10 text-center space-y-8 animate-in fade-in zoom-in-95 duration-300">
          <div className="w-20 h-20 bg-blue-500/10 text-blue-400 rounded-full border border-blue-500/20 flex items-center justify-center mx-auto shadow-lg shadow-blue-500/5">
            <UserCheck className="w-10 h-10" />
          </div>
          <div>
            <h3 className="text-2xl font-black tracking-tight text-white uppercase">Registration Successful!</h3>
            <p className="text-sm text-slate-400 mt-2 font-semibold leading-relaxed">
              Your PCM Project ID is officially registered.
            </p>
          </div>

          <div className="bg-white/5 border border-white/10 py-5 px-6 rounded-2xl font-mono text-3xl font-black text-blue-400 tracking-widest shadow-inner">
            {registeredId}
          </div>

          <p className="text-xs text-slate-500 font-bold leading-normal">
            Save this ID for portal access.
          </p>

          <button
            onClick={() => onLoginSuccess(registeredId)}
            className="w-full flex items-center justify-center py-5 bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-500 hover:to-indigo-600 text-white rounded-2xl font-black text-xs transition uppercase tracking-widest shadow-xl shadow-blue-900/20 active:scale-[0.98] border border-white/10 cursor-pointer"
          >
            <span>Launch Client Portal</span>
            <ArrowRight className="ml-2 w-4 h-4" />
          </button>
        </div>
      </div>
    );
  }

  let submitText = 'Access Portal';
  if (loading) {
    submitText = 'Processing...';
  } else if (isRegisterMode) {
    submitText = 'Complete Registration';
  }

  return (
    <div className="min-h-screen bg-[#0d0d11] flex items-center justify-center p-4 md:p-8 text-white relative overflow-hidden">
      
      {/* Background Animated Glows & Cove Lighting */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-blue-500/40 to-transparent blur-[1px]"></div>
      <div className="absolute top-0 left-0 right-0 h-[40px] bg-gradient-to-b from-blue-500/[0.05] to-transparent pointer-events-none"></div>

      <div className="absolute top-20 left-10 w-96 h-96 bg-blue-600/10 rounded-full blur-[100px] pointer-events-none"></div>
      <div className="absolute bottom-40 right-10 w-96 h-96 bg-purple-600/10 rounded-full blur-[100px] pointer-events-none"></div>

      {/* Main Glass Container */}
      <div className="w-full max-w-5xl bg-white/[0.03] backdrop-blur-3xl border border-white/10 rounded-[3rem] shadow-[0_25px_50px_-12px_rgba(0,0,0,0.5)] overflow-hidden flex flex-col md:flex-row relative z-10 animate-in fade-in zoom-in-95 duration-700">
        
        {/* LEFT PANEL: Branding */}
        <div className="md:w-[45%] bg-gradient-to-br from-blue-950/40 to-slate-950/60 p-10 md:p-20 flex flex-col items-center justify-center text-center border-b md:border-b-0 md:border-r border-white/10 relative">
          <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/dark-matter.png')] opacity-10 pointer-events-none"></div>
          <div className="mb-12 hover:scale-110 transition-transform duration-500">
            <img
              src="/logo.png"
              alt="PCM Logo"
              className="h-[140px] md:h-[180px] w-auto object-contain drop-shadow-[0_0_30px_rgba(59,130,246,0.3)]"
            />
          </div>
          <h1 className="text-3xl md:text-5xl font-black text-white tracking-tighter leading-tight uppercase">
            PCM <br/>
            <span className="text-blue-500">Wayanad</span>
          </h1>
          <div className="h-1 w-20 bg-blue-500 my-8 rounded-full mx-auto shadow-[0_0_15px_rgba(59,130,246,0.8)]"></div>
          <p className="text-xs md:text-sm text-slate-400 font-bold tracking-widest uppercase leading-loose max-w-[280px]">
            Premium Ceiling Master <br/> Digital Project Hub
          </p>
        </div>

        {/* RIGHT PANEL: Form */}
        <div className="flex-1 p-10 md:p-16 flex flex-col justify-center bg-transparent">

          <div className="flex items-center justify-between mb-12">
            <div>
              <h2 className="text-2xl font-black text-white uppercase tracking-[0.2em]">
                {isRegisterMode ? 'New Registry' : 'Client Login'}
              </h2>
              <div className="h-1 w-12 bg-blue-500 mt-2 rounded-full shadow-[0_0_10px_rgba(59,130,246,0.5)]"></div>
            </div>

            <div className="flex bg-white/5 border border-white/10 p-1 rounded-2xl">
              <button
                type="button"
                onClick={() => { setIsRegisterMode(false); setErrorMsg(null); }}
                className={`px-6 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all duration-300 cursor-pointer ${
                  isRegisterMode
                    ? 'text-slate-500 hover:text-white'
                    : 'bg-blue-600 text-white shadow-[0_0_15px_rgba(59,130,246,0.4)]'
                }`}
              >
                Access
              </button>
              <button
                type="button"
                onClick={() => { setIsRegisterMode(true); setErrorMsg(null); }}
                className={`px-6 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all duration-300 cursor-pointer ${
                  isRegisterMode
                    ? 'bg-blue-600 text-white shadow-[0_0_15px_rgba(59,130,246,0.4)]'
                    : 'text-slate-500 hover:text-white'
                }`}
              >
                Register
              </button>
            </div>
          </div>

          <form onSubmit={isRegisterMode ? handleRegister : handleLogin} className="space-y-6">

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {isRegisterMode ? (
                <>
                  <div className="space-y-3">
                    <label htmlFor="fullNameInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Full Name
                    </label>
                    <div className="relative group">
                      <UserCheck className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 group-focus-within:text-blue-400 transition-colors" />
                      <input
                        id="fullNameInput"
                        type="text"
                        required
                        value={clientName}
                        onChange={(e) => handlePredictiveSearch(e.target.value, 'name')}
                        onBlur={() => setTimeout(() => setActiveSearchField(null), 200)}
                        placeholder="John Doe"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-5 text-white placeholder-slate-700 focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500/50 outline-none transition-all font-bold text-sm"
                      />
                      {renderSuggestions('name')}
                    </div>
                  </div>

                  <div className="space-y-3">
                    <label htmlFor="phoneNumberInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Phone Number
                    </label>
                    <div className="relative group">
                      <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 group-focus-within:text-blue-400 transition-colors" />
                      <input
                        id="phoneNumberInput"
                        type="tel"
                        required
                        maxLength={10}
                        value={phone}
                        onChange={(e) => handlePredictiveSearch(e.target.value, 'phone')}
                        onBlur={() => setTimeout(() => setActiveSearchField(null), 200)}
                        placeholder="10-digit number"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-5 text-white placeholder-slate-700 focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500/50 outline-none transition-all font-bold text-sm"
                      />
                      {renderSuggestions('phone')}
                    </div>
                  </div>

                  <div className="space-y-3">
                    <label htmlFor="locationInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Location / Place
                    </label>
                    <div className="relative group">
                      <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 group-focus-within:text-blue-400 transition-colors" />
                      <input
                        id="locationInput"
                        type="text"
                        required
                        value={location}
                        onChange={(e) => handlePredictiveSearch(e.target.value, 'location')}
                        onBlur={() => setTimeout(() => setActiveSearchField(null), 200)}
                        placeholder="City Name"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-5 text-white placeholder-slate-700 focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500/50 outline-none transition-all font-bold text-sm"
                      />
                      {renderSuggestions('location')}
                    </div>
                  </div>

                  <div className="space-y-3">
                    <label htmlFor="projectSiteIdInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Project Site ID
                    </label>
                    <div className="relative flex items-center bg-white/5 border border-white/10 rounded-2xl h-[60px] px-4 group">
                      <Lock className="w-4 h-4 text-blue-500/50 mr-3" />
                      <span className="font-mono text-sm font-black text-blue-500/40 select-none tracking-tight">
                        pcm-ms-
                      </span>
                      <input
                        id="projectSiteIdInput"
                        type="text"
                        readOnly
                        value={generatedSuffix}
                        title="Project Site ID Suffix"
                        placeholder="Site ID"
                        className="flex-1 bg-transparent text-blue-400 outline-none font-mono text-xl font-black tracking-[0.3em] ml-2 cursor-default"
                      />
                    </div>
                  </div>
                </>
              ) : (
                <>
                  <div className="space-y-3">
                    <label htmlFor="registeredPhoneInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Registered Phone
                    </label>
                    <div className="relative group">
                      <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 group-focus-within:text-blue-400 transition-colors" />
                      <input
                        id="registeredPhoneInput"
                        type="tel"
                        required
                        maxLength={10}
                        value={phone}
                        onChange={(e) => handlePredictiveSearch(e.target.value, 'phone')}
                        onBlur={() => setTimeout(() => setActiveSearchField(null), 200)}
                        placeholder="9383406185"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl pl-12 pr-4 py-5 text-white placeholder-slate-700 focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500/50 outline-none transition-all font-bold text-sm"
                      />
                      {renderSuggestions('phone')}
                    </div>
                  </div>

                  <div className="space-y-3">
                    <label htmlFor="projectIdInput" className="block text-[10px] font-black text-slate-500 uppercase tracking-[0.2em] ml-1">
                      Project ID
                    </label>
                    <div className="relative flex items-center bg-white/5 border border-white/10 rounded-2xl focus-within:ring-2 focus-within:ring-blue-500/30 focus-within:border-blue-500/50 transition-all h-[60px] group">
                      <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500 group-focus-within:text-blue-400 transition-colors pointer-events-none" />
                      <div className="flex items-center w-full pl-12 pr-4">
                        <span className="font-mono text-xs font-black text-blue-500/30 select-none tracking-tighter">
                          pcm-ms-
                        </span>
                        <input
                          id="projectIdInput"
                          type="text"
                          inputMode="numeric"
                          required
                          maxLength={4}
                          value={projectId}
                          onChange={(e) => setProjectId(e.target.value.replace(/\D/g, '').slice(0, 4))}
                          placeholder="0000"
                          className="flex-1 bg-transparent text-white placeholder-slate-800 outline-none font-mono text-xl font-black tracking-[0.4em] ml-3 text-center"
                        />
                      </div>
                    </div>
                  </div>
                </>
              )}
            </div>

            {errorMsg && (
              <div className="p-4 bg-red-500/10 text-[10px] text-red-400 font-black uppercase tracking-widest rounded-xl border border-red-500/20 text-center animate-shake">
                {errorMsg}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className={`w-full flex items-center justify-center py-5 rounded-2xl font-black text-xs transition-all uppercase tracking-[0.3em] cursor-pointer mt-6 ${
                loading
                  ? 'bg-slate-800 text-slate-600 cursor-not-allowed'
                  : 'bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-500 hover:to-indigo-600 text-white shadow-[0_15px_30px_-5px_rgba(59,130,246,0.3)] active:scale-[0.98] border border-white/10'
              }`}
            >
              <span>{submitText}</span>
              {!loading && <ArrowRight className="ml-2 w-4 h-4" />}
            </button>
          </form>

          <div className="mt-12 pt-8 border-t border-white/5 flex items-center justify-between">
            <p className="text-[9px] text-slate-600 font-black uppercase tracking-[0.2em]">
              Secure SSL Encrypted Access
            </p>
            <div className="flex gap-6">
              <span className="text-[9px] text-slate-700 font-black tracking-widest">v3.1</span>
              <span className="text-[9px] text-slate-700 font-black tracking-widest">PCM</span>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default ClientLogin;
