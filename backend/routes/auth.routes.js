const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config');
const { loadDB, saveDB } = require('../db');
const { authMiddleware } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

const router = express.Router();

// Register new customer
router.post('/auth/register', (req, res) => {
  const db = loadDB();
  const { nama, email, no_hp, password, negara, alamat, lat, lng, foto, paket_id } = req.body;

  if (!email || !password || !nama) {
    return res.status(400).json({ success: false, message: 'Nama, email, dan password wajib diisi' });
  }

  const existing = db.users.find(u => u.email.toLowerCase() === email.toLowerCase());
  if (existing) {
    return res.status(400).json({ success: false, message: 'Email sudah terdaftar' });
  }

  // Country determines default currency and timezone per PRD
  let mata_uang = 'IDR';
  let zona_waktu = 'WIB';
  const countryLower = (negara || '').toLowerCase();
  if (countryLower.includes('united states') || countryLower.includes('usa') || countryLower.includes('us')) {
    mata_uang = 'USD';
    zona_waktu = 'London';
  } else if (countryLower.includes('europe') || countryLower.includes('germany') || countryLower.includes('uk') || countryLower.includes('belanda')) {
    mata_uang = 'EUR';
    zona_waktu = 'London';
  }

  const salt = bcrypt.genSaltSync(10);
  const password_hash = bcrypt.hashSync(password, salt);

  const newUser = {
    id: db.users.length ? Math.max(...db.users.map(u => u.id)) + 1 : 1,
    nama,
    email,
    no_hp: no_hp || '',
    password_hash,
    role: 'pelanggan',
    negara: negara || 'Indonesia',
    mata_uang,
    zona_waktu,
    alamat: alamat || '',
    lat: lat ? parseFloat(lat) : -7.7956,
    lng: lng ? parseFloat(lng) : 110.3695,
    foto: foto || '',
    status: 'pending', // Account is pending until activated by admin per PRD
    paket_id: paket_id ? parseInt(paket_id) : 1
  };

  db.users.push(newUser);
  saveDB(db);

  const token = jwt.sign(
    { id: newUser.id, email: newUser.email, role: newUser.role, nama: newUser.nama },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const { password_hash: _, ...safeUser } = newUser;
  return res.status(201).json({
    success: true,
    message: 'Pendaftaran berhasil. Akun Anda sedang menunggu aktivasi oleh admin.',
    token,
    user: safeUser
  });
});

// Login (Customer, Admin, Technician)
router.post('/auth/login', (req, res) => {
  const db = loadDB();
  const { email, username, password } = req.body;
  const identifier = (email || username || '').trim();

  if (!identifier || !password) {
    return res.status(400).json({ success: false, message: 'Username/Email dan password wajib diisi' });
  }

  // Support login via email, username, or legacy IP alias "192.168.1.1" -> admin
  const user = db.users.find(u => {
    if (u.email.toLowerCase() === identifier.toLowerCase()) return true;
    if (identifier === '192.168.1.1' && u.role === 'admin') return true;
    if (identifier === 'admin' && u.role === 'admin') return true;
    if (identifier === 'teknisi' && u.role === 'teknisi') return true;
    return false;
  });

  if (!user) {
    return res.status(401).json({ success: false, message: 'Kredensial login tidak valid' });
  }

  const isMatch = bcrypt.compareSync(password, user.password_hash);
  if (!isMatch) {
    return res.status(401).json({ success: false, message: 'Password salah' });
  }

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role, nama: user.nama },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const { password_hash: _, ...safeUser } = user;
  return res.json({
    success: true,
    message: 'Login berhasil',
    token,
    user: safeUser
  });
});

// Get current user profile
router.get('/me', authMiddleware, (req, res) => {
  const db = loadDB();
  const user = db.users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
  const { password_hash: _, ...safeUser } = user;
  return res.json({ success: true, user: safeUser });
});

// Update current user profile & avatar photo
router.put('/me', authMiddleware, upload.single('foto'), (req, res) => {
  const db = loadDB();
  const idx = db.users.findIndex(u => u.id === req.user.id);
  if (idx === -1) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

  const { nama, no_hp, alamat, negara, zona_waktu, mata_uang, lat, lng } = req.body;
  if (nama) db.users[idx].nama = nama;
  if (no_hp !== undefined) db.users[idx].no_hp = no_hp;
  if (alamat !== undefined) db.users[idx].alamat = alamat;
  if (negara) db.users[idx].negara = negara;
  if (zona_waktu) db.users[idx].zona_waktu = zona_waktu;
  if (mata_uang) db.users[idx].mata_uang = mata_uang;
  if (lat !== undefined && lat !== null) db.users[idx].lat = parseFloat(lat);
  if (lng !== undefined && lng !== null) db.users[idx].lng = parseFloat(lng);
  if (req.file) {
    db.users[idx].foto = `/uploads/${req.file.filename}`;
  }

  saveDB(db);
  const { password_hash: _, ...safeUser } = db.users[idx];
  return res.json({ success: true, message: 'Profil berhasil diperbarui', user: safeUser });
});

module.exports = router;
