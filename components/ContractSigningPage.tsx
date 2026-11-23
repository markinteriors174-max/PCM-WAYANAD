/* eslint-disable react/forbid-dom-props, react/forbid-component-props, sonarjs/no-inline-styles, react-native/no-inline-styles, jsx-a11y/no-static-element-interactions, jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-nested-interactive, sonarjs/cognitive-complexity, sonarjs/no-nested-template-literals, sonarjs/no-inverted-boolean-check, no-empty, no-nested-ternary */
import React, { useEffect, useRef, useState, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { PDFDocument, rgb } from 'pdf-lib';

interface ContractData {
  id: string;
  unit_number: string;
  client_name: string;
  client_phone: string;
  contract_status: string;
  access_token: string;
  unsigned_pdf_url: string | null;
  signed_pdf_url: string | null;
  signed_at: string | null;
}

interface Props {
  accessToken: string;
}

type PageState = 'loading' | 'ready' | 'already_signed' | 'submitting' | 'success' | 'error';

const SUPABASE_URL = 'https://pNZYGMVENSMRZQPOBWTK.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k2';

const ContractSigningPage: React.FC<Props> = ({ accessToken }) => {
  const [contract, setContract] = useState<ContractData | null>(null);
  const [pageState, setPageState] = useState<PageState>('loading');
  const [error, setError] = useState('');
  const [statusMsg, setStatusMsg] = useState('');

  // Canvas signature pad
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isDrawing = useRef(false);
  const lastPos = useRef<{ x: number; y: number } | null>(null);
  const [hasSig, setHasSig] = useState(false);

  // ── Fetch contract by access_token ─────────────────────────
  useEffect(() => {
    const fetchContract = async () => {
      const { data, error: err } = await supabase
        .from('contracts')
        .select('*')
        .eq('access_token', accessToken)
        .single();

      if (err || !data) {
        setError('Contract not found or link is invalid. Please contact PCM WAYANAD.');
        setPageState('error');
        return;
      }

      const c = data as ContractData;
      setContract(c);

      if (c.contract_status === 'signed_by_client') {
        setPageState('already_signed');
      } else {
        setPageState('ready');
      }
    };

    fetchContract();
  }, [accessToken]);

  // ── Canvas signature pad ────────────────────────────────────
  const getPos = (e: React.MouseEvent | React.TouchEvent, canvas: HTMLCanvasElement) => {
    const rect = canvas.getBoundingClientRect();
    if ('touches' in e) {
      const touch = e.touches[0];
      return { x: touch.clientX - rect.left, y: touch.clientY - rect.top };
    }
    return { x: (e as React.MouseEvent).clientX - rect.left, y: (e as React.MouseEvent).clientY - rect.top };
  };

  const startDraw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault();
    if (!canvasRef.current) return;
    isDrawing.current = true;
    lastPos.current = getPos(e, canvasRef.current);
  }, []);

  const draw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault();
    if (!isDrawing.current || !canvasRef.current || !lastPos.current) return;
    const ctx = canvasRef.current.getContext('2d')!;
    const pos = getPos(e, canvasRef.current);
    ctx.beginPath();
    ctx.moveTo(lastPos.current.x, lastPos.current.y);
    ctx.lineTo(pos.x, pos.y);
    ctx.strokeStyle = '#1a1a2e';
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.stroke();
    lastPos.current = pos;
    setHasSig(true);
  }, []);

  const endDraw = useCallback(() => {
    isDrawing.current = false;
    lastPos.current = null;
  }, []);

  const clearSignature = () => {
    if (!canvasRef.current) return;
    const ctx = canvasRef.current.getContext('2d')!;
    ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
    setHasSig(false);
  };

  // ── Upload bytes to Supabase Storage ────────────────────────
  const uploadToStorage = async (bucket: string, path: string, bytes: Uint8Array, contentType: string): Promise<string | null> => {
    const url = `${SUPABASE_URL}/storage/v1/object/${bucket}/${path}`;
    const res = await fetch(url, {
      method: 'PUT',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: bytes,
    });
    if (res.ok) {
      return `${SUPABASE_URL}/storage/v1/object/public/${bucket}/${path}`;
    }
    return null;
  };

  // ── Approve & embed signature ───────────────────────────────
  const handleApprove = async () => {
    if (!hasSig) {
      alert('Please draw your signature before approving.');
      return;
    }
    if (!contract?.unsigned_pdf_url) {
      alert('Contract PDF not found. Please contact PCM WAYANAD.');
      return;
    }

    setPageState('submitting');
    setStatusMsg('Preparing your signature...');

    try {
      // 1. Export signature as PNG data URL
      const canvas = canvasRef.current!;
      const sigDataUrl = canvas.toDataURL('image/png');
      const sigBase64 = sigDataUrl.split(',')[1];
      const sigBytes = Uint8Array.from(atob(sigBase64), c => c.charCodeAt(0));

      // 2. Fetch the unsigned PDF
      setStatusMsg('Fetching contract PDF...');
      const pdfRes = await fetch(contract.unsigned_pdf_url);
      if (!pdfRes.ok) throw new Error('Failed to fetch the contract PDF.');
      const pdfBytes = await pdfRes.arrayBuffer();

      // 3. Load PDF with pdf-lib
      setStatusMsg('Embedding your signature...');
      const pdfDoc = await PDFDocument.load(pdfBytes);
      const pages = pdfDoc.getPages();
      const lastPage = pages[pages.length - 1];
      const { width, height } = lastPage.getSize();

      // 4. Embed signature PNG onto last page (bottom-right area, matching buildFinalSignatures layout)
      const sigImg = await pdfDoc.embedPng(sigBytes);
      const sigDims = sigImg.scale(0.4); // scale to a reasonable size
      lastPage.drawImage(sigImg, {
        x: width - sigDims.width - 40,
        y: 50,
        width: sigDims.width,
        height: sigDims.height,
      });

      // 5. Add "Digitally Signed by Client" text below
      const helveticaFont = await pdfDoc.embedFont('Helvetica');
      lastPage.drawText(`Digitally Signed by: ${contract.client_name}`, {
        x: width - sigDims.width - 40,
        y: 38,
        size: 7,
        font: helveticaFont,
        color: rgb(0.3, 0.3, 0.3),
      });
      lastPage.drawText(`Date: ${new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}`, {
        x: width - sigDims.width - 40,
        y: 28,
        size: 7,
        font: helveticaFont,
        color: rgb(0.3, 0.3, 0.3),
      });

      // 6. Save the signed PDF
      setStatusMsg('Uploading signed contract...');
      const signedPdfBytes = await pdfDoc.save();
      const timestamp = Date.now();
      const storagePath = `signed/${contract.unit_number}_signed_${timestamp}.pdf`;
      const signedPdfUrl = await uploadToStorage('contracts', storagePath, signedPdfBytes, 'application/pdf');

      if (!signedPdfUrl) throw new Error('Failed to upload signed PDF to storage.');

      // 7. Update the contracts table
      setStatusMsg('Finalizing...');
      const { error: updateError } = await supabase
        .from('contracts')
        .update({
          signed_pdf_url: signedPdfUrl,
          client_signature_data: sigDataUrl,
          contract_status: 'signed_by_client',
          signed_at: new Date().toISOString(),
        })
        .eq('access_token', accessToken);

      if (updateError) throw new Error('Failed to update contract status.');

      setPageState('success');
    } catch (err) {
      console.error('[ContractSigningPage] Error:', err);
      setError(err instanceof Error ? err.message : 'An unexpected error occurred.');
      setPageState('error');
    }
  };

  // ── UI ──────────────────────────────────────────────────────

  if (pageState === 'loading') {
    return (
      <div style={styles.centeredPage}>
        <div style={styles.spinner} />
        <p style={styles.loadingText}>Loading your contract...</p>
      </div>
    );
  }

  if (pageState === 'error') {
    return (
      <div style={styles.centeredPage}>
        <div style={styles.errorIcon}>⚠️</div>
        <h2 style={styles.errorTitle}>Link Invalid</h2>
        <p style={styles.errorMsg}>{error}</p>
        <a href="https://pcmwayanad.com" style={styles.homeLink}>← Back to PCM WAYANAD</a>
      </div>
    );
  }

  if (pageState === 'already_signed') {
    return (
      <div style={styles.centeredPage}>
        <div style={{ fontSize: 64 }}>✅</div>
        <h2 style={{ ...styles.successTitle, marginTop: 16 }}>Already Signed</h2>
        <p style={styles.successMsg}>
          This contract was already digitally signed and returned to PCM WAYANAD.
          <br />Thank you, {contract?.client_name}!
        </p>
        {contract?.signed_at && (
          <p style={{ fontSize: 12, color: '#64748b', marginTop: 8 }}>
            Signed on: {new Date(contract.signed_at).toLocaleString('en-IN')}
          </p>
        )}
      </div>
    );
  }

  if (pageState === 'success') {
    return (
      <div style={styles.centeredPage}>
        <div style={{ fontSize: 72 }}>🎉</div>
        <h2 style={styles.successTitle}>Contract Signed!</h2>
        <p style={styles.successMsg}>
          Your signature has been embedded and the signed contract has been returned to PCM WAYANAD.
          <br /><br />
          <strong>Thank you, {contract?.client_name}!</strong>
          <br />
          The PCM WAYANAD team will be in touch shortly.
        </p>
      </div>
    );
  }

  if (pageState === 'submitting') {
    return (
      <div style={styles.centeredPage}>
        <div style={styles.spinner} />
        <p style={styles.loadingText}>{statusMsg}</p>
        <p style={{ fontSize: 11, color: '#94a3b8', marginTop: 8 }}>Please wait, do not close this page...</p>
      </div>
    );
  }

  // ── Main signing page ───────────────────────────────────────
  return (
    <div style={styles.page}>
      {/* Header */}
      <div style={styles.header}>
        <div style={styles.headerLogo}>PCM WAYANAD</div>
        <div style={styles.headerSub}>Contract Review & Digital Signature</div>
      </div>

      {/* Client info banner */}
      <div style={styles.infoBanner}>
        <span>📋 Project: <strong>{contract?.unit_number}</strong></span>
        <span>👤 {contract?.client_name}</span>
      </div>

      {/* Main content */}
      <div style={styles.mainGrid}>
        {/* Left: PDF Viewer */}
        <div style={styles.pdfPanel}>
          <h3 style={styles.panelTitle}>📄 Your Contract</h3>
          <p style={styles.panelSub}>Please read the full document below before signing.</p>
          {contract?.unsigned_pdf_url ? (
            <iframe
              src={contract.unsigned_pdf_url}
              style={styles.pdfFrame}
              title="Contract PDF"
            />
          ) : (
            <div style={styles.pdfPlaceholder}>PDF not available</div>
          )}
        </div>

        {/* Right: Signature pad */}
        <div style={styles.sigPanel}>
          <h3 style={styles.panelTitle}>✍️ Your Signature</h3>
          <p style={styles.panelSub}>Draw your signature in the box below using your finger or mouse.</p>

          <div style={styles.canvasWrapper}>
            <canvas
              ref={canvasRef}
              width={320}
              height={180}
              style={styles.canvas}
              onMouseDown={startDraw}
              onMouseMove={draw}
              onMouseUp={endDraw}
              onMouseLeave={endDraw}
              onTouchStart={startDraw}
              onTouchMove={draw}
              onTouchEnd={endDraw}
            />
            {!hasSig && (
              <div style={styles.canvasHint}>Sign here →</div>
            )}
          </div>

          <button
            onClick={clearSignature}
            style={styles.clearBtn}
          >
            🗑️ Clear Signature
          </button>

          {/* Terms */}
          <div style={styles.termsBox}>
            <p style={styles.termsText}>
              By clicking "Approve & Return", I <strong>{contract?.client_name}</strong> confirm that:
              <br />• I have read and understood the full contract.
              <br />• I agree to all terms and conditions stated therein.
              <br />• My digital signature above is legally binding.
            </p>
          </div>

          {/* Approve button */}
          <button
            onClick={handleApprove}
            style={{ ...styles.approveBtn, opacity: hasSig ? 1 : 0.5 }}
            disabled={!hasSig}
          >
            ✅ APPROVE & RETURN SIGNED CONTRACT
          </button>
        </div>
      </div>

      {/* Footer */}
      <div style={styles.footer}>
        <p>PCM WAYANAD — Premium Ceiling Master | Secure Digital Signing Portal</p>
      </div>
    </div>
  );
};

// ── Styles ──────────────────────────────────────────────────────
const styles: Record<string, React.CSSProperties> = {
  page: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
    color: '#f1f5f9',
    fontFamily: '"Inter", "Segoe UI", sans-serif',
    display: 'flex',
    flexDirection: 'column',
  },
  header: {
    background: 'linear-gradient(90deg, #78350f, #92400e)',
    padding: '20px 24px',
    textAlign: 'center',
    borderBottom: '2px solid #d97706',
  },
  headerLogo: {
    fontSize: 22,
    fontWeight: 900,
    color: '#fef3c7',
    letterSpacing: '3px',
  },
  headerSub: {
    fontSize: 12,
    color: '#fbbf24',
    marginTop: 4,
    letterSpacing: '1px',
  },
  infoBanner: {
    background: 'rgba(255,255,255,0.05)',
    borderBottom: '1px solid rgba(255,255,255,0.1)',
    padding: '12px 24px',
    display: 'flex',
    gap: 24,
    flexWrap: 'wrap',
    fontSize: 13,
    color: '#cbd5e1',
  },
  mainGrid: {
    flex: 1,
    display: 'flex',
    gap: 0,
    flexWrap: 'wrap',
    padding: '20px',
    maxWidth: 1200,
    margin: '0 auto',
    width: '100%',
    boxSizing: 'border-box',
  },
  pdfPanel: {
    flex: '1 1 380px',
    background: 'rgba(255,255,255,0.04)',
    borderRadius: 12,
    padding: 20,
    border: '1px solid rgba(255,255,255,0.08)',
    marginRight: 16,
    marginBottom: 16,
  },
  sigPanel: {
    flex: '1 1 320px',
    background: 'rgba(255,255,255,0.04)',
    borderRadius: 12,
    padding: 20,
    border: '1px solid rgba(255,255,255,0.08)',
    marginBottom: 16,
    display: 'flex',
    flexDirection: 'column',
    gap: 12,
  },
  panelTitle: {
    fontSize: 16,
    fontWeight: 800,
    color: '#fbbf24',
    marginBottom: 4,
  },
  panelSub: {
    fontSize: 11,
    color: '#94a3b8',
    marginBottom: 12,
  },
  pdfFrame: {
    width: '100%',
    height: 540,
    borderRadius: 8,
    border: '1px solid rgba(255,255,255,0.1)',
    background: 'white',
  },
  pdfPlaceholder: {
    height: 400,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'rgba(255,255,255,0.05)',
    borderRadius: 8,
    color: '#64748b',
    fontSize: 14,
  },
  canvasWrapper: {
    position: 'relative',
    background: 'white',
    borderRadius: 8,
    overflow: 'hidden',
    border: '2px dashed #d97706',
  },
  canvas: {
    display: 'block',
    width: '100%',
    touchAction: 'none',
    cursor: 'crosshair',
  },
  canvasHint: {
    position: 'absolute',
    top: '50%',
    left: '50%',
    transform: 'translate(-50%, -50%)',
    color: '#d1d5db',
    fontSize: 14,
    fontStyle: 'italic',
    pointerEvents: 'none',
    userSelect: 'none',
  },
  clearBtn: {
    padding: '8px 16px',
    background: 'rgba(255,255,255,0.08)',
    border: '1px solid rgba(255,255,255,0.15)',
    borderRadius: 6,
    color: '#94a3b8',
    fontSize: 12,
    cursor: 'pointer',
    alignSelf: 'flex-start',
    transition: 'background 0.2s',
  },
  termsBox: {
    background: 'rgba(251,191,36,0.08)',
    border: '1px solid rgba(251,191,36,0.2)',
    borderRadius: 8,
    padding: 12,
  },
  termsText: {
    fontSize: 11,
    color: '#cbd5e1',
    lineHeight: 1.6,
    margin: 0,
  },
  approveBtn: {
    padding: '16px 20px',
    background: 'linear-gradient(135deg, #059669, #047857)',
    border: 'none',
    borderRadius: 10,
    color: 'white',
    fontSize: 13,
    fontWeight: 900,
    letterSpacing: '0.5px',
    cursor: 'pointer',
    transition: 'transform 0.15s, box-shadow 0.15s',
    boxShadow: '0 4px 20px rgba(5,150,105,0.4)',
    marginTop: 4,
  },
  footer: {
    textAlign: 'center',
    padding: '16px',
    fontSize: 11,
    color: '#475569',
    borderTop: '1px solid rgba(255,255,255,0.05)',
  },
  centeredPage: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #0f172a, #1e293b)',
    color: '#f1f5f9',
    padding: 32,
    fontFamily: '"Inter", sans-serif',
    textAlign: 'center',
    gap: 8,
  },
  spinner: {
    width: 40,
    height: 40,
    border: '3px solid rgba(251,191,36,0.3)',
    borderTop: '3px solid #fbbf24',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
  },
  loadingText: { fontSize: 14, color: '#94a3b8', marginTop: 12 },
  errorIcon: { fontSize: 48 },
  errorTitle: { fontSize: 22, fontWeight: 800, color: '#f87171' },
  errorMsg: { fontSize: 13, color: '#94a3b8', maxWidth: 400, lineHeight: 1.6 },
  homeLink: { fontSize: 12, color: '#fbbf24', marginTop: 16 },
  successTitle: { fontSize: 24, fontWeight: 900, color: '#34d399' },
  successMsg: { fontSize: 13, color: '#94a3b8', maxWidth: 440, lineHeight: 1.7 },
};

export default ContractSigningPage;
