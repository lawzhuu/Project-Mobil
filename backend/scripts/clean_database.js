require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const fs = require('fs');
const path = require('path');
const { calculateBlockHash } = require('../utils/hash');
const { isSupabaseConfigured, getSupabaseClient } = require('../config/supabase');
const supabaseDb = require('../services/supabase_db.service');

const DB_FILE = path.join(__dirname, '..', 'database.json');

async function cleanDatabase() {
  console.log('--- Cleaning database.json & removing legacy mock junk ---');

  if (!fs.existsSync(DB_FILE)) {
    console.error('File database.json not found!');
    return;
  }

  const raw = fs.readFileSync(DB_FILE, 'utf8');
  const db = JSON.parse(raw);

  // 1. Bersihkan Users (Hapus akun testing sampah seperti Igidabado)
  db.users = (db.users || []).filter(u => u.email !== 'a@a.com' && u.nama !== 'Igidabado');
  
  // Pastikan user Sarah Jenkins (Diaspora) aktif dan memiliki paket 3 (Ultimate Pro 100)
  const sarah = db.users.find(u => u.id === 3 || u.email === 'sarah@gmail.com');
  if (sarah) {
    sarah.status = 'active';
    sarah.paket_id = 3;
    sarah.mata_uang = 'USD';
    sarah.zona_waktu = 'London';
    sarah.negara = 'United States';
    sarah.alamat = 'Rumah Keluarga: Jl. Gejayan No. 45, Yogyakarta';
  }

  // Pastikan user Budi Santoso aktif dan memiliki paket 2 (Turbo Home 50)
  const budi = db.users.find(u => u.id === 2 || u.email === 'budi@gmail.com');
  if (budi) {
    budi.status = 'active';
    budi.paket_id = 2;
    budi.mata_uang = 'IDR';
    budi.zona_waktu = 'WITA';
  }

  // 2. Bersihkan Invoices
  // Standarisasi kurs terkunci USD menjadi 16.300 (nilai pasar realistis)
  db.invoices = [
    {
      id: 1,
      user_id: 3,
      periode: 'November 2026',
      nominal_idr: 450000,
      mata_uang: 'USD',
      kurs_terkunci: 16300.0,
      jatuh_tempo: '2026-11-25T23:59:59+00:00',
      status: 'belum',
      diskon_idr: 0,
      voucher_code: null,
      created_at: '2026-11-01T08:00:00+00:00'
    },
    {
      id: 2,
      user_id: 2,
      periode: 'November 2026',
      nominal_idr: 275000,
      mata_uang: 'IDR',
      kurs_terkunci: 1.0,
      jatuh_tempo: '2026-11-25T23:59:59+00:00',
      status: 'belum',
      diskon_idr: 0,
      voucher_code: null,
      created_at: '2026-11-01T08:00:00+00:00'
    },
    {
      id: 3,
      user_id: 3,
      periode: 'Oktober 2026',
      nominal_idr: 450000,
      mata_uang: 'USD',
      kurs_terkunci: 16300.0,
      jatuh_tempo: '2026-10-25T23:59:59+00:00',
      status: 'lunas',
      diskon_idr: 0,
      voucher_code: null,
      created_at: '2026-10-01T08:00:00+00:00'
    },
    {
      id: 4,
      user_id: 2,
      periode: 'Oktober 2026',
      nominal_idr: 275000,
      mata_uang: 'IDR',
      kurs_terkunci: 1.0,
      jatuh_tempo: '2026-10-25T23:59:59+00:00',
      status: 'lunas',
      diskon_idr: 0,
      voucher_code: null,
      created_at: '2026-10-01T08:00:00+00:00'
    }
  ];

  // 3. Bersihkan Payments (Hanya simpan pembayaran resmi untuk invoice lunas)
  db.payments = [
    {
      id: 1,
      invoice_id: 3,
      user_id: 3,
      bukti_path: 'https://ysokrzhqtlpdwypauvjk.supabase.co/storage/v1/object/public/profile-photos/receipts/1792854787772-245249994.jpg',
      nominal_idr: 450000,
      status: 'diverifikasi',
      verified_at: '2026-10-20T15:13:37+00:00',
      created_at: '2026-10-20T15:10:00+00:00'
    },
    {
      id: 2,
      invoice_id: 4,
      user_id: 2,
      bukti_path: 'https://ysokrzhqtlpdwypauvjk.supabase.co/storage/v1/object/public/profile-photos/receipts/1793119140954-892797677.png',
      nominal_idr: 275000,
      status: 'diverifikasi',
      verified_at: '2026-10-20T16:39:21+00:00',
      created_at: '2026-10-20T16:35:00+00:00'
    }
  ];

  // 4. Rekalkulasi Blockchain Ledger Blocks (Integritas Kriptografi SHA-256)
  const genesisHash = calculateBlockHash(
    0,
    '2026-10-01T08:00:00.000Z',
    0,
    0,
    '0000000000000000000000000000000000000000000000000000000000000000'
  );

  const block1Hash = calculateBlockHash(
    1,
    '2026-10-20T15:13:37+00:00',
    1,
    450000,
    genesisHash
  );

  const block2Hash = calculateBlockHash(
    2,
    '2026-10-20T16:39:21+00:00',
    2,
    275000,
    block1Hash
  );

  db.ledger_blocks = [
    {
      idx: 0,
      waktu: '2026-10-01T08:00:00.000Z',
      payment_id: 0,
      nominal_idr: 0,
      prev_hash: '0000000000000000000000000000000000000000000000000000000000000000',
      hash: genesisHash,
      created_at: '2026-10-01T08:00:00.000Z'
    },
    {
      idx: 1,
      waktu: '2026-10-20T15:13:37+00:00',
      payment_id: 1,
      nominal_idr: 450000,
      prev_hash: genesisHash,
      hash: block1Hash,
      created_at: '2026-10-20T15:13:38+00:00'
    },
    {
      idx: 2,
      waktu: '2026-10-20T16:39:21+00:00',
      payment_id: 2,
      nominal_idr: 275000,
      prev_hash: block1Hash,
      hash: block2Hash,
      created_at: '2026-10-20T16:39:22+00:00'
    }
  ];

  // 5. Bersihkan Tasks (Hapus catatan sampah seperti "[Internet Lambat] p")
  db.tasks = [
    {
      id: 1,
      teknisi_id: 4,
      pelanggan_id: 2,
      jenis: 'perbaikan',
      status: 'dikerjakan',
      catatan: 'Pengecekan redaman kabel optik dan ganti drop core port 2.',
      created_at: '2026-11-01T09:00:00+00:00'
    },
    {
      id: 2,
      teknisi_id: 4,
      pelanggan_id: 5,
      jenis: 'instalasi',
      status: 'dikerjakan',
      catatan: 'Tarik kabel FO dari ODP-SLM-08 ke rumah pelanggan baru.',
      created_at: '2026-11-02T10:00:00+00:00'
    },
    {
      id: 3,
      teknisi_id: 4,
      pelanggan_id: 3,
      jenis: 'instalasi',
      status: 'selesai',
      catatan: 'Pergantian perangkat ONT WiFi 6 gigabit untuk pelanggan Sarah Jenkins (Diaspora).',
      created_at: '2026-10-20T14:00:00+00:00'
    }
  ];

  // 6. Bersihkan Package Requests (Hapus request sampah user 8)
  db.package_requests = [
    {
      id: 1,
      user_id: 3,
      user_nama: 'Sarah Jenkins (Diaspora)',
      user_email: 'sarah@gmail.com',
      user_alamat: 'Rumah Keluarga: Jl. Gejayan No. 45, Yogyakarta',
      user_no_hp: '+14155552671',
      paket_lama_id: 2,
      paket_lama_nama: 'Paket Turbo Home 50',
      paket_lama_kecepatan: 50,
      paket_lama_harga: 275000,
      paket_baru_id: 3,
      paket_baru_nama: 'Paket Ultimate Pro 100',
      paket_baru_kecepatan: 100,
      paket_baru_harga: 450000,
      selisih_harga: 175000,
      tipe: 'Upgrade Kecepatan',
      alasan: 'Membutuhkan bandwidth lebih tinggi untuk streaming 4K dan smart home.',
      status: 'approved',
      admin_catatan: 'Disetujui. Perangkat & konfigurasi siap disesuaikan.',
      created_at: '2026-10-24T15:10:28+00:00',
      updated_at: '2026-10-24T15:10:56+00:00'
    }
  ];

  // Tulis kembali file database.json
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
  console.log('✓ database.json cleaned successfully.');

  // Jika Supabase aktif, sinkronkan perubahan pembersihan data ke Supabase cloud juga
  if (isSupabaseConfigured()) {
    console.log('--- Syncing sanitized data to Supabase cloud ---');
    try {
      const supabase = getSupabaseClient();
      if (supabase) {
        // Hapus dummy user Igidabado jika ada di cloud
        await supabase.from('users').delete().eq('email', 'a@a.com');
        await supabase.from('package_requests').delete().eq('user_email', 'a@a.com');
      }
      await supabaseDb.pushAll(db, { verbose: true });
      console.log('✓ Supabase cloud database synchronized with clean state.');
    } catch (err) {
      console.warn('⚠️ Supabase sync notice:', err.message);
    }
  }

  console.log('--- All cleanup completed! ---');
}

cleanDatabase().catch(err => {
  console.error('Error during cleanup:', err);
});
