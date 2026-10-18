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

// ==========================================
// PACKAGE CHANGE REQUESTS (APPROVAL WORKFLOW)
// ==========================================

// 1. Pelanggan mengajukan perubahan paket
const handlePackageChangeRequest = (req, res) => {
  const db = loadDB();
  const userId = req.user.id;
  const user = db.users.find(u => u.id === userId);
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  const { paket_id, tipe, alasan } = req.body;
  if (!paket_id) {
    return res.status(400).json({ success: false, message: 'paket_id wajib diisi' });
  }

  const newPkgId = parseInt(paket_id);
  const newPkg = db.packages.find(p => p.id === newPkgId);
  if (!newPkg) {
    return res.status(404).json({ success: false, message: 'Paket target tidak ditemukan' });
  }

  // Cek apakah sudah memakai paket yang sama
  if (user.paket_id === newPkgId) {
    return res.status(400).json({ success: false, message: 'Ini adalah paket aktif Anda saat ini' });
  }

  // Cek apakah ada request pending sebelumnya
  const existingPending = (db.package_requests || []).find(
    r => r.user_id === user.id && r.status === 'pending'
  );
  if (existingPending) {
    return res.status(400).json({
      success: false,
      message: `Anda masih memiliki pengajuan ke "${existingPending.paket_baru_nama}" yang sedang ditinjau admin.`
    });
  }

  const oldPkg = db.packages.find(p => p.id === user.paket_id);
  const oldPrice = oldPkg ? oldPkg.harga_idr : 0;
  const oldSpeed = oldPkg ? oldPkg.kecepatan_mbps : 0;

  const detectedType = tipe || (newPkg.kecepatan_mbps > oldSpeed ? 'Upgrade Kecepatan' : 'Hemat Biaya (Downgrade)');

  const newRequest = {
    id: db.package_requests.length ? Math.max(...db.package_requests.map(r => r.id)) + 1 : 1,
    user_id: user.id,
    user_nama: user.nama,
    user_email: user.email,
    user_alamat: user.alamat || '',
    user_no_hp: user.no_hp || '',
    paket_lama_id: oldPkg ? oldPkg.id : null,
    paket_lama_nama: oldPkg ? oldPkg.nama : 'Belum Ada',
    paket_lama_kecepatan: oldSpeed,
    paket_lama_harga: oldPrice,
    paket_baru_id: newPkg.id,
    paket_baru_nama: newPkg.nama,
    paket_baru_kecepatan: newPkg.kecepatan_mbps,
    paket_baru_harga: newPkg.harga_idr,
    selisih_harga: newPkg.harga_idr - oldPrice,
    tipe: detectedType,
    alasan: alasan || (detectedType === 'Upgrade Kecepatan' ? 'Ingin koneksi lebih cepat dan stabil' : 'Penyesuaian kebutuhan keluarga'),
    status: 'pending',
    admin_catatan: '',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  db.package_requests.push(newRequest);
  saveDB(db);

  return res.status(201).json({
    success: true,
    message: `Pengajuan ${detectedType} ke "${newPkg.nama}" berhasil diajukan dan sedang ditinjau admin!`,
    request: newRequest
  });
};

router.post('/packages/change-request', authMiddleware, handlePackageChangeRequest);
router.post('/customer/change-request', authMiddleware, handlePackageChangeRequest);

// 2. Pelanggan melihat riwayat & status pengajuan aktifnya
router.get('/customer/change-request', authMiddleware, (req, res) => {
  const db = loadDB();
  const userId = req.user.id;
  const requests = (db.package_requests || [])
    .filter(r => r.user_id === userId)
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  const pending = requests.find(r => r.status === 'pending') || null;

  return res.json({
    success: true,
    pending,
    requests
  });
});

// 3. Admin melihat semua pengajuan ubah paket
router.get('/admin/package-requests', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const requests = (db.package_requests || [])
    .slice()
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return res.json({ success: true, requests });
});

// 4. Admin menyetujui (Approve) pengajuan ubah paket
router.post('/admin/package-requests/:id/approve', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const request = (db.package_requests || []).find(r => r.id === id);

  if (!request) {
    return res.status(404).json({ success: false, message: 'Pengajuan tidak ditemukan' });
  }

  if (request.status !== 'pending') {
    return res.status(400).json({ success: false, message: `Pengajuan sudah berstatus ${request.status}` });
  }

  const user = db.users.find(u => u.id === request.user_id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });
  }

  // Update status request
  request.status = 'approved';
  request.admin_catatan = req.body.admin_catatan || 'Pengajuan disetujui oleh admin';
  request.updated_at = new Date().toISOString();

  // Update paket pelanggan
  user.paket_id = request.paket_baru_id;

  // Update tagihan pelanggan: jika ada tagihan yang belum lunas, sesuaikan nominalnya.
  // Jika semua tagihan sudah lunas, terbitkan tagihan periode berikutnya dengan harga paket baru.
  const unpaidInv = db.invoices.find(inv => inv.user_id === user.id && inv.status === 'belum');
  if (unpaidInv) {
    unpaidInv.nominal_idr = request.paket_baru_harga;
  } else {
    const nextInvoiceId = db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1;
    const newInvoice = {
      id: nextInvoiceId,
      user_id: user.id,
      periode: "November 2026",
      nominal_idr: request.paket_baru_harga,
      mata_uang: user.mata_uang || "IDR",
      kurs_terkunci: user.mata_uang === 'USD' ? 15500 : 1,
      jatuh_tempo: "2026-11-25T23:59:59+00:00",
      status: "belum",
      created_at: new Date().toISOString()
    };
    db.invoices.push(newInvoice);
  }

  // Jika upgrade kecepatan, otomatis buat tugas teknisi (penggantian/penyesuaian perangkat)
  if (request.paket_baru_kecepatan > request.paket_lama_kecepatan) {
    const tech = db.users.find(u => u.role === 'teknisi') || { id: 1 };
    const newTask = {
      id: db.tasks.length ? Math.max(...db.tasks.map(t => t.id)) + 1 : 1,
      teknisi_id: tech.id,
      pelanggan_id: user.id,
      jenis: 'instalasi',
      status: 'baru',
      catatan: `Pergantian/konfigurasi perangkat ONT untuk upgrade paket "${request.paket_baru_nama}" (${request.paket_baru_kecepatan} Mbps). Pelanggan: ${user.nama} (${user.no_hp}).`
    };
    db.tasks.push(newTask);
  }

  saveDB(db);

  return res.json({
    success: true,
    message: `Pengajuan ${request.user_nama} berhasil disetujui! Paket aktif dan tagihan telah diperbarui.`,
    request,
    user
  });
});

// 5. Admin menolak (Reject) pengajuan ubah paket
router.post('/admin/package-requests/:id/reject', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const request = (db.package_requests || []).find(r => r.id === id);

  if (!request) {
    return res.status(404).json({ success: false, message: 'Pengajuan tidak ditemukan' });
  }

  if (request.status !== 'pending') {
    return res.status(400).json({ success: false, message: `Pengajuan sudah berstatus ${request.status}` });
  }

  request.status = 'rejected';
  request.admin_catatan = req.body.admin_catatan || 'Maaf, jaringan di wilayah Anda belum mendukung kapasitas paket ini.';
  request.updated_at = new Date().toISOString();

  saveDB(db);

  return res.json({
    success: true,
    message: `Pengajuan ${request.user_nama} telah ditolak.`,
    request
  });
});

module.exports = router;
