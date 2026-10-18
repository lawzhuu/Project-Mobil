const express = require('express');
const bcrypt = require('bcryptjs');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Admin get all customer accounts
router.get('/customers', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const customers = db.users
    .filter(u => u.role === 'pelanggan')
    .map(({ password_hash: _, ...safe }) => safe);
  return res.json({ success: true, customers });
});

// Admin activate customer account and generate first invoice
router.patch('/customers/:id/activate', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const user = db.users.find(u => u.id === id);
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  user.status = 'active';
  if (req.body.paket_id) user.paket_id = parseInt(req.body.paket_id);

  // Automatically create first invoice when activated if none exists for this month
  const existingInv = db.invoices.find(inv => inv.user_id === user.id && inv.periode === 'Oktober 2026');
  if (!existingInv && user.paket_id) {
    const pkg = db.packages.find(p => p.id === user.paket_id) || db.packages[0];
    const rate = STATIC_RATES.idrPerCurrency[user.mata_uang] || 1.0;
    const newInv = {
      id: db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1,
      user_id: user.id,
      periode: 'Oktober 2026',
      nominal_idr: pkg.harga_idr,
      mata_uang: user.mata_uang,
      kurs_terkunci: rate,
      jatuh_tempo: '2026-10-25T23:59:59.000Z',
      status: 'belum'
    };
    db.invoices.push(newInv);
  }

  saveDB(db);
  return res.json({ success: true, message: 'Pelanggan berhasil diaktifkan', user });
});

// Admin add new staff / technician
router.post('/staff', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { nama, email, no_hp, password, role, alamat, lat, lng } = req.body;

  if (!email || !password || !nama) {
    return res.status(400).json({ success: false, message: 'Nama, email, dan password wajib diisi' });
  }

  const salt = bcrypt.genSaltSync(10);
  const password_hash = bcrypt.hashSync(password, salt);

  const newStaff = {
    id: db.users.length ? Math.max(...db.users.map(u => u.id)) + 1 : 1,
    nama,
    email,
    no_hp: no_hp || '',
    password_hash,
    role: role || 'teknisi',
    negara: 'Indonesia',
    mata_uang: 'IDR',
    zona_waktu: 'WIB',
    alamat: alamat || '',
    lat: lat ? parseFloat(lat) : -7.7956,
    lng: lng ? parseFloat(lng) : 110.3695,
    foto: '',
    status: 'active',
    paket_id: null
  };

  db.users.push(newStaff);
  saveDB(db);
  const { password_hash: _, ...safeStaff } = newStaff;
  return res.status(201).json({ success: true, message: 'Staf teknisi berhasil ditambahkan', staff: safeStaff });
});

module.exports = router;
