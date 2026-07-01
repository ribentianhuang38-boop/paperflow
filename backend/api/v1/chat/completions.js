const https = require('https');
const { URL } = require('url');

const API_KEY = process.env.MIMO_API_KEY;
const BASE_URL = process.env.MIMO_BASE_URL || 'https://api.xiaomimimo.com/v1';
const MODEL = process.env.MIMO_MODEL || 'mimo-v2.5';
const ACCESS_KEY = process.env.API_ACCESS_KEY || 'paperflow-s3cr3t-2026';

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();

  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ') || auth.slice(7) !== ACCESS_KEY) {
    return res.status(401).json({ error: 'Invalid access key' });
  }

  try {
    const target = `${BASE_URL}/chat/completions`;
    const hdrs = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`
    };
    const body = JSON.stringify(req.body);

    const result = await new Promise((resolve, reject) => {
      const url = new URL(target);
      const options = { hostname: url.hostname, path: url.pathname, method: 'POST', headers: hdrs };
      const proxyReq = https.request(options, (proxyRes) => {
        const chunks = [];
        proxyRes.on('data', (c) => chunks.push(c));
        proxyRes.on('end', () => resolve({ status: proxyRes.statusCode, headers: proxyRes.headers, body: Buffer.concat(chunks) }));
      });
      proxyReq.on('error', reject);
      proxyReq.setTimeout(180000, () => { proxyReq.destroy(); reject(new Error('Timeout')); });
      proxyReq.write(body);
      proxyReq.end();
    });

    res.status(result.status);
    for (const [k, v] of Object.entries(result.headers)) {
      if (k.toLowerCase() !== 'transfer-encoding') res.setHeader(k, v);
    }
    res.send(result.body);
  } catch (err) {
    res.status(502).json({ error: 'Proxy error', detail: err.message });
  }
};
