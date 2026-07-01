const https = require('https');
const http = require('http');
const { URL } = require('url');

const LONGCAT_API_KEY = process.env.LONGCAT_API_KEY;
const LONGCAT_BASE_URL = process.env.LONGCAT_BASE_URL || 'https://api.longcat.ai/v1';
const API_ACCESS_KEY = process.env.API_ACCESS_KEY || 'paperflow-s3cr3t-key-change-me';

function verifyAccessKey(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return false;
  return authHeader.slice(7) === API_ACCESS_KEY;
}

function proxyRequest(targetUrl, method, headers, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(targetUrl);
    const isHttps = url.protocol === 'https:';
    const httpModule = isHttps ? https : http;

    const options = {
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: url.pathname + url.search,
      method: method,
      headers: headers,
    };

    const proxyReq = httpModule.request(options, (proxyRes) => {
      const chunks = [];
      proxyRes.on('data', (chunk) => chunks.push(chunk));
      proxyRes.on('end', () => {
        resolve({
          status: proxyRes.statusCode,
          headers: proxyRes.headers,
          body: Buffer.concat(chunks),
        });
      });
    });

    proxyReq.on('error', reject);
    proxyReq.setTimeout(120000, () => {
      proxyReq.destroy();
      reject(new Error('Timeout'));
    });

    if (body) proxyReq.write(body);
    proxyReq.end();
  });
}

module.exports = async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Health check
  if (req.url === '/health') {
    return res.status(200).json({ status: 'ok', service: 'paperflow-backend' });
  }

  // Auth check
  if (!verifyAccessKey(req)) {
    return res.status(401).json({ error: 'Invalid access key' });
  }

  try {
    const targetPath = req.url;
    const targetUrl = `${LONGCAT_BASE_URL}${targetPath}`;

    const headers = {
      'Content-Type': req.headers['content-type'] || 'application/json',
      'Authorization': `Bearer ${LONGCAT_API_KEY}`,
    };

    const body = req.method !== 'GET' ? JSON.stringify(req.body) : null;

    const result = await proxyRequest(targetUrl, req.method, headers, body);

    // Forward response
    res.status(result.status);
    for (const [key, value] of Object.entries(result.headers)) {
      if (key.toLowerCase() !== 'transfer-encoding') {
        res.setHeader(key, value);
      }
    }
    res.send(result.body);
  } catch (err) {
    console.error('Proxy error:', err.message);
    res.status(502).json({ error: 'Proxy error', detail: err.message });
  }
};
