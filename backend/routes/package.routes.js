const express = require('express');
const { loadDB, saveDB } = require('../db');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get all packages (Public & cached)
router.get('/packages', (req, res) => {
  const db = loadDB();
  return res.json({ success: true, packages: db.packages });
});

// Admin create new package
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

// Admin update package
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

// Admin delete package
router.delete('/packages/:id', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  db.packages = db.packages.filter(p => p.id !== id);
  saveDB(db);
  return res.json({ success: true, message: 'Paket berhasil dihapus' });
});

module.exports = router;
