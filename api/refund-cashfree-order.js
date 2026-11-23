/**
 * ==============================================================================
 * PCM WAYANAD - Serverless API Route: /api/refund-cashfree-order
 * Connects directly to Cashfree PG REST API (POST /pg/orders/{order_id}/refunds)
 * Handles Discount Refunds & Payment Reversals
 * Inserts negative ledger entry in client_payments & adjusts client totals
 * ==============================================================================
 */

export default async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    let body = req.body;
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch (e) { body = {}; }
    }

    const {
      orderId,
      refundAmount = 1000,
      refundNote = 'Discount negotiated after advance',
      clientId = '',
      siteId = ''
    } = body || {};

    const amount = Number(refundAmount);
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid refund amount is required' });
    }

    const targetOrderId = orderId || `PCM_ORD_${siteId || clientId || 'MANUAL'}`;
    const refundId = `PCM_REF_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`.toUpperCase();

    // 1. Fetch Cashfree Credentials
    const appId = process.env.CASHFREE_APP_ID || 'YOUR_CASHFREE_APP_ID';
    const secretKey = process.env.CASHFREE_SECRET_KEY || 'YOUR_CASHFREE_SECRET_KEY';
    const envMode = process.env.CASHFREE_ENV || (secretKey.includes('_test_') ? 'SANDBOX' : 'PRODUCTION');
    const cfBaseUrl = envMode === 'SANDBOX' || secretKey.includes('_test_')
      ? 'https://sandbox.cashfree.com/pg'
      : 'https://api.cashfree.com/pg';

    let cashfreeSuccess = false;
    let cashfreeData = null;

    // 2. If valid orderId provided, call Cashfree PG Refunds API
    if (orderId && !orderId.startsWith('MOCK_') && !orderId.startsWith('LOCAL_')) {
      try {
        const response = await fetch(`${cfBaseUrl}/orders/${encodeURIComponent(orderId)}/refunds`, {
          method: 'POST',
          headers: {
            'x-client-id': appId,
            'x-client-secret': secretKey,
            'x-api-version': '2023-08-01',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            refund_amount: amount,
            refund_id: refundId,
            refund_note: refundNote || 'Admin discount reversal',
            refund_speed: 'STANDARD'
          })
        });

        cashfreeData = await response.json();
        if (response.ok) {
          cashfreeSuccess = true;
        } else {
          console.warn('Cashfree PG Refund API response non-200:', cashfreeData);
        }
      } catch (cfErr) {
        console.warn('Cashfree PG Refund API network call error:', cfErr.message);
      }
    } else {
      // Offline / Manual / Direct order refund simulation
      cashfreeSuccess = true;
      cashfreeData = {
        cf_refund_id: `MOCK_CF_REF_${Date.now()}`,
        refund_id: refundId,
        order_id: targetOrderId,
        refund_amount: amount,
        refund_status: 'SUCCESS',
        refund_note: refundNote
      };
    }

    // 3. Database Ledger insertion & Client balance adjustment (Supabase if available)
    const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || 'https://whqfnvbyxwyvtdjnlzss.supabase.co';
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || process.env.VITE_SUPABASE_ANON_KEY;

    let dbUpdated = false;
    const effectiveClientId = clientId || siteId;

    if (supabaseUrl && supabaseServiceKey && effectiveClientId) {
      try {
        const { createClient } = await import('@supabase/supabase-js');
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // A. Insert negative ledger entry into client_payments
        const refundRecord = {
          client_id: effectiveClientId,
          amount: -amount,
          amount_paid: -amount,
          payment_method: 'DISCOUNT_REFUND',
          payment_status: 'SUCCESS',
          remarks: `Discount ₹${amount.toLocaleString('en-IN')} credited back to client account: ${refundNote}`,
          notes: `Discount ₹${amount.toLocaleString('en-IN')} credited back to client account`,
          created_at: new Date().toISOString()
        };

        const { error: insErr } = await supabase.from('client_payments').insert([refundRecord]);
        if (insErr) console.warn('Supabase client_payments refund insert error:', insErr.message);

        // B. Update Client Total Paid & Balance Due
        const { data: curClient } = await supabase
          .from('clients')
          .select('total_paid, total_contract, balance_due')
          .eq('id', effectiveClientId)
          .maybeSingle();

        if (curClient) {
          const currentPaid = Number(curClient.total_paid || 0);
          const newPaid = Math.max(0, currentPaid - amount);
          const totalContract = Number(curClient.total_contract || 0);
          const newDue = Math.max(0, totalContract - newPaid);

          await supabase.from('clients').update({
            total_paid: newPaid,
            balance_due: newDue,
            updated_at: new Date().toISOString()
          }).eq('id', effectiveClientId);
        }

        dbUpdated = true;
      } catch (dbErr) {
        console.warn('Supabase client update in refund route error:', dbErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      refund_id: refundId,
      order_id: targetOrderId,
      refund_amount: amount,
      refund_note: refundNote,
      cashfree_success: cashfreeSuccess,
      cashfree_response: cashfreeData,
      db_updated: dbUpdated,
      ledger_entry: {
        amount: -amount,
        payment_method: 'DISCOUNT_REFUND',
        status: 'SUCCESS',
        notes: `Discount ₹${amount.toLocaleString('en-IN')} credited back to client account`
      }
    });

  } catch (error) {
    console.error('Server error processing Cashfree discount refund:', error);
    return res.status(500).json({
      error: error.message || 'Internal server error processing refund request'
    });
  }
}
