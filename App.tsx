import React, { useState, useEffect } from 'react';
import ClientPortal from './components/ClientPortal';
import ClientLogin from './components/ClientLogin';
import ContractSigningPage from './components/ContractSigningPage';

const App: React.FC = () => {
  const [clientId, setClientId] = useState<string | null>(() => {
    const searchParams = new URLSearchParams(globalThis.location.search);
    const pathname = globalThis.location.pathname;
    let id = searchParams.get('clientId') || searchParams.get('unitNumber');
    if (!id && pathname.startsWith('/project/')) {
      id = pathname.substring('/project/'.length);
    }
    return id;
  });

  // Detect /contract/:token route for client contract signing
  const contractToken = (() => {
    const pathname = globalThis.location.pathname;
    if (pathname.startsWith('/contract/')) {
      const token = pathname.substring('/contract/'.length).trim();
      return token.length > 0 ? token : null;
    }
    return null;
  })();

  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [showInstallBanner, setShowInstallBanner] = useState(false);

  useEffect(() => {
    const handlePopState = () => {
      const pathname = globalThis.location.pathname;
      let id = searchParams.get('clientId') || searchParams.get('unitNumber');
      if (!id && pathname.startsWith('/project/')) {
        id = pathname.substring('/project/'.length);
      }
      setClientId(id);
    };
    const searchParams = new URLSearchParams(globalThis.location.search);
    globalThis.addEventListener('popstate', handlePopState);
    return () => {
      globalThis.removeEventListener('popstate', handlePopState);
    };
  }, []);

  useEffect(() => {
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e);
      setShowInstallBanner(true);
    };

    globalThis.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    if (globalThis.matchMedia('(display-mode: standalone)').matches || (globalThis.navigator as any).standalone) {
      setShowInstallBanner(false);
    }

    return () => {
      globalThis.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  const handleInstallClick = async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    console.log(`User response to install prompt: ${outcome}`);
    setDeferredPrompt(null);
    setShowInstallBanner(false);
  };

  const renderInstallBanner = () => {
    if (!showInstallBanner) return null;
    return (
      <div className="fixed bottom-6 left-4 right-4 max-w-sm mx-auto bg-gradient-to-r from-blue-900 to-indigo-900 text-white rounded-2xl p-4 shadow-2xl border border-blue-500/30 z-[9999] flex items-center justify-between gap-3 animate-bounce">
        <div className="flex-1">
          <h4 className="text-xs font-black tracking-wide uppercase text-blue-200">
            Install App
          </h4>
          <p className="text-[11px] text-slate-200 font-medium leading-normal mt-0.5">
            Install Premium Ceiling App to your Home Screen for mobile app experience!
          </p>
        </div>
        <div className="flex items-center gap-1 shrink-0">
          <button
            onClick={() => setShowInstallBanner(false)}
            className="px-2.5 py-1.5 rounded-lg text-slate-400 hover:text-white text-xs font-bold transition"
          >
            Dismiss
          </button>
          <button
            onClick={handleInstallClick}
            className="bg-white text-blue-900 px-4 py-2 rounded-xl text-xs font-black hover:bg-blue-50 active:scale-95 transition shadow-md uppercase tracking-wider"
          >
            Install
          </button>
        </div>
      </div>
    );
  };

  const handleLoginSuccess = (newClientId: string) => {
    setClientId(newClientId);
    const newUrl = `${globalThis.location.origin}${globalThis.location.pathname}?clientId=${newClientId}`;
    globalThis.history.pushState({ path: newUrl }, '', newUrl);
  };

  let mainContent;
  // Priority 1: Contract signing link (client receives from admin)
  if (contractToken) {
    mainContent = <ContractSigningPage accessToken={contractToken} />;
  } else if (clientId) {
    mainContent = <ClientPortal clientId={clientId} />;
  } else {
    mainContent = <ClientLogin onLoginSuccess={handleLoginSuccess} />;
  }

  return (
    <div className="min-h-screen bg-slate-950 font-sans text-slate-900 flex flex-col max-w-4xl mx-auto shadow-2xl overflow-hidden relative">
      <main className="flex-1 overflow-y-auto no-scrollbar relative">
        {mainContent}
      </main>
      {renderInstallBanner()}
    </div>
  );
};

export default App;