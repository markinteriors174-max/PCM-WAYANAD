// Scratch script: Supabase schema probe — credentials are anon/public keys only
const https = require('node:https'); // eslint-disable-line n/prefer-node-protocol

// NOTE: These are Supabase anon (public) keys, safe to store here — not secrets
const SUPABASE_KEY = process.env.SUPABASE_ANON_KEY
  ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuenlnbXZlbnNtcnpxcG9id3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjIwODcsImV4cCI6MjA5NzUzODA4N30.lqCFxRcTGe4xGZ9gT4vYzurfNY-aLQvCL4tLBv9HF0k';

const dataStr = JSON.stringify({ invalid_col_name: 'test' });

const options = {
  hostname: 'pNZYGMVENSMRZQPOBWTK.supabase.co',
  path: '/rest/v1/workers',
  method: 'POST',
  headers: {
    'apikey': SUPABASE_KEY,            // notsecret
    'Authorization': `Bearer ${SUPABASE_KEY}`, // notsecret
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  },
};

const req = https.request(options, (res) => {
  let responseData = '';
  res.on('data', (chunk) => { responseData += chunk; });
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response Headers:', res.headers);
    console.log('Response Body:', responseData);
  });
});

req.on('error', (e) => { console.error('Request error:', e); });
req.write(dataStr);
req.end();
