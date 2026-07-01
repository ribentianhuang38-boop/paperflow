require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const https = require('https');
const http = require('http');
const { URL } = require('url');

const app = express();
const PORT = process.env.PORT || 3000;
const LONGCAT_API_KEY = process.env.LONGCAT_API_KEY;
const LONGCAT_BASE_URL = process.env.LONGCAT_BASE_URL || 'https://api.longcat.ai/v1';
const API_ACCESS_KEY = process.env.API_ACCESS_KEY;
const RATE_LIMIT_MAX = parseInt(process.env.RATE_LIMIT || '30');

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: RATE_LIMIT_MAX,
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/v1/', limiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'paperflow-backend' });
});

// Access key verification middleware
function verifyAccessKey(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing access key' });
  }
  const token = authHeader.slice(7);
  if (token !== API_ACCESS_KEY) {
    return res.status(403).json({ error: 'Invalid access key' });
  }
  next();
}

// Proxy: forward all /v1/* requests to Longcat
app.all('/v1/*', verifyAccessKey, (req, res) => {
  const targetUrl = new URL(req.originalUrl, LONGCAT_BASE_URL);
  const isHttps = targetUrl.protocol === 'https:';
  const httpModule = isHttps ? https : http;

  // Build headers - replace access key with real Longcat key
  const headers = {
    'Content-Type': req.headers['content-type'] || 'application/json',
    'Authorization': `Bearer ${LONGCAT_API_KEY}`,
  };

  // Forward request body
  const body = req.method !== 'GET' ? JSON.stringify(req.body) : null;

  const options = {
    hostname: targetUrl.hostname,
    port: targetUrl.port || (isHttps ? 443 : 80),
    path: targetUrl.pathname + targetUrl.search,
    method: req.method,
    headers: headers,
  };

  const proxyReq = httpModule.request(options, (proxyRes) => {
    // Forward status and headers
    res.writeHead(proxyRes.statusCode, {
      'Content-Type': proxyRes.headers['content-type'] || 'application/json',
      'Transfer-Encoding': 'chunked',
    });

    // Stream response back
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    if (!res.headersSent) {
      res.status(502).json({ error: 'Backend proxy error', detail: err.message });
    }
  });

  // Handle streaming (SSE) for chat completions
  proxyReq.setTimeout(120000, () => {
    proxyReq.destroy();
    if (!res.headersSent) {
      res.status(504).json({ error: 'Request timeout' });
    }
  });

  if (body) {
    proxyReq.write(body);
  }
  proxyReq.end();
});

// Fallback
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`PaperFlow backend running on port ${PORT}`);
  console.log(`Longcat API: ${LONGCAT_BASE_URL}`);
  console.log(`Rate limit: ${RATE_LIMIT_MAX} req/min per IP`);
});
