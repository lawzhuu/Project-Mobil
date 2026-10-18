const express = require('express');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get live currency exchange rates
router.get('/rates', (req, res) => {
  return res.json({
    success: true,
    data: STATIC_RATES
  });
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
