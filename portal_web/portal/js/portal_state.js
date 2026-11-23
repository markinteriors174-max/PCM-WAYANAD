/**
 * PCM WAYANAD PORTAL - STATE & FORMATTERS (< 55 lines)
 */

window.PortalState = {
  SUPABASE_URL: "https://acszqttuqdvpgmwbtndw.supabase.co",
  SUPABASE_ANON: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjc3pxdHR1cWR2cGdtd2J0bmR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzODQ3NzksImV4cCI6MjA5OTk2MDc3OX0.8IohWgAWzeUromPsSE4YBu2ZTqn6wJZL7WYx637wBWE",
  
  supabaseClient: null,
  portalData: null,
  currentClientFound: null,
  renderedMsgSet: new Set(),
  
  currentSiteId: (function() {
    const search = (typeof window !== 'undefined' && window.location) ? window.location.search : '';
    const params = new URLSearchParams(search);
    return (params.get('site') || params.get('pin') || 'pcm-ms-003').trim().toLowerCase();
  })()
};

window.formatInr = function(val) {
  if (val === undefined || val === null || Number.isNaN(Number(val))) return '₹0.00';
  return '₹' + Number(val).toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
};

window.formatChatTime = function(timeIso) {
  if (!timeIso) return '';
  const d = new Date(timeIso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
};
