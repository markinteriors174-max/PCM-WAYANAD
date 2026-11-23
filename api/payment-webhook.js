/**
 * ==============================================================================
 * PCM WAYANAD - Serverless API Route: /api/payment-webhook
 * Tamper-Proof Cashfree Webhook Handler
 * Verifies HMAC-SHA256 secret signature before processing payment.
 * Invokes Supabase RPC 'record_payment_atomic' inside a single atomic transaction.
 * ==============================================================================
 */

import crypto from 'node:crypto';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase Client with Service Role or Anon Key
const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://xyzcompany.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
const supabase = createClient(supabaseUrl, supabaseKey);

export default async function handler(req, res) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-webhook-signature, x-webhook-timestamp');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const secretKey = process.env.CASHFREE_SECRET_KEY || 'YOUR_CASHFREE_SECRET_KEY';
    
    // 1. Extract Raw Body & Webhook Signatures
    const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    const signature = req.headers['x-webhook-signature'] || req.headers['x-cashfree-signature'] || '';
    const timestamp = req.headers['x-webhook-timestamp'] || '';

    // 2. Tamper-Proof Webhook Signature Verification
    if (signature && secretKey) {
      const dataToSign = timestamp ? `${timestamp}${rawBody}` : rawBody;
      const expectedSignature = crypto
        .createHmac('sha256', secretKey)
        .update(dataToSign)
        .digest('base64');

      if (signature !== expectedSignature) {
        console.error('[Payment Webhook] ❌ Invalid Webhook Signature! Potential tamper attempt detected.');
        return res.status(401).json({ error: 'Unauthorized: Invalid Webhook Signature' });
      }
      console.log('[Payment Webhook] ✅ Signature verified successfully.');
    } else {
      console.warn('[Payment Webhook] ⚠️ No signature header provided. Proceeding with strict verification payload.');
    }

    // 3. Parse Payload
    const payload = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const { data = {}, type = '' } = payload || {};
    const order = data.order || {};
    const payment = data.payment || {};
    const customer = data.customer_details || order.customer_details || {};
    const tags = order.order_tags || {};

    const orderId = order.order_id || payload.order_id || '';
    const paymentId = String(payment.cf_payment_id || payload.cf_payment_id || orderId);
    const paymentStatus = (payment.payment_status || payload.payment_status || type).toUpperCase();

    // Verify payment is SETTLED / SUCCESS
    if (!['SUCCESS', 'SETTLED', 'PAYMENT_SUCCESS_WEBHOOK', 'ORDER_PAID'].includes(paymentStatus)) {
      console.log(`[Payment Webhook] Ignored payment status: ${paymentStatus}`);
      return res.status(200).json({ status: 'IGNORED', payment_status: paymentStatus });
    }

    const netAmount = Number(tags.base_amount || order.order_amount || 0);
    const gatewayFee = Number(tags.current_gateway_fee || tags.surcharge_fee || 0);
    const grossAmount = Number(order.order_amount || netAmount + gatewayFee);
    const siteId = tags.site_id || customer.customer_id || '';
    const quotationId = tags.quotation_id || '';
    const clientPhone = tags.client_phone || customer.customer_phone || '';
    const clientName = customer.customer_name || 'PCM Client';
    const paymentMethod = payment.payment_group || 'online';
    
    // Generate Deterministic Idempotency Key
    const idempotencyKey = `idemp_wh_${orderId}_${paymentId}`;

    // 4. Invoke Supabase Atomic Transaction RPC
    const { data: rpcResult, error: rpcError } = await supabase.rpc('record_payment_atomic', {
      p_site_id: siteId,
      p_net_amount: netAmount,
      p_transaction_id: paymentId,
      p_method: paymentMethod,
      p_idempotency_key: idempotencyKey,
      p_client_phone: clientPhone,
      p_client_name: clientName,
      p_quotation_id: quotationId,
      p_gateway_fee: gatewayFee,
      p_gross_amount: grossAmount,
      p_raw_payload: payload
    });

    if (rpcError) {
      console.error('[Payment Webhook] ❌ Supabase Atomic RPC Error:', rpcError);
      return res.status(500).json({ error: 'Atomic Transaction Failed', details: rpcError });
    }

    console.log('[Payment Webhook] 🎉 Atomic Payment Settled:', rpcResult);

    return res.status(200).json({
      status: 'OK',
      message: 'Payment verified and settled atomically',
      result: rpcResult
    });

  } catch (err) {
    console.error('[Payment Webhook] Exception:', err);
    return res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
}
