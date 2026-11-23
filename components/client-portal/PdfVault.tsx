import React, { useEffect, useState } from 'react';
import { supabase } from '../../supabaseClient';
import { FolderOpen, Download, FileText, Loader2 } from 'lucide-react';

interface PdfVaultProps {
  uniqueCode: string;
}

interface VaultFile {
  name: string;
  size: number;
  url: string;
}

export const PdfVault: React.FC<PdfVaultProps> = ({ uniqueCode }) => {
  const [files, setFiles] = useState<VaultFile[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchFiles = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.storage.from('project_documents').list(uniqueCode, {
        limit: 50,
        sortBy: { column: 'name', order: 'desc' }
      });
      if (error) throw error;

      if (data) {
        const mapped = data.map(f => {
          const { data: { publicUrl } } = supabase.storage.from('project_documents').getPublicUrl(`${uniqueCode}/${f.name}`);
          return {
            name: f.name,
            size: f.metadata?.size || 0,
            url: publicUrl
          };
        });
        setFiles(mapped);
      }
    } catch (err: any) {
      console.warn('PDF Vault list error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFiles();
  }, [uniqueCode]);

  const formatSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Number.parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const renderContent = () => {
    if (loading) {
      return (
        <div className="flex justify-center py-6">
          <Loader2 className="animate-spin text-blue-500" size={20} />
        </div>
      );
    }
    if (files.length > 0) {
      return (
        <div className="space-y-3">
          {files.map(file => (
            <div key={file.name} className="backdrop-blur-md bg-white/5 p-4 rounded-2xl border border-white/10 shadow-sm flex items-center justify-between gap-4 transition hover:border-blue-500/30 text-white">
              <div className="flex items-center gap-3 min-w-0">
                <div className="bg-red-500/10 p-2.5 rounded-xl text-red-400 border border-red-500/20 shrink-0">
                  <FileText size={20} />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-slate-200 text-xs truncate leading-tight">{file.name}</p>
                  <p className="text-[10px] text-slate-400 font-semibold mt-0.5">{formatSize(file.size)}</p>
                </div>
              </div>
              <a
                href={file.url}
                download={file.name}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white px-4 py-2 rounded-xl transition shadow-lg shadow-blue-600/20 hover:scale-105 active:scale-95 shrink-0 flex items-center justify-center gap-1.5 cursor-pointer border border-white/15 text-xs font-black uppercase tracking-wider"
                title="Download PDF"
              >
                <Download size={14} />
                <span>Download</span>
              </a>
            </div>
          ))}
        </div>
      );
    }
    return (
      <div className="text-center py-8 border border-dashed border-white/10 bg-white/5 rounded-2xl">
        <FileText className="text-slate-500 mx-auto mb-2" size={28} />
        <p className="text-xs text-slate-300 font-bold">No documents in vault yet.</p>
        <p className="text-[9px] text-slate-400 font-semibold mt-1">Uploaded PDF documents will appear here.</p>
      </div>
    );
  };

  return (
    <div className="space-y-4">
      <div className="border-b border-white/10 pb-2 flex justify-between items-center">
        <h4 className="text-xs font-black text-slate-300 uppercase tracking-widest flex items-center gap-1.5">
          <FolderOpen size={14} className="text-blue-400" /> Signed Project Documents
        </h4>
        <button onClick={fetchFiles} className="text-[10px] font-black text-blue-400 uppercase tracking-wider hover:text-blue-300 transition">
          Refresh
        </button>
      </div>

      {renderContent()}
    </div>
  );
};
export default PdfVault;
