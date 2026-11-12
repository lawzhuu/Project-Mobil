// ==============================================================================
// PANDUAN PEMULA: MODUL AUTENTIKASI (REGISTER, LOGIN, & PROFILE)
// ==============================================================================
// Modul ini mengelola siklus otentikasi pengguna:
// 1. POST /auth/register: Pendaftaran pelanggan baru dengan hash password bcrypt & auto-token JWT.
// 2. POST /auth/login   : Verifikasi email/username dan password, menghasilkan token sesi JWT.
// 3. GET  /me           : Mengambil profil pengguna yang sedang login saat ini.
// 4. PUT  /me           : Memperbarui data profil dan koordinat GPS pelanggan.
// 5. POST /me/photo     : Mengunggah foto profil pengguna ke cloud storage.
// ==============================================================================

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config');
const { loadDB, saveDB } = require('../db');
const { authMiddleware } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

const router = express.Router();

// ==============================================================================
// 1. ENDPOINT REGISTRASI PELANGGAN BARU (POST /auth/register)
// ==============================================================================
router.post('/auth/register', (req, res) => {
  const db = loadDB();
  const { nama, email, no_hp, password, negara, alamat, lat, lng, foto, paket_id } = req.body;

  // Validasi kolom wajib (Nama, Email, Password)
  if (!email || !password || !nama) {
    return res.status(400).json({ success: false, message: 'Nama, email, dan password wajib diisi' });
  }

  // Cek apakah email sudah terdaftar sebelumnya
  const existing = db.users.find(u => u.email.toLowerCase() === email.toLowerCase());
  if (existing) {
    return res.status(400).json({ success: false, message: 'Email sudah terdaftar' });
  }

  // Penentuan otomatis mata uang & zona waktu berdasarkan negara asal pelanggan
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

  // ENKRIPSI PASSWORD: Menggunakan bcrypt dengan 10 putaran salt
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
    status: 'active', // Akun aktif agar pengguna baru dapat menjelajahi aplikasi dan memilih paket
    paket_id: paket_id ? parseInt(paket_id) : null
  };

  db.users.push(newUser);
  saveDB(db);

  try {
    const { isSupabaseConfigured, getSupabaseClient } = require('../config/supabase');
    if (isSupabaseConfigured()) {
      const sb = getSupabaseClient();
      if (sb) {
        sb.from('users').upsert({
          id: newUser.id,
          nama: newUser.nama,
          email: newUser.email,
          no_hp: newUser.no_hp,
          password_hash: newUser.password_hash,
          role: newUser.role,
          negara: newUser.negara,
          mata_uang: newUser.mata_uang,
          zona_waktu: newUser.zona_waktu,
          alamat: newUser.alamat,
          lat: newUser.lat,
          lng: newUser.lng,
          foto: newUser.foto,
          status: newUser.status,
          paket_id: newUser.paket_id
        }, { onConflict: 'id' }).then(({ error }) => {
          if (error) console.warn('[Supabase DB Register Sync Note]:', error.message);
        });
      }
    }
  } catch (err) {
    console.warn('[Supabase DB Register Exception]:', err.message);
  }

  const token = jwt.sign(
    { id: newUser.id, email: newUser.email, role: newUser.role, nama: newUser.nama },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const { password_hash: _, ...safeUser } = newUser;
  return res.status(201).json({
    success: true,
    message: 'Pendaftaran akun berhasil. Selamat datang di Sima.net!',
    token,
    user: safeUser
  });
});

// ==============================================================================
// 2. ENDPOINT LOGIN PENGGUNA (POST /auth/login)
// ==============================================================================
// Mendukung login Pelanggan, Admin, dan Teknisi:
// - Pencarian user berdasarkan email, username, atau alias IP admin (192.168.1.1).
// - Membandingkan password input dengan hash tersimpan menggunakan `bcrypt.compareSync()`.
// - Jika valid, membuat token JWT yang berlaku selama 7 hari (`expiresIn: '7d'`).
// - Menghapus `password_hash` dari objek user sebelum dikirim kembali ke client.
// ==============================================================================
router.post('/auth/login', (req, res) => {
  const db = loadDB();
  const { email, username, password } = req.body;
  const identifier = (email || username || '').trim();

  if (!identifier || !password) {
    return res.status(400).json({ success: false, message: 'Username/Email dan password wajib diisi' });
  }

  // Dukungan login via email, username, atau alias IP lokal router '192.168.1.1' -> admin
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

  // Komparasi kecocokan password dengan hash terenkripsi
  const isMatch = bcrypt.compareSync(password, user.password_hash);
  if (!isMatch) {
    return res.status(401).json({ success: false, message: 'Password salah' });
  }

  // Pembuatan Token JWT (JSON Web Token) dengan masa aktif 7 hari
  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role, nama: user.nama },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  // Buang password_hash agar aman tidak bocor ke sisi client / frontend Flutter
  const { password_hash: _, ...safeUser } = user;
  return res.json({
    success: true,
    message: 'Login berhasil',
    token,
    user: safeUser
  });
});

// ==============================================================================
// 3. ENDPOINT CEK PROFIL USER AKTIF (GET /me)
// ==============================================================================
router.get('/me', authMiddleware, (req, res) => {
  const db = loadDB();
  const user = db.users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
  const { password_hash: _, ...safeUser } = user;
  return res.json({ success: true, user: safeUser });
});

const { uploadFile } = require('../services/storage.service');

// ==============================================================================
// 4. ENDPOINT PERBARUI DATA PROFIL & KOORDINAT GPS (PUT /me)
// ==============================================================================
// - Mendukung pembaruan nama, nomor HP, alamat, negara, zona waktu, dan koordinat GPS.
// - Jika menyertakan upload file gambar 'foto', file langsung diunggah ke storage cloud.
// ==============================================================================
router.put('/me', authMiddleware, upload.single('foto'), async (req, res) => {
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
    const uploadedUrl = await uploadFile(req.file, 'avatars');
    if (uploadedUrl) {
      db.users[idx].foto = uploadedUrl;
    }
  }

  saveDB(db);
  const { password_hash: _, ...safeUser } = db.users[idx];
  return res.json({ success: true, message: 'Profil berhasil diperbarui', user: safeUser });
});

// ==============================================================================
// 5. ENDPOINT KHUSUS UNGGAH FOTO PROFIL AVATAR (POST /me/photo)
// ==============================================================================
// - Menerima form-data dengan kunci 'foto' via middleware `upload.single('foto')`.
// - Mengunggah file ke Supabase Storage (folder 'avatars') dan menyimpan URL-nya di DB.
// ==============================================================================
router.post('/me/photo', authMiddleware, upload.single('foto'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'File foto wajib diunggah' });
  }

  const db = loadDB();
  const idx = db.users.findIndex(u => u.id === req.user.id);
  if (idx === -1) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

  const uploadedUrl = await uploadFile(req.file, 'avatars');
  if (uploadedUrl) {
    db.users[idx].foto = uploadedUrl;
    saveDB(db);
    const { password_hash: _, ...safeUser } = db.users[idx];
    return res.json({
      success: true,
      message: 'Foto profil berhasil diunggah ke storage!',
      foto: uploadedUrl,
      user: safeUser
    });
  } else {
    return res.status(500).json({ success: false, message: 'Gagal mengunggah foto profil' });
  }
});

module.exports = router;

