const express = require('express');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// In-memory cache for live exchange rates (1 hour TTL)
let cachedRates = null;
let cacheExpiresAt = 0;
const CACHE_DURATION_MS = 60 * 60 * 1000;

async function fetchCdn(path) {
  const primaryUrl = `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/${path}`;
  const fallbackUrl = `https://latest.currency-api.pages.dev/v1/${path}`;

  try {
    const res = await fetch(primaryUrl, { signal: AbortSignal.timeout(4000) });
    if (res.ok) return await res.json();
  } catch (_) {}

  const fallbackRes = await fetch(fallbackUrl, { signal: AbortSignal.timeout(4000) });
  if (fallbackRes.ok) return await fallbackRes.json();
  throw new Error('Failed to fetch from both jsDelivr and Cloudflare Pages CDN');
}

// Get live currency exchange rates (fawazahmed0/exchange-api)
router.get('/rates', async (req, res) => {
  const now = Date.now();
  if (cachedRates && now < cacheExpiresAt) {
    return res.json({
      success: true,
      data: cachedRates,
      cached: true
    });
  }

  try {
    const [usdData, eurData] = await Promise.all([
      fetchCdn('currencies/usd.min.json'),
      fetchCdn('currencies/eur.min.json')
    ]);

    const usdToIdr = parseFloat(usdData?.usd?.idr) || 15500.0;
    const eurToIdr = parseFloat(eurData?.eur?.idr) || 16800.0;
    const dateStr = usdData?.date || new Date().toISOString().split('T')[0];

    cachedRates = {
      base: 'IDR',
      date: dateStr,
      source: 'fawazahmed0/exchange-api',
      rates: {
        IDR: 1.0,
        USD: Number((1 / usdToIdr).toFixed(8)),
        EUR: Number((1 / eurToIdr).toFixed(8))
      },
      idrPerCurrency: {
        IDR: 1.0,
        USD: Number(usdToIdr.toFixed(2)),
        EUR: Number(eurToIdr.toFixed(2))
      }
    };
    cacheExpiresAt = now + CACHE_DURATION_MS;

    return res.json({
      success: true,
      data: cachedRates,
      cached: false
    });
  } catch (err) {
    console.warn('[Rates] Live currency fetch error, fallback to STATIC_RATES:', err.message);
    return res.json({
      success: true,
      data: STATIC_RATES,
      fallback: true
    });
  }
});

// Get feedback entries
router.get('/feedback', (req, res) => {
  const db = loadDB();
  return res.json({ success: true, feedback: db.feedback });
});

// Submit user feedback (saran & kesan)
router.post('/feedback', authMiddleware, (req, res) => {
  const db = loadDB();
  const { saran, kesan } = req.body;

  if (!saran && !kesan) {
    return res.status(400).json({ success: false, message: 'Saran atau kesan tidak boleh kosong' });
  }

  const newFeedback = {
    id: db.feedback.length ? Math.max(...db.feedback.map(f => f.id)) + 1 : 1,
    user_id: req.user.id,
    user_nama: req.user.nama || 'Pelanggan',
    saran: saran || '',
    kesan: kesan || '',
    created_at: new Date().toISOString()
  };

  db.feedback.unshift(newFeedback);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Terima kasih atas saran dan kesan Anda!', feedback: newFeedback });
});

// Register FCM device token
router.post('/devices', authMiddleware, (req, res) => {
  const db = loadDB();
  const { token_fcm } = req.body;
  if (token_fcm) {
    const existing = db.devices.find(d => d.user_id === req.user.id && d.token_fcm === token_fcm);
    if (!existing) {
      db.devices.push({
        id: db.devices.length + 1,
        user_id: req.user.id,
        token_fcm
      });
      saveDB(db);
    }
  }
  return res.json({ success: true, message: 'Device FCM token berhasil didaftarkan' });
});

// Proxy for external Supabase storage objects (solves Android emulator DNS lookup failures)
router.get('/storage/proxy', async (req, res) => {
  const fileUrl = req.query.url;
  if (!fileUrl) return res.status(400).send('Missing url parameter');

  if (fileUrl.startsWith('/uploads')) {
    return res.redirect(fileUrl);
  }

  try {
    const fetchRes = await fetch(fileUrl);
    if (!fetchRes.ok) {
      return res.status(fetchRes.status).send('Failed to fetch image');
    }
    const contentType = fetchRes.headers.get('content-type') || 'image/jpeg';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=604800');
    const arrayBuffer = await fetchRes.arrayBuffer();
    return res.send(Buffer.from(arrayBuffer));
  } catch (err) {
    console.warn('[Storage Proxy Error]:', err.message);
    return res.status(500).send('Proxy error: ' + err.message);
  }
});

// Health check endpoint
router.get('/', (req, res) => {
  res.json({
    app: 'Sima.net API Server',
    status: 'online',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
