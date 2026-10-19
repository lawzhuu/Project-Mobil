const express = require('express');
const { loadDB, saveDB } = require('../db');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get tasks (Technician sees all or my_tasks; Admin sees all)
router.get('/tasks', authMiddleware, (req, res) => {
  const db = loadDB();
  let tasks = db.tasks || [];

  if (req.user.role === 'teknisi') {
    if (req.query.my_tasks === 'true') {
      tasks = tasks.filter(t => t.teknisi_id === req.user.id);
    }
  }

  const enriched = tasks.map(t => {
    const customer = db.users.find(u => u.id === t.pelanggan_id) || {};
    const tech = db.users.find(u => u.id === t.teknisi_id) || {};
    return {
      ...t,
      pelanggan_nama: customer.nama || 'Pelanggan',
      pelanggan_alamat: customer.alamat || '',
      pelanggan_no_hp: customer.no_hp || '',
      pelanggan_lat: customer.lat || -7.7956,
      pelanggan_lng: customer.lng || 110.3695,
      teknisi_nama: tech.nama || (t.teknisi_id ? 'Teknisi' : 'Belum Diambil'),
      is_my_task: req.user ? t.teknisi_id === req.user.id : false,
    };
  });

  return res.json({ success: true, tasks: enriched });
});

// Admin assign task to technician
router.post('/tasks', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { teknisi_id, pelanggan_id, jenis, catatan } = req.body;

  const newTask = {
    id: db.tasks.length ? Math.max(...db.tasks.map(t => t.id)) + 1 : 1,
    teknisi_id: teknisi_id ? parseInt(teknisi_id) : null,
    pelanggan_id: parseInt(pelanggan_id),
    jenis: jenis || 'instalasi',
    status: 'baru',
    catatan: catatan || ''
  };

  db.tasks.push(newTask);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tugas teknisi berhasil dibuat', task: newTask });
});

// Technician claim task
router.post('/tasks/:id/claim', authMiddleware, (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const task = db.tasks.find(t => t.id === id);

  if (!task) return res.status(404).json({ success: false, message: 'Tugas tidak ditemukan' });

  // STRICT RULE: Tugas yang sudah diambil terkunci dan tidak bisa diambil oleh teknisi manapun
  if (task.teknisi_id) {
    const tech = db.users.find(u => u.id === task.teknisi_id) || {};
    return res.status(400).json({
      success: false,
      message: `Tugas #${id} sudah diambil oleh ${tech.nama || 'teknisi lain'} dan terkunci.`
    });
  }

  // Set teknisi_id dan otomatis ubah status menjadi "dikerjakan"
  task.teknisi_id = req.user.id;
  task.status = 'dikerjakan';

  saveDB(db);
  return res.json({ success: true, message: 'Tugas berhasil diambil dan status otomatis berubah menjadi Dikerjakan', task });
});

// Technician / Admin update task status
router.patch('/tasks/:id', authMiddleware, (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const task = db.tasks.find(t => t.id === id);

  if (!task) return res.status(404).json({ success: false, message: 'Tugas tidak ditemukan' });

  const { status, catatan, teknisi_id } = req.body;

  // STRICT RULE: Tugas yang sudah selesai sudah final & terkunci, tidak dapat diubah lagi statusnya
  if (task.status === 'selesai' && status && status !== 'selesai') {
    return res.status(400).json({
      success: false,
      message: `Tugas #${id} sudah selesai dan terkunci permanen, status tidak dapat diubah lagi.`
    });
  }

  if (status) task.status = status; // 'baru', 'dikerjakan', 'selesai'
  if (catatan) task.catatan = catatan;
  if (teknisi_id !== undefined) task.teknisi_id = teknisi_id ? parseInt(teknisi_id) : null;

  saveDB(db);
  return res.json({ success: true, message: 'Status tugas berhasil diperbarui', task });
});

module.exports = router;
