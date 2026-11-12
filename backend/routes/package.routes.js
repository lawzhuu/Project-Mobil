// ==============================================================================
// PANDUAN PEMULA: MODUL KATALOG PAKET INTERNET (PACKAGE CRUD)
// ==============================================================================
// Modul ini mengelola katalog paket bandwidth internet Wi-Fi Sima.net:
// 1. GET    /packages    : Publik (bisa diakses siapa saja tanpa login) untuk melihat daftar paket.
// 2. POST   /packages    : Admin membuat paket internet baru (Nama, Kecepatan Mbps, Harga IDR).
// 3. PUT    /packages/:id: Admin memperbarui informasi tarif atau kecepatan paket.
// 4. DELETE /packages/:id: Admin menghapus paket internet dari katalog.
// ==============================================================================

const express = require('express');
const { loadDB, saveDB } = require('../db');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// 1. ENDPOINT MELIHAT SELURUH PAKET (GET /packages - Terbuka untuk Publik)
router.get('/packages', (req, res) => {
  const db = loadDB();
  return res.json({ success: true, packages: db.packages });
});

// 2. ENDPOINT MEMBUAT PAKET BARU (POST /packages - Khusus Admin)
router.post('/packages', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { nama, kecepatan_mbps, harga_idr, deskripsi } = req.body;
  const newPkg = {
    id: db.packages.length ? Math.max(...db.packages.map(p => p.id)) + 1 : 1,
    nama,
    kecepatan_mbps: parseInt(kecepatan_mbps) || 10,
    harga_idr: parseInt(harga_idr) || 150000,
    deskripsi: deskripsi || ''
  };
  db.packages.push(newPkg);
  saveDB(db);
  return res.status(201).json({ success: true, package: newPkg });
});

// 3. ENDPOINT UPDATE PAKET (PUT /packages/:id - Khusus Admin)
router.put('/packages/:id', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const idx = db.packages.findIndex(p => p.id === id);
  if (idx === -1) return res.status(404).json({ success: false, message: 'Paket tidak ditemukan' });

  const { nama, kecepatan_mbps, harga_idr, deskripsi } = req.body;
  if (nama) db.packages[idx].nama = nama;
  if (kecepatan_mbps) db.packages[idx].kecepatan_mbps = parseInt(kecepatan_mbps);
  if (harga_idr) db.packages[idx].harga_idr = parseInt(harga_idr);
  if (deskripsi) db.packages[idx].deskripsi = deskripsi;

  saveDB(db);
  return res.json({ success: true, package: db.packages[idx] });
});

// 4. ENDPOINT HAPUS PAKET (DELETE /packages/:id - Khusus Admin)
router.delete('/packages/:id', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  db.packages = db.packages.filter(p => p.id !== id);
  saveDB(db);
  return res.json({ success: true, message: 'Paket berhasil dihapus' });
});

module.exports = router;
