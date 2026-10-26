const express = require('express');
const bcrypt = require('bcryptjs');
const { loadDB, saveDB } = require('../db');
const { STATIC_RATES } = require('../config');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');
const { getSupabaseClient, isSupabaseConfigured } = require('../config/supabase');

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
router.patch('/customers/:id/activate', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const user = db.users.find(u => u.id === id);
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  user.status = 'active';
  if (req.body.paket_id) user.paket_id = parseInt(req.body.paket_id);

  // Automatically create first invoice when activated if none exists for this month
  let newInv = null;
  const existingInv = db.invoices.find(inv => inv.user_id === user.id && inv.periode === 'Oktober 2026');
  if (!existingInv && user.paket_id) {
    const pkg = db.packages.find(p => p.id === user.paket_id) || db.packages[0];
    const rate = STATIC_RATES.idrPerCurrency[user.mata_uang] || 1.0;
    newInv = {
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

  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      await sb.from('users').update({ status: 'active', paket_id: user.paket_id }).eq('id', id);
      if (newInv) {
        await sb.from('invoices').upsert(newInv, { onConflict: 'id' });
      }
    }
  }

  saveDB(db);
  return res.json({ success: true, message: 'Pelanggan berhasil diaktifkan', user });
});

// Admin add new staff / technician
router.post('/staff', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
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

  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      await sb.from('users').upsert(newStaff, { onConflict: 'id' });
    }
  }

  db.users.push(newStaff);
  saveDB(db);
  const { password_hash: _, ...safeStaff } = newStaff;
  return res.status(201).json({ success: true, message: 'Staf teknisi berhasil ditambahkan', staff: safeStaff });
});

// ==========================================
// PACKAGE CHANGE REQUESTS (APPROVAL WORKFLOW - ONLINE SUPABASE)
// ==========================================

// 1. Pelanggan mengajukan perubahan paket
const handlePackageChangeRequest = async (req, res) => {
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

  // Cek apakah ada request pending sebelumnya di Supabase / lokal
  let existingPending = null;
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      const { data: remotePending } = await sb
        .from('package_requests')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();
      if (remotePending) {
        existingPending = remotePending;
      }
    }
  }

  if (!existingPending) {
    existingPending = (db.package_requests || []).find(
      r => r.user_id === user.id && r.status === 'pending'
    );
  }

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
  const detectedReason = alasan || (detectedType === 'Upgrade Kecepatan' ? 'Ingin koneksi lebih cepat dan stabil' : 'Penyesuaian kebutuhan keluarga');

  let newRequest = null;

  // Dapatkan ID berikutnya yang terjamin unik (menghindari PostgreSQL sequence out-of-sync di Supabase)
  const maxLocalId = (db.package_requests || []).length > 0 
    ? Math.max(...db.package_requests.map(r => r.id || 0)) 
    : 0;
  let targetId = maxLocalId + 1;

  // Insert langsung ke Supabase jika terhubung online
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        // Cek ID tertinggi di Supabase remote
        const { data: latestRows } = await sb
          .from('package_requests')
          .select('id')
          .order('id', { ascending: false })
          .limit(1);

        if (latestRows && latestRows.length > 0 && latestRows[0].id >= targetId) {
          targetId = latestRows[0].id + 1;
        }

        const requestPayload = {
          id: targetId,
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
          alasan: detectedReason,
          status: 'pending',
          admin_catatan: ''
        };

        const { data: inserted, error: insertErr } = await sb
          .from('package_requests')
          .upsert(requestPayload, { onConflict: 'id' })
          .select()
          .single();

        if (!insertErr && inserted) {
          newRequest = inserted;
          console.log(`[Supabase DB] Package request #${inserted.id} successfully created online.`);
        } else if (insertErr) {
          console.error('[Supabase DB Package Request Insert Error]:', insertErr.message);
        }
      } catch (err) {
        console.error('[Supabase DB Exception]:', err.message);
      }
    }
  }

  // Fallback offline bila Supabase tidak merespons
  if (!newRequest) {
    newRequest = {
      id: targetId,
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
      alasan: detectedReason,
      status: 'pending',
      admin_catatan: '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
  }

  // Sinkronkan ke cache lokal memory & json
  db.package_requests.push(newRequest);
  saveDB(db);

  return res.status(201).json({
    success: true,
    message: `Pengajuan ${detectedType} ke "${newPkg.nama}" berhasil diajukan dan sedang ditinjau admin!`,
    request: newRequest
  });
};

// 1.b Pelanggan mengajukan berhenti / putus langganan
const handleTerminationRequest = async (req, res) => {
  const db = loadDB();
  const userId = req.user.id;
  const user = db.users.find(u => u.id === userId);
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  // Cek apakah ada request pending sebelumnya di Supabase / lokal
  let existingPending = null;
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      const { data: remotePending } = await sb
        .from('package_requests')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();
      if (remotePending) {
        existingPending = remotePending;
      }
    }
  }

  if (!existingPending) {
    existingPending = (db.package_requests || []).find(
      r => r.user_id === user.id && r.status === 'pending'
    );
  }

  if (existingPending) {
    return res.status(400).json({
      success: false,
      message: `Anda masih memiliki pengajuan "${existingPending.tipe}" yang sedang ditinjau admin.`
    });
  }

  const { alasan, catatan } = req.body;
  const fullReason = catatan && catatan.trim().length > 0 
    ? `${alasan || 'Pemutusan Langganan'} - Catatan: ${catatan.trim()}`
    : (alasan || 'Permintaan pemutusan layanan oleh pelanggan');

  const oldPkg = db.packages.find(p => p.id === user.paket_id);
  const oldPrice = oldPkg ? oldPkg.harga_idr : 0;
  const oldSpeed = oldPkg ? oldPkg.kecepatan_mbps : 0;

  const maxLocalId = (db.package_requests || []).length > 0 
    ? Math.max(...db.package_requests.map(r => r.id || 0)) 
    : 0;
  let targetId = maxLocalId + 1;

  let newRequest = null;
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        const { data: latestRows } = await sb
          .from('package_requests')
          .select('id')
          .order('id', { ascending: false })
          .limit(1);

        if (latestRows && latestRows.length > 0 && latestRows[0].id >= targetId) {
          targetId = latestRows[0].id + 1;
        }

        const requestPayload = {
          id: targetId,
          user_id: user.id,
          user_nama: user.nama,
          user_email: user.email,
          user_alamat: user.alamat || '',
          user_no_hp: user.no_hp || '',
          paket_lama_id: oldPkg ? oldPkg.id : null,
          paket_lama_nama: oldPkg ? oldPkg.nama : 'Paket Aktif',
          paket_lama_kecepatan: oldSpeed,
          paket_lama_harga: oldPrice,
          paket_baru_id: 0,
          paket_baru_nama: 'Nonaktif (Putus Langganan)',
          paket_baru_kecepatan: 0,
          paket_baru_harga: 0,
          selisih_harga: -oldPrice,
          tipe: 'Berhenti Berlangganan',
          alasan: fullReason,
          status: 'pending',
          admin_catatan: ''
        };

        const { data: inserted, error: insertErr } = await sb
          .from('package_requests')
          .upsert(requestPayload, { onConflict: 'id' })
          .select()
          .single();

        if (!insertErr && inserted) {
          newRequest = inserted;
          console.log(`[Supabase DB] Termination request #${inserted.id} successfully created online.`);
        } else if (insertErr) {
          console.error('[Supabase DB Termination Request Error]:', insertErr.message);
        }
      } catch (err) {
        console.error('[Supabase DB Exception]:', err.message);
      }
    }
  }

  if (!newRequest) {
    newRequest = {
      id: targetId,
      user_id: user.id,
      user_nama: user.nama,
      user_email: user.email,
      user_alamat: user.alamat || '',
      user_no_hp: user.no_hp || '',
      paket_lama_id: oldPkg ? oldPkg.id : null,
      paket_lama_nama: oldPkg ? oldPkg.nama : 'Paket Aktif',
      paket_lama_kecepatan: oldSpeed,
      paket_lama_harga: oldPrice,
      paket_baru_id: 0,
      paket_baru_nama: 'Nonaktif (Putus Langganan)',
      paket_baru_kecepatan: 0,
      paket_baru_harga: 0,
      selisih_harga: -oldPrice,
      tipe: 'Berhenti Berlangganan',
      alasan: fullReason,
      status: 'pending',
      admin_catatan: '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
  }

  db.package_requests.push(newRequest);
  saveDB(db);

  return res.status(201).json({
    success: true,
    message: 'Pengajuan berhenti berlangganan berhasil dikirim. Admin akan meninjau dan menjadwalkan penarikan perangkat.',
    request: newRequest
  });
};

router.post('/packages/change-request', authMiddleware, handlePackageChangeRequest);
router.post('/customer/change-request', authMiddleware, handlePackageChangeRequest);
router.post('/customer/termination-request', authMiddleware, handleTerminationRequest);

// 2. Pelanggan melihat riwayat & status pengajuan aktifnya (Langsung Supabase Online)
router.get('/customer/change-request', authMiddleware, async (req, res) => {
  const db = loadDB();
  const userId = req.user.id;

  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        const { data: remoteReqs, error } = await sb
          .from('package_requests')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (!error && remoteReqs) {
          // Sinkronkan ke local cache
          const otherReqs = (db.package_requests || []).filter(r => r.user_id !== userId);
          db.package_requests = [...otherReqs, ...remoteReqs];

          const pending = remoteReqs.find(r => r.status === 'pending') || null;
          return res.json({
            success: true,
            pending,
            requests: remoteReqs
          });
        }
      } catch (err) {
        console.warn('[Supabase DB GET Requests Note]:', err.message);
      }
    }
  }

  // Fallback lokal
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

// 3. Admin melihat semua pengajuan ubah paket (Langsung Supabase Online)
router.get('/admin/package-requests', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
  const db = loadDB();

  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        const { data: remoteReqs, error } = await sb
          .from('package_requests')
          .select('*')
          .order('created_at', { ascending: false });

        if (!error && remoteReqs) {
          db.package_requests = remoteReqs;
          return res.json({ success: true, requests: remoteReqs });
        }
      } catch (err) {
        console.warn('[Supabase DB GET All Requests Note]:', err.message);
      }
    }
  }

  // Fallback lokal
  const requests = (db.package_requests || [])
    .slice()
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  return res.json({ success: true, requests });
});

// 4. Admin menyetujui (Approve) pengajuan ubah paket (Sinkron Supabase Online)
router.post('/admin/package-requests/:id/approve', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
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
  request.admin_catatan = req.body.admin_catatan || (request.tipe === 'Berhenti Berlangganan' ? 'Pemutusan langganan disetujui oleh admin.' : 'Pengajuan disetujui oleh admin.');
  request.updated_at = new Date().toISOString();

  // JIKA TIPE: BERHENTI BERLANGGANAN
  if (request.tipe === 'Berhenti Berlangganan') {
    user.status = 'inactive';
    user.paket_id = null;

    // Buat SPK Tugas Teknisi untuk penarikan modem/ONT & kabel
    const tech = db.users.find(u => u.role === 'teknisi') || { id: 1 };
    const terminationTask = {
      id: db.tasks.length ? Math.max(...db.tasks.map(t => t.id)) + 1 : 1,
      teknisi_id: tech.id,
      pelanggan_id: user.id,
      jenis: 'pencopotan',
      status: 'baru',
      catatan: `Pencopotan perangkat modem/ONT & penarikan kabel dropcore pemutusan langganan: ${user.nama} (${user.no_hp}). Alamat: ${user.alamat || '-'}. Alasan: ${request.alasan || '-'}`
    };
    db.tasks.push(terminationTask);

    if (isSupabaseConfigured()) {
      const sb = getSupabaseClient();
      if (sb) {
        try {
          await Promise.all([
            sb.from('package_requests').update({
              status: 'approved',
              admin_catatan: request.admin_catatan,
              updated_at: request.updated_at
            }).eq('id', id),
            sb.from('users').update({
              status: 'inactive',
              paket_id: null
            }).eq('id', user.id),
            sb.from('tasks').upsert(terminationTask, { onConflict: 'id' })
          ]);
          console.log(`[Supabase DB] Termination request #${id} approved online.`);
        } catch (err) {
          console.error('[Supabase DB Termination Approval Sync Error]:', err.message);
        }
      }
    }

    saveDB(db);

    return res.json({
      success: true,
      message: `Pemutusan langganan ${request.user_nama} berhasil disetujui. Status akun dinonaktifkan dan SPK penarikan perangkat telah dikirimkan ke teknisi.`,
      request,
      user
    });
  }

  // Update paket pelanggan (untuk ubah/upgrade/downgrade paket)
  user.paket_id = request.paket_baru_id;

  // Update tagihan pelanggan: jika ada tagihan yang belum lunas, sesuaikan nominalnya.
  // Jika semua tagihan sudah lunas, terbitkan tagihan periode berikutnya dengan harga paket baru.
  let newInvoice = null;
  const unpaidInv = db.invoices.find(inv => inv.user_id === user.id && inv.status === 'belum');
  if (unpaidInv) {
    unpaidInv.nominal_idr = request.paket_baru_harga;
  } else {
    const nextInvoiceId = db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1;
    newInvoice = {
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
  let newTask = null;
  if (request.paket_baru_kecepatan > request.paket_lama_kecepatan) {
    const tech = db.users.find(u => u.role === 'teknisi') || { id: 1 };
    newTask = {
      id: db.tasks.length ? Math.max(...db.tasks.map(t => t.id)) + 1 : 1,
      teknisi_id: tech.id,
      pelanggan_id: user.id,
      jenis: 'instalasi',
      status: 'baru',
      catatan: `Pergantian/konfigurasi perangkat ONT untuk upgrade paket "${request.paket_baru_nama}" (${request.paket_baru_kecepatan} Mbps). Pelanggan: ${user.nama} (${user.no_hp}).`
    };
    db.tasks.push(newTask);
  }

  // SINKRONISASI LANGSUNG KE SUPABASE ONLINE
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        await Promise.all([
          // 1. Update status request
          sb.from('package_requests').update({
            status: 'approved',
            admin_catatan: request.admin_catatan,
            updated_at: request.updated_at
          }).eq('id', id),
          // 2. Update user paket_id
          sb.from('users').update({
            paket_id: request.paket_baru_id
          }).eq('id', user.id),
          // 3. Update / Insert invoice
          unpaidInv
            ? sb.from('invoices').update({ nominal_idr: unpaidInv.nominal_idr }).eq('id', unpaidInv.id)
            : (newInvoice ? sb.from('invoices').upsert(newInvoice, { onConflict: 'id' }) : Promise.resolve()),
          // 4. Insert task jika ada
          newTask ? sb.from('tasks').upsert(newTask, { onConflict: 'id' }) : Promise.resolve()
        ]);
        console.log(`[Supabase DB] Package request #${id} approved and synced online.`);
      } catch (err) {
        console.error('[Supabase DB Approval Sync Error]:', err.message);
      }
    }
  }

  saveDB(db);

  return res.json({
    success: true,
    message: `Pengajuan ${request.user_nama} berhasil disetujui! Paket aktif dan tagihan telah diperbarui secara online.`,
    request,
    user
  });
});

// 5. Admin menolak (Reject) pengajuan ubah paket (Sinkron Supabase Online)
router.post('/admin/package-requests/:id/reject', authMiddleware, roleMiddleware(['admin']), async (req, res) => {
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

  // SINKRONISASI LANGSUNG KE SUPABASE ONLINE
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        await sb.from('package_requests').update({
          status: 'rejected',
          admin_catatan: request.admin_catatan,
          updated_at: request.updated_at
        }).eq('id', id);
        console.log(`[Supabase DB] Package request #${id} rejected and synced online.`);
      } catch (err) {
        console.error('[Supabase DB Rejection Sync Error]:', err.message);
      }
    }
  }

  saveDB(db);

  return res.json({
    success: true,
    message: `Pengajuan ${request.user_nama} telah ditolak.`,
    request
  });
});

// ==========================================
// GAMIFICATION: TILT FIBER OPTIC REWARD
// ==========================================

// 1. Cek status klaim reward game pelanggan
router.get('/customer/game-reward-status', authMiddleware, (req, res) => {
  const db = loadDB();
  const userId = req.user.id;

  // Cek apakah ada invoice yang sudah diklaim voucher game
  const claimedInvoice = (db.invoices || []).find(
    inv => inv.user_id === userId && inv.voucher_code === 'FIBERHEMAT10'
  );

  return res.json({
    success: true,
    already_claimed: !!claimedInvoice,
    claimed_invoice_id: claimedInvoice ? claimedInvoice.id : null,
    voucher_code: 'FIBERHEMAT10',
    discount_amount: 25000
  });
});

// 2. Klaim voucher reward dari Mini-game Fiber ke Tagihan
router.post('/customer/claim-game-reward', authMiddleware, async (req, res) => {
  const db = loadDB();
  const userId = req.user.id;
  const { score } = req.body;

  if (score === undefined || score < 70) {
    return res.status(400).json({
      success: false,
      message: 'Skor minimal 70 diperlukan untuk mendapatkan redaman optik prima dan mengklaim voucher.'
    });
  }

  // Cek apakah invoice belum lunas milik user ini sudah memiliki voucher
  let targetInvoice = (db.invoices || []).find(
    inv => inv.user_id === userId && inv.status === 'belum'
  );

  // Jika tidak ada invoice 'belum' (semua lunas), buatkan invoice berjalan agar bisa langsung didemokan
  if (!targetInvoice) {
    const user = (db.users || []).find(u => u.id === userId);
    const pkg = (db.packages || []).find(p => p.id === (user?.paket_id || 2)) || db.packages[0];
    const rate = STATIC_RATES.idrPerCurrency[user?.mata_uang || 'IDR'] || 1.0;
    
    targetInvoice = {
      id: db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1,
      user_id: userId,
      periode: 'Desember 2026',
      nominal_idr: pkg.harga_idr,
      mata_uang: user?.mata_uang || 'IDR',
      kurs_terkunci: rate,
      jatuh_tempo: '2026-12-25T23:59:59.000Z',
      status: 'belum',
      diskon_idr: 0,
      voucher_code: null
    };
    db.invoices.push(targetInvoice);
  }

  if (targetInvoice.diskon_idr && targetInvoice.diskon_idr > 0) {
    return res.status(400).json({
      success: false,
      message: 'Voucher diskon sudah pernah diaplikasikan ke tagihan periode ini.',
      invoice: targetInvoice
    });
  }

  const discountAmount = 25000;
  targetInvoice.diskon_idr = discountAmount;
  targetInvoice.voucher_code = 'FIBERHEMAT10';

  // SINKRONKAN KE SUPABASE JIKA ONLINE
  if (isSupabaseConfigured()) {
    const sb = getSupabaseClient();
    if (sb) {
      try {
        await sb.from('invoices').upsert({
          id: targetInvoice.id,
          diskon_idr: targetInvoice.diskon_idr,
          voucher_code: targetInvoice.voucher_code
        }, { onConflict: 'id' });
        console.log(`[Supabase DB] Invoice #${targetInvoice.id} updated with game discount reward.`);
      } catch (err) {
        console.warn('[Supabase Sync Warning]:', err.message);
      }
    }
  }

  saveDB(db);

  return res.json({
    success: true,
    message: '🎉 Selamat! Diskon Rp 25.000 berhasil dipotongkan langsung ke tagihan Anda.',
    discount: discountAmount,
    voucher_code: 'FIBERHEMAT10',
    invoice: targetInvoice
  });
});

module.exports = router;
