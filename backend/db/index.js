const fs = require('fs');
const bcrypt = require('bcryptjs');
const { DB_FILE } = require('../config');
const { calculateBlockHash } = require('../utils/hash');

function getInitialData() {
  const salt = bcrypt.genSaltSync(10);
  const defaultHash = bcrypt.hashSync('123', salt);

  const initialLedger = [
    {
      idx: 0,
      waktu: '2026-10-01T08:00:00.000Z',
      payment_id: 0,
      nominal_idr: 0,
      prev_hash: '0000000000000000000000000000000000000000000000000000000000000000',
      hash: calculateBlockHash(0, '2026-10-01T08:00:00.000Z', 0, 0, '0000000000000000000000000000000000000000000000000000000000000000')
    }
  ];

  return {
    users: [
      {
        id: 1,
        nama: 'Administrator Sima.net',
        email: 'admin@sima.net',
        no_hp: '081234567890',
        password_hash: defaultHash,
        role: 'admin',
        negara: 'Indonesia',
        mata_uang: 'IDR',
        zona_waktu: 'WIB',
        alamat: 'Kantor Pusat Sima.net, Jl. Telekomunikasi No. 1, Yogyakarta',
        lat: -7.7956,
        lng: 110.3695,
        foto: '',
        status: 'active',
        paket_id: null
      },
      {
        id: 2,
        nama: 'Budi Santoso',
        email: 'budi@gmail.com',
        no_hp: '085678912345',
        password_hash: defaultHash,
        role: 'pelanggan',
        negara: 'Indonesia',
        mata_uang: 'IDR',
        zona_waktu: 'WIB',
        alamat: 'Jl. Kaliurang KM 5 No. 12, Sleman',
        lat: -7.7612,
        lng: 110.3802,
        foto: '',
        status: 'active',
        paket_id: 2
      },
      {
        id: 3,
        nama: 'Sarah Jenkins (Diaspora)',
        email: 'sarah@gmail.com',
        no_hp: '+14155552671',
        password_hash: defaultHash,
        role: 'pelanggan',
        negara: 'United States',
        mata_uang: 'USD',
        zona_waktu: 'London',
        alamat: 'Rumah Keluarga: Jl. Gejayan No. 45, Yogyakarta',
        lat: -7.7735,
        lng: 110.3921,
        foto: '',
        status: 'active',
        paket_id: 3
      },
      {
        id: 4,
        nama: 'Rahmat Hidayat (Teknisi)',
        email: 'teknisi@sima.net',
        no_hp: '081987654321',
        password_hash: defaultHash,
        role: 'teknisi',
        negara: 'Indonesia',
        mata_uang: 'IDR',
        zona_waktu: 'WIB',
        alamat: 'Basecamp Teknisi Sima, Jl. Palagan, Sleman',
        lat: -7.7550,
        lng: 110.3750,
        foto: '',
        status: 'active',
        paket_id: null
      },
      {
        id: 5,
        nama: 'Ahmad Faisal (Pending)',
        email: 'ahmad@gmail.com',
        no_hp: '082233445566',
        password_hash: defaultHash,
        role: 'pelanggan',
        negara: 'Indonesia',
        mata_uang: 'IDR',
        zona_waktu: 'WITA',
        alamat: 'Perumahan Graha Asri Blok C-3, Sleman',
        lat: -7.7420,
        lng: 110.3680,
        foto: '',
        status: 'pending',
        paket_id: 1
      }
    ],
    packages: [
      {
        id: 1,
        nama: 'Paket Hemat Fiber 20',
        kecepatan_mbps: 20,
        harga_idr: 175000,
        deskripsi: 'Akses internet stabil unlimited untuk kebutuhan browsing dan media sosial keluarga kecil.'
      },
      {
        id: 2,
        nama: 'Paket Turbo Home 50',
        kecepatan_mbps: 50,
        harga_idr: 275000,
        deskripsi: 'Kecepatan tinggi untuk streaming 4K tanpa buffering, Zoom meeting, dan online gaming.'
      },
      {
        id: 3,
        nama: 'Paket Ultimate Pro 100',
        kecepatan_mbps: 100,
        harga_idr: 450000,
        deskripsi: 'Koneksi ultra-cepat fiber optic simetris untuk profesional, content creator, dan smart home.'
      },
      {
        id: 4,
        nama: 'Paket Fast Fiber 30',
        kecepatan_mbps: 30,
        harga_idr: 215000,
        deskripsi: 'Internet fiber optic handal untuk WFH, download cepat, dan streaming HD bebas lag.'
      },
      {
        id: 5,
        nama: 'Paket Turbo Home 75',
        kecepatan_mbps: 75,
        harga_idr: 340000,
        deskripsi: 'Keluarga besar aktif & smart TV multi-room, download file besar dalam hitungan detik.'
      },
      {
        id: 6,
        nama: 'Paket Gamer Sakti 100',
        kecepatan_mbps: 100,
        harga_idr: 399000,
        deskripsi: 'Jalur khusus gaming prioritas rendah latensi (<5ms), anti spike & zero packet loss.'
      },
      {
        id: 7,
        nama: 'Paket Gamer Pro 150',
        kecepatan_mbps: 150,
        harga_idr: 520000,
        deskripsi: 'Bandwidth simetris 1:1, live streaming YouTube/Twitch kualitas 1080p 60fps tanpa jeda.'
      },
      {
        id: 8,
        nama: 'Paket Promo Flash 60',
        kecepatan_mbps: 60,
        harga_idr: 239000,
        deskripsi: 'Promo spesial kuota unlimited kecepatan ekstra fiber optic hemat bulanan.'
      },
      {
        id: 9,
        nama: 'Paket Promo Pelajar Hemat',
        kecepatan_mbps: 25,
        harga_idr: 150000,
        deskripsi: 'Paket ramah kantong untuk pelajar & mahasiswa, riset kuliah & Google Classroom.'
      }
    ],
    invoices: [
      {
        id: 1,
        user_id: 2,
        periode: 'Oktober 2026',
        nominal_idr: 275000,
        mata_uang: 'IDR',
        kurs_terkunci: 1.0,
        jatuh_tempo: '2026-10-25T23:59:59.000Z',
        status: 'belum'
      },
      {
        id: 2,
        user_id: 3,
        periode: 'Oktober 2026',
        nominal_idr: 450000,
        mata_uang: 'USD',
        kurs_terkunci: 15500.0,
        jatuh_tempo: '2026-10-25T23:59:59.000Z',
        status: 'lunas'
      },
      {
        id: 3,
        user_id: 2,
        periode: 'September 2026',
        nominal_idr: 275000,
        mata_uang: 'IDR',
        kurs_terkunci: 1.0,
        jatuh_tempo: '2026-09-25T23:59:59.000Z',
        status: 'lunas'
      }
    ],
    payments: [
      {
        id: 1,
        invoice_id: 2,
        user_id: 3,
        bukti_path: '',
        nominal_idr: 450000,
        status: 'diverifikasi',
        verified_at: '2026-10-10T14:20:00.000Z'
      },
      {
        id: 2,
        invoice_id: 3,
        user_id: 2,
        bukti_path: '',
        nominal_idr: 275000,
        status: 'diverifikasi',
        verified_at: '2026-09-20T10:15:00.000Z'
      }
    ],
    ledger_blocks: initialLedger,
    tasks: [
      {
        id: 1,
        teknisi_id: 4,
        pelanggan_id: 2,
        jenis: 'perbaikan',
        status: 'baru',
        catatan: 'Pengecekan redaman kabel optik dan ganti drop core port 2.'
      },
      {
        id: 2,
        teknisi_id: 4,
        pelanggan_id: 5,
        jenis: 'instalasi',
        status: 'dikerjakan',
        catatan: 'Tarik kabel FO dari ODP-SLM-08 ke rumah pelanggan baru.'
      }
    ],
    upstream_bills: [
      {
        id: 1,
        periode: 'September 2026',
        nominal_idr: 4500000,
        provider_name: 'Indibizz Dedicated 500M',
        status: 'lunas'
      },
      {
        id: 2,
        periode: 'Oktober 2026',
        nominal_idr: 4500000,
        provider_name: 'Indibizz Dedicated 500M',
        status: 'belum'
      }
    ],
    feedback: [
      {
        id: 1,
        user_id: 2,
        user_nama: 'Budi Santoso',
        saran: 'Mohon tambahkan opsi pembayaran otomatis via QRIS di rilis berikutnya.',
        kesan: 'Pelayanan Sima.net luar biasa cepat, teknisi ramah dan internet sangat stabil!',
        created_at: '2026-10-12T11:00:00.000Z'
      }
    ],
    devices: [],
    package_requests: []
  };
}

let inMemoryData = null;

async function initDB() {
  const supabaseDb = require('../services/supabase_db.service');
  const { isSupabaseConfigured } = require('../config/supabase');

  if (isSupabaseConfigured()) {
    console.log('[Database] Supabase is configured. Initializing sync from Supabase...');
    const remoteData = await supabaseDb.pullAll();
    if (remoteData && remoteData.users && remoteData.users.length > 0) {
      // Pertahankan package_requests lokal jika di Supabase belum ada tabelnya
      let currentLocal = {};
      try {
        if (fs.existsSync(DB_FILE)) {
          currentLocal = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
        }
      } catch (_) {}

      if ((!remoteData.package_requests || remoteData.package_requests.length === 0) && currentLocal.package_requests) {
        remoteData.package_requests = currentLocal.package_requests;
      }

      inMemoryData = remoteData;
      fs.writeFileSync(DB_FILE, JSON.stringify(remoteData, null, 2), 'utf8');
      console.log('[Database] Local cache successfully synced with Supabase PostgreSQL.');
      return inMemoryData;
    } else {
      console.log('[Database] Remote tables empty or initial startup. Keeping current data.');
    }
  } else {
    console.log('[Database] Running in local mode (SUPABASE_URL / SUPABASE_KEY not yet set).');
  }

  return loadDB();
}

function loadDB() {
  if (inMemoryData) {
    if (!inMemoryData.package_requests) inMemoryData.package_requests = [];
    return inMemoryData;
  }

  if (!fs.existsSync(DB_FILE)) {
    const data = getInitialData();
    saveDB(data);
    inMemoryData = data;
    return data;
  }
  try {
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    inMemoryData = JSON.parse(raw);
    if (!inMemoryData.package_requests) inMemoryData.package_requests = [];
    return inMemoryData;
  } catch (err) {
    const data = getInitialData();
    saveDB(data);
    inMemoryData = data;
    return data;
  }
}

function saveDB(data) {
  inMemoryData = data;
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
  } catch (err) {
    console.error('[Database] Failed to write local DB_FILE:', err.message);
  }

  // If Supabase is configured, trigger asynchronous background sync
  const { isSupabaseConfigured } = require('../config/supabase');
  if (isSupabaseConfigured()) {
    const supabaseDb = require('../services/supabase_db.service');
    // Non-blocking sync to keep responses fast
    setImmediate(async () => {
      try {
        await supabaseDb.pushAll(data);
      } catch (err) {
        console.warn('[Database] Supabase background sync note:', err.message);
      }
    });
  }
}

module.exports = {
  loadDB,
  saveDB,
  initDB,
  getInitialData
};

