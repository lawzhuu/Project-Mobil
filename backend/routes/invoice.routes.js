const express = require('express');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { calculateBlockHash } = require('../utils/hash');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

const router = express.Router();

// Get invoices (Customer views own; Admin views all)
router.get('/invoices', authMiddleware, (req, res) => {
  const db = loadDB();
  let invoices = db.invoices;

  // Customers only see their own invoices; admin sees all
  if (req.user.role === 'pelanggan') {
    invoices = invoices.filter(inv => inv.user_id === req.user.id);
  }

  // Attach user, package, and payment details
  const enriched = invoices.map(inv => {
    const user = db.users.find(u => u.id === inv.user_id) || {};
    const pkg = db.packages.find(p => p.id === user.paket_id) || {};
    const payment = db.payments.find(p => p.invoice_id === inv.id);
    return {
      ...inv,
      pelanggan_nama: user.nama || 'Pelanggan',
      pelanggan_email: user.email || '',
      paket_nama: pkg.nama || 'Internet Sima.net',
      payment: payment || null
    };
  });

  return res.json({ success: true, invoices: enriched });
});

// Admin create invoice with locked exchange rate per PRD
router.post('/invoices', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { user_id, periode, nominal_idr, jatuh_tempo } = req.body;

  const user = db.users.find(u => u.id === parseInt(user_id));
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  // Lock exchange rate at time of invoice creation per PRD
  const lockedRate = STATIC_RATES.idrPerCurrency[user.mata_uang] || 1.0;

  const newInvoice = {
    id: db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1,
    user_id: user.id,
    periode: periode || 'November 2026',
    nominal_idr: parseInt(nominal_idr) || 275000,
    mata_uang: user.mata_uang,
    kurs_terkunci: lockedRate,
    jatuh_tempo: jatuh_tempo || '2026-11-25T23:59:59.000Z',
    status: 'belum'
  };

  db.invoices.push(newInvoice);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tagihan berhasil dibuat', invoice: newInvoice });
});

// Customer upload payment receipt
router.post('/payments', authMiddleware, upload.single('bukti'), (req, res) => {
  const db = loadDB();
  const invoice_id = parseInt(req.body.invoice_id);
  const invoice = db.invoices.find(i => i.id === invoice_id);

  if (!invoice) {
    return res.status(404).json({ success: false, message: 'Tagihan tidak ditemukan' });
  }

  const bukti_path = req.file ? `/uploads/${req.file.filename}` : (req.body.bukti_path || '/uploads/sample_receipt.png');

  // Check if a payment record already exists
  let payment = db.payments.find(p => p.invoice_id === invoice_id);
  if (payment) {
    payment.bukti_path = bukti_path;
    payment.status = 'menunggu';
  } else {
    payment = {
      id: db.payments.length ? Math.max(...db.payments.map(p => p.id)) + 1 : 1,
      invoice_id,
      user_id: req.user.id,
      bukti_path,
      nominal_idr: invoice.nominal_idr,
      status: 'menunggu',
      verified_at: null
    };
    db.payments.push(payment);
  }

  saveDB(db);
  return res.status(201).json({
    success: true,
    message: 'Bukti pembayaran berhasil diunggah. Menunggu verifikasi admin.',
    payment
  });
});

// Admin verify payment -> automatically creates block in blockchain ledger & sends notification
router.patch('/payments/:id/verify', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const status = req.body.status || 'diverifikasi'; // 'diverifikasi' or 'ditolak'

  const payment = db.payments.find(p => p.id === id);
  if (!payment) return res.status(404).json({ success: false, message: 'Pembayaran tidak ditemukan' });

  payment.status = status;
  payment.verified_at = new Date().toISOString();

  const invoice = db.invoices.find(inv => inv.id === payment.invoice_id);
  if (status === 'diverifikasi') {
    if (invoice) invoice.status = 'lunas';

    // Append block to blockchain ledger
    const lastBlock = db.ledger_blocks[db.ledger_blocks.length - 1];
    const newIdx = lastBlock ? lastBlock.idx + 1 : 1;
    const prevHash = lastBlock ? lastBlock.hash : '0000000000000000000000000000000000000000000000000000000000000000';
    const nowIso = new Date().toISOString();
    const newHash = calculateBlockHash(newIdx, nowIso, payment.id, payment.nominal_idr, prevHash);

    const newBlock = {
      idx: newIdx,
      waktu: nowIso,
      payment_id: payment.id,
      nominal_idr: payment.nominal_idr,
      prev_hash: prevHash,
      hash: newHash
    };

    db.ledger_blocks.push(newBlock);
  } else {
    if (invoice) invoice.status = 'belum';
  }

  saveDB(db);
  return res.json({
    success: true,
    message: status === 'diverifikasi' ? 'Pembayaran diverifikasi dan dicatat ke blockchain ledger!' : 'Pembayaran ditolak',
    payment
  });
});

module.exports = router;
