const express = require('express');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { calculateBlockHash } = require('../utils/hash');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');
const { getSupabaseClient, isSupabaseConfigured } = require('../config/supabase');
const upload = require('../middleware/upload.middleware');

const { uploadFile } = require('../services/storage.service');

const router = express.Router();

async function activateCustomerOnPaymentVerified(db, invoice) {
  if (!invoice) return;
  const user = db.users.find(u => u.id === invoice.user_id);
  if (!user) return;

  // 1. Ubah status user menjadi aktif (layanan kembali berjalan)
  user.status = 'active';

  // 2. Pastikan paket_id terisi paket yang sesuai dengan invoice
  if (!user.paket_id || user.paket_id <= 0) {
    const matchingPkg = db.packages.find(p => p.harga_idr === invoice.nominal_idr) || db.packages[0];
    user.paket_id = matchingPkg ? matchingPkg.id : 1;
  }

  // 3. Selesaikan jika ada package_requests pending untuk user ini
  const pendingReq = (db.package_requests || []).find(r => r.user_id === user.id && r.status === 'pending');
  if (pendingReq) {
    pendingReq.status = 'approved';
    pendingReq.updated_at = new Date().toISOString();
  }

  // 4. Sinkronkan online ke Supabase PostgreSQL
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        await Promise.all([
          sb.from('users').update({ status: 'active', paket_id: user.paket_id }).eq('id', user.id),
          sb.from('invoices').update({ status: 'lunas' }).eq('id', invoice.id),
          pendingReq
            ? sb.from('package_requests').update({ status: 'approved', updated_at: pendingReq.updated_at }).eq('id', pendingReq.id)
            : Promise.resolve()
        ]);
        console.log(`[Invoice] Pelanggan #${user.id} (${user.nama}) status aktif & paket #${user.paket_id} terverifikasi lunas.`);
      } catch (err) {
        console.warn('[Invoice] Supabase sync note on payment verify:', err.message);
      }
    }
  }
}

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
    const payment = [...(db.payments || [])].reverse().find(p => p.invoice_id === inv.id);
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
router.post('/payments', authMiddleware, upload.single('bukti'), async (req, res) => {
  const db = loadDB();
  const invoice_id = parseInt(req.body.invoice_id);
  const invoice = db.invoices.find(i => i.id === invoice_id);

  if (!invoice) {
    return res.status(404).json({ success: false, message: 'Tagihan tidak ditemukan' });
  }

  let bukti_path = req.body.bukti_path || '/uploads/sample_receipt.png';
  if (req.file) {
    bukti_path = await uploadFile(req.file, 'receipts');
  }

  const netAmount = Math.max(0, invoice.nominal_idr - (invoice.diskon_idr || 0));

  // Check if a payment record already exists
  let payment = db.payments.find(p => p.invoice_id === invoice_id);
  if (payment) {
    payment.bukti_path = bukti_path;
    payment.nominal_idr = netAmount;
    payment.status = 'menunggu';
  } else {
    payment = {
      id: db.payments.length ? Math.max(...db.payments.map(p => p.id)) + 1 : 1,
      invoice_id,
      user_id: req.user.id,
      bukti_path,
      nominal_idr: netAmount,
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
router.patch('/payments/:id/verify', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const status = req.body.status || 'diverifikasi'; // 'diverifikasi' or 'ditolak'

  const payment = db.payments.find(p => p.id === id);
  if (!payment) return res.status(404).json({ success: false, message: 'Pembayaran tidak ditemukan' });

  payment.status = status;
  payment.verified_at = new Date().toISOString();

  const invoice = db.invoices.find(inv => inv.id === payment.invoice_id);
  if (status === 'diverifikasi') {
    if (invoice) {
      invoice.status = 'lunas';
      await activateCustomerOnPaymentVerified(db, invoice);
    }

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

// Admin manual verify invoice (e.g. cash or direct transfer verification)
router.post('/invoices/:id/verify-manual', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const status = req.body.status || 'diverifikasi'; // 'diverifikasi' or 'ditolak'

  const invoice = db.invoices.find(inv => inv.id === id);
  if (!invoice) return res.status(404).json({ success: false, message: 'Tagihan tidak ditemukan' });

  let payment = [...(db.payments || [])].reverse().find(p => p.invoice_id === id);
  if (!payment) {
    payment = {
      id: db.payments.length ? Math.max(...db.payments.map(p => p.id)) + 1 : 1,
      invoice_id: id,
      user_id: invoice.user_id,
      bukti_path: req.body.bukti_path || 'MANUAL_VERIFIKASI_ADMIN',
      nominal_idr: invoice.nominal_idr,
      status: status,
      verified_at: new Date().toISOString()
    };
    db.payments.push(payment);
  } else {
    payment.status = status;
    payment.verified_at = new Date().toISOString();
  }

  if (status === 'diverifikasi') {
    invoice.status = 'lunas';
    await activateCustomerOnPaymentVerified(db, invoice);

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
    invoice.status = 'belum';
  }

  saveDB(db);
  return res.json({
    success: true,
    message: status === 'diverifikasi' ? 'Pembayaran berhasil diverifikasi manual dan dicatat ke blockchain ledger!' : 'Pembayaran ditolak',
    payment,
    invoice
  });
});

module.exports = router;
