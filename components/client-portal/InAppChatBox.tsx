import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '../../supabaseClient';
import { MessageSquare, Send, Image, Mic, Loader2 } from 'lucide-react';

const watermarkImage = (file: File, projectId: string): Promise<Blob> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new globalThis.Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          resolve(file); // fallback to original file if canvas not supported
          return;
        }

        // Keep original dimensions
        canvas.width = img.width;
        canvas.height = img.height;

        // Draw original image
        ctx.drawImage(img, 0, 0);

        // Watermark style configuration
        const fontSize = Math.max(16, Math.floor(img.width * 0.03)); // dynamic font size
        ctx.font = `bold ${fontSize}px sans-serif`;
        
        // Contextual information
        const timestamp = new Date().toLocaleString();
        const brandText = "PCM WAYANAD - CEILING MASTER";
        const infoText = `PROJECT: ${projectId} | ${timestamp}`;

        // Semi-transparent background banner for readability
        const padding = fontSize * 0.6;
        const bannerHeight = fontSize * 2.2 + padding * 2;
        ctx.fillStyle = 'rgba(15, 23, 42, 0.7)'; // slate-900 with transparency
        ctx.fillRect(0, canvas.height - bannerHeight, canvas.width, bannerHeight);

        // Text shadows/styling
        ctx.fillStyle = '#ffffff';
        ctx.textAlign = 'left';
        
        // Draw Brand
        ctx.fillText(brandText, padding, canvas.height - bannerHeight + fontSize + padding);
        
        // Draw Info (Project ID and Time)
        ctx.fillStyle = '#38bdf8'; // sky-400
        ctx.font = `${fontSize * 0.8}px sans-serif`;
        ctx.fillText(infoText, padding, canvas.height - padding);

        // Convert canvas back to blob
        canvas.toBlob((blob) => {
          if (blob) {
            resolve(blob);
          } else {
            resolve(file);
          }
        }, file.type || 'image/jpeg', 0.85);
      };
      img.onerror = () => reject(new Error("Image load error"));
      img.src = e.target?.result as string;
    };
    reader.onerror = () => reject(new Error("File read error"));
    reader.readAsDataURL(file);
  });
};

export const InAppChatBox: React.FC<{ clientId: string }> = ({ clientId }) => {
  const [messages, setMessages] = useState<any[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [sending, setSending] = useState(false);
  const endRef = useRef<HTMLDivElement | null>(null);
  
  const imageInputRef = useRef<HTMLInputElement | null>(null);
  const audioInputRef = useRef<HTMLInputElement | null>(null);

  const fetchMsgs = async () => {
    const { data } = await supabase
      .from('chat_messages')
      .select('*')
      .eq('site_id', clientId)
      .order('created_at', { ascending: true });
    if (data) setMessages(data);
  };

  useEffect(() => {
    fetchMsgs();
    const sub = supabase.channel(`chat:${clientId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'chat_messages', filter: `site_id=eq.${clientId}` }, fetchMsgs)
      .subscribe();
    return () => { supabase.removeChannel(sub); };
  }, [clientId]);

  useEffect(() => { endRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const uploadFile = async (file: File | Blob, fileType: 'image' | 'audio', originalName: string) => {
    const fileExt = originalName.split('.').pop() || (fileType === 'image' ? 'jpg' : 'mp3');
    const fileName = `${clientId}/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
    
    const { data, error } = await supabase.storage
      .from('site-media')
      .upload(fileName, file, {
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      console.error("Storage upload error:", error);
      throw error;
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('site-media')
      .getPublicUrl(fileName);

    return publicUrl;
  };

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || sending) return;
    setSending(true);
    const { error } = await supabase.from('chat_messages').insert({ 
      site_id: clientId, 
      sender: 'client', 
      message: newMessage.trim(), 
      message_type: 'text',
      created_at: new Date().toISOString() 
    });
    if (!error) { setNewMessage(''); fetchMsgs(); }
    setSending(false);
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>, fileType: 'image' | 'audio') => {
    const file = e.target.files?.[0];
    if (!file) return;

    setSending(true);
    try {
      let finalFile: File | Blob = file;
      if (fileType === 'image') {
        finalFile = await watermarkImage(file, clientId);
      }
      
      const publicUrl = await uploadFile(finalFile, fileType, file.name);
      
      const { error } = await supabase.from('chat_messages').insert({
        site_id: clientId,
        sender: 'client',
        message: fileType === 'image' ? '📷 Photo uploaded' : '🎵 Audio uploaded',
        message_content: publicUrl,
        message_type: fileType,
        created_at: new Date().toISOString()
      });

      if (error) throw error;
      fetchMsgs();
    } catch (err: any) {
      console.error(err);
      alert("Failed to upload file: " + err.message);
    } finally {
      setSending(false);
      if (e.target) e.target.value = '';
    }
  };

  return (
    <div className="backdrop-blur-md bg-white/5 border border-white/10 rounded-3xl p-5 shadow-inner flex flex-col gap-4">
      <div className="flex items-center gap-2 border-b border-white/10 pb-2">
        <MessageSquare size={16} className="text-blue-400" />
        <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest">Realtime Chat Log</h4>
      </div>
      
      <div className="h-60 overflow-y-auto bg-slate-955/40 border border-white/10 rounded-2xl p-3.5 space-y-3 flex flex-col no-scrollbar">
        {messages.length > 0 ? messages.map((m, i) => {
          const isAdmin = m.sender === 'admin';
          return (
            <div key={m.id || i} className={`max-w-[85%] rounded-2xl px-3 py-2 text-xs leading-normal ${isAdmin ? 'bg-slate-800 text-slate-100 self-start rounded-tl-none border border-white/5' : 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white self-end rounded-tr-none'}`}>
              <span className="block text-[7px] font-black uppercase text-slate-400 tracking-wider mb-0.5">{isAdmin ? 'Admin' : 'You'}</span>
              
              {m.message_type === 'image' ? (
                <div className="space-y-1 my-1">
                  <a href={m.message_content} target="_blank" rel="noopener noreferrer" className="block rounded-lg overflow-hidden border border-white/10 max-w-full">
                    <img src={m.message_content} alt="Chat attachment" className="max-h-48 object-cover w-full hover:scale-102 transition-transform" />
                  </a>
                  {m.message && <p className="font-semibold whitespace-pre-wrap mt-1">{m.message}</p>}
                </div>
              ) : m.message_type === 'audio' ? (
                <div className="space-y-1 my-1">
                  <audio src={m.message_content} controls className="max-w-full rounded border border-white/10 focus:outline-none invert hue-rotate-180" />
                  {m.message && <p className="font-semibold whitespace-pre-wrap mt-1">{m.message}</p>}
                </div>
              ) : (
                <p className="font-semibold whitespace-pre-wrap">{m.message}</p>
              )}

              <span className="block text-[6px] text-slate-300 text-right mt-1 font-bold">
                {new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
          );
        }) : (
          <div className="flex-1 flex flex-col items-center justify-center opacity-50 py-10 gap-2">
            <MessageSquare size={20} />
            <p className="text-[10px] font-semibold">No messages yet.</p>
          </div>
        )}
        <div ref={endRef} />
      </div>

      <form onSubmit={handleSend} className="flex gap-2 items-center">
        <input 
          type="file" 
          ref={imageInputRef} 
          accept="image/*" 
          className="hidden" 
          title="Upload Image File"
          onChange={(e) => handleFileChange(e, 'image')} 
        />
        <input 
          type="file" 
          ref={audioInputRef} 
          accept="audio/*" 
          className="hidden" 
          title="Upload Audio File"
          onChange={(e) => handleFileChange(e, 'audio')} 
        />

        <button 
          type="button" 
          disabled={sending} 
          onClick={() => imageInputRef.current?.click()}
          className="w-9 h-9 bg-white/5 hover:bg-white/10 text-slate-300 rounded-xl flex items-center justify-center transition disabled:opacity-50 cursor-pointer border border-white/10 shrink-0"
          title="Upload Image"
        >
          <Image size={14} />
        </button>

        <button 
          type="button" 
          disabled={sending} 
          onClick={() => audioInputRef.current?.click()}
          className="w-9 h-9 bg-white/5 hover:bg-white/10 text-slate-300 rounded-xl flex items-center justify-center transition disabled:opacity-50 cursor-pointer border border-white/10 shrink-0"
          title="Upload Audio"
        >
          <Mic size={14} />
        </button>

        <input 
          type="text" 
          placeholder="Ask site manager..." 
          value={newMessage} 
          onChange={(e) => setNewMessage(e.target.value)} 
          disabled={sending} 
          className="flex-1 bg-slate-955/80 border border-white/10 rounded-xl px-4 py-2 text-xs text-white focus:outline-none focus:border-blue-500 transition-colors disabled:opacity-50" 
        />
        
        <button 
          type="submit" 
          disabled={sending || !newMessage.trim()} 
          className="w-9 h-9 bg-gradient-to-r from-blue-500 to-indigo-600 text-white rounded-xl flex items-center justify-center hover:scale-105 active:scale-95 transition-transform disabled:opacity-50 cursor-pointer shrink-0 border border-white/10"
        >
          {sending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send size={12} />}
        </button>
      </form>
    </div>
  );
};
