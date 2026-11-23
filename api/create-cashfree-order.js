/**
 * ==============================================================================
 * PCM WAYANAD - Serverless API Route: /api/create-cashfree-order
 * Connects directly to Cashfree PG REST API (Production / Sandbox)
 * Computes 2.36% Gateway Surcharge (2% Gateway + 18% GST)
 * Returns payment_session_id for Seamless Frontend Checkout Dropin
 * ==============================================================================
 */

export default async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    let body = req.body || {};
    if (typeof body === 'string') {
      try { body = JSON.parse(body); } catch (e) { body = {}; }
    }

    const {
      clientId = '',
      clientPhone = '9383406185',
      clientName = 'PCM Client',
      clientEmail = 'pcmwayanad@gmail.com',
      baseAmount = 1000,
      previousUnpaidFee = 0,
      quotationId = 'PCM_ESTIMATE',
      siteId = '',
      returnUrl = ''
    } = body;

    const base = Number(baseAmount) || 0;
    const prevFee = Math.max(0, Number(previousUnpaidFee) || 0);

    // 1. Compute 2.36% Gateway Surcharge (2% PG fee + 18% GST = 2.36%)
    const GATEWAY_PERCENT = 0.0236;
    const currentGatewayFee = Math.round(base * GATEWAY_PERCENT);
    const totalSurcharge = prevFee + currentGatewayFee;
    const totalOrderAmount = Number((base + prevFee + currentGatewayFee).toFixed(2));
    const finalOrderAmount = totalOrderAmount > 0 ? totalOrderAmount : 1000;

    const cleanPhone = String(clientPhone || '').replace(/\D/g, '').slice(-10) || '9383406185';
    const rawCustomerId = String(clientId || `CUST_${cleanPhone}`).trim();
    const cleanCustomerId = rawCustomerId.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 40) || `CUST_${cleanPhone}`;
    const orderId = `PCM_ORD_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`.toUpperCase().replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 45);

    const cleanName = (clientName && String(clientName).trim().length > 0) ? String(clientName).trim() : 'PCM Client';
    const cleanEmail = (clientEmail && String(clientEmail).includes('@')) ? String(clientEmail).trim() : 'pcmwayanad@gmail.com';

    // Credentials & Environment Mode
    const appId = process.env.CASHFREE_APP_ID || 'YOUR_CASHFREE_APP_ID';
    const secretKey = process.env.CASHFREE_SECRET_KEY || 'YOUR_CASHFREE_SECRET_KEY';
    const isTestKey = secretKey.includes('_test_') || secretKey.startsWith('cfsk_ma_test_') || appId.startsWith('TEST');
    const envMode = process.env.CASHFREE_ENV || (isTestKey ? 'SANDBOX' : 'PRODUCTION');
    const cfBaseUrl = (envMode === 'SANDBOX' || isTestKey)
      ? 'https://sandbox.cashfree.com/pg'
      : 'https://api.cashfree.com/pg';

    const callbackUrl = returnUrl || `https://pcm-wayanad-portal.vercel.app/?order_id={order_id}&status={order_status}`;

    const payload = {
      order_id: orderId,
      order_amount: finalOrderAmount,
      order_currency: 'INR',
      customer_details: {
        customer_id: cleanCustomerId,
        customer_name: cleanName,
        customer_email: cleanEmail,
        customer_phone: cleanPhone
      },
      order_meta: {
        return_url: callbackUrl,
        payment_methods: 'cc,dc,upi,nb,app'
      },
      order_tags: {
        base_amount: String(base),
        quotation_id: String(quotationId || 'PCM_ESTIMATE').replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 40),
        site_id: String(siteId || clientId || '').replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 40),
        client_phone: cleanPhone
      }
    };

    const response = await fetch(`${cfBaseUrl}/orders`, {
      method: 'POST',
      headers: {
        'x-client-id': appId,
        'x-client-secret': secretKey,
        'x-api-version': '2023-08-01',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok || !data.payment_session_id) {
      console.error('Cashfree PG Orders API Error:', data);
      return res.status(response.status || 400).json({
        error: data.message || 'Cashfree Order Creation Failed - Missing payment_session_id',
        details: data
      });
    }

    return res.status(200).json({
      success: true,
      order_id: data.order_id,
      payment_session_id: data.payment_session_id,
      order_status: data.order_status,
      mode: envMode,
      breakdown: {
        baseAmount: base,
        totalPayable: finalOrderAmount,
        feePercent: '2.36%'
      }
    });

  } catch (error) {
    console.error('Server error creating Cashfree order:', error);
    return res.status(500).json({
      error: error.message || 'Internal server error processing payment request'
    });
  }
}
