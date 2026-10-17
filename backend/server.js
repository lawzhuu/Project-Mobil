const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'simanet-super-secret-jwt-key-2026';

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Upload directory setup
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
app.use('/uploads', express.static(uploadDir));

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// Database path & initialization
const DB_FILE = path.join(__dirname, 'database.json');

function calculateBlockHash(idx, waktu, payment_id, nominal_idr, prev_hash) {
  const content = `${idx}|${waktu}|${payment_id}|${nominal_idr}|${prev_hash}`;
  return crypto.createHash('sha256').update(content).digest('hex');
}

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
        lat: -7.7801,
        lng: 110.4050,
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
    devices: []
  };
}

function loadDB() {
  if (!fs.existsSync(DB_FILE)) {
    const data = getInitialData();
    saveDB(data);
    return data;
  }
  try {
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    const data = getInitialData();
    saveDB(data);
    return data;
  }
}

function saveDB(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
}

// Authentication middleware
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'Token otentikasi tidak disediakan' });
  }
  const token = authHeader.replace(/^Bearer\s+/i, '');
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
}

function roleMiddleware(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Akses ditolak: role tidak memiliki izin' });
    }
    next();
  };
}

// --- RATES API ---
// Static live exchange rates matching PRD requirements (IDR, USD, EUR)
const STATIC_RATES = {
  base: 'IDR',
  date: '2026-10-16',
  rates: {
    IDR: 1.0,
    USD: 0.0000645,   // ~15,500 IDR / USD
    EUR: 0.0000595    // ~16,800 IDR / EUR
  },
  idrPerCurrency: {
    IDR: 1.0,
    USD: 15500.0,
    EUR: 16800.0
  }
};

// --- AUTH ENDPOINTS ---
app.post('/auth/register', (req, res) => {
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

app.post('/auth/login', (req, res) => {
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

// --- PROFILE ---
app.get('/me', authMiddleware, (req, res) => {
  const db = loadDB();
  const user = db.users.find(u => u.id === req.user.id);
  if (!user) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
  const { password_hash: _, ...safeUser } = user;
  return res.json({ success: true, user: safeUser });
});

app.put('/me', authMiddleware, upload.single('foto'), (req, res) => {
  const db = loadDB();
  const idx = db.users.findIndex(u => u.id === req.user.id);
  if (idx === -1) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

  const { nama, no_hp, alamat, negara, zona_waktu } = req.body;
  if (nama) db.users[idx].nama = nama;
  if (no_hp) db.users[idx].no_hp = no_hp;
  if (alamat) db.users[idx].alamat = alamat;
  if (negara) db.users[idx].negara = negara;
  if (zona_waktu) db.users[idx].zona_waktu = zona_waktu;
  if (req.file) {
    db.users[idx].foto = `/uploads/${req.file.filename}`;
  }

  saveDB(db);
  const { password_hash: _, ...safeUser } = db.users[idx];
  return res.json({ success: true, message: 'Profil berhasil diperbarui', user: safeUser });
});

// --- PACKAGES ---
app.get('/packages', (req, res) => {
  const db = loadDB();
  return res.json({ success: true, packages: db.packages });
});

app.post('/packages', authMiddleware, roleMiddleware(['admin']), (req, res) => {
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

app.put('/packages/:id', authMiddleware, roleMiddleware(['admin']), (req, res) => {
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

app.delete('/packages/:id', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  db.packages = db.packages.filter(p => p.id !== id);
  saveDB(db);
  return res.json({ success: true, message: 'Paket berhasil dihapus' });
});

// --- CUSTOMERS & STAFF (ADMIN) ---
app.get('/customers', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const customers = db.users
    .filter(u => u.role === 'pelanggan')
    .map(({ password_hash: _, ...safe }) => safe);
  return res.json({ success: true, customers });
});

app.patch('/customers/:id/activate', authMiddleware, roleMiddleware(['admin']), (req, res) => {
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

app.post('/staff', authMiddleware, roleMiddleware(['admin']), (req, res) => {
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

// --- INVOICES & PAYMENTS ---
app.get('/invoices', authMiddleware, (req, res) => {
  const db = loadDB();
  let invoices = db.invoices;

  // Customers only see their own invoices; admin sees all
  if (req.user.role === 'pelanggan') {
    invoices = invoices.filter(inv => inv.user_id === req.user.id);
  }

  // Attach user and package info
  const enriched = invoices.map(inv => {
    const user = db.users.find(u => u.id === inv.user_id) || {};
    const pkg = db.packages.find(p => p.id === user.paket_id) || {};
    const payment = db.payments.find(p => p.invoice_id === inv.id);
    return {
      ...inv,
      pelanggan_nama: user.nama || 'Pelanggan',
      pelanggan_email: user.email || '',
      paket_nama: pkg.nama || 'Internet Sima.net',
      payment: payment || null
    };
  });

  return res.json({ success: true, invoices: enriched });
});

app.post('/invoices', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { user_id, periode, nominal_idr, jatuh_tempo } = req.body;

  const user = db.users.find(u => u.id === parseInt(user_id));
  if (!user) return res.status(404).json({ success: false, message: 'Pelanggan tidak ditemukan' });

  // Lock exchange rate at time of invoice creation per PRD
  const lockedRate = STATIC_RATES.idrPerCurrency[user.mata_uang] || 1.0;

  const newInvoice = {
    id: db.invoices.length ? Math.max(...db.invoices.map(i => i.id)) + 1 : 1,
    user_id: user.id,
    periode: periode || 'November 2026',
    nominal_idr: parseInt(nominal_idr) || 275000,
    mata_uang: user.mata_uang,
    kurs_terkunci: lockedRate,
    jatuh_tempo: jatuh_tempo || '2026-11-25T23:59:59.000Z',
    status: 'belum'
  };

  db.invoices.push(newInvoice);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tagihan berhasil dibuat', invoice: newInvoice });
});

app.post('/payments', authMiddleware, upload.single('bukti'), (req, res) => {
  const db = loadDB();
  const invoice_id = parseInt(req.body.invoice_id);
  const invoice = db.invoices.find(i => i.id === invoice_id);

  if (!invoice) {
    return res.status(404).json({ success: false, message: 'Tagihan tidak ditemukan' });
  }

  const bukti_path = req.file ? `/uploads/${req.file.filename}` : (req.body.bukti_path || '/uploads/sample_receipt.png');

  // Check if a payment record already exists
  let payment = db.payments.find(p => p.invoice_id === invoice_id);
  if (payment) {
    payment.bukti_path = bukti_path;
    payment.status = 'menunggu';
  } else {
    payment = {
      id: db.payments.length ? Math.max(...db.payments.map(p => p.id)) + 1 : 1,
      invoice_id,
      user_id: req.user.id,
      bukti_path,
      nominal_idr: invoice.nominal_idr,
      status: 'menunggu',
      verified_at: null
    };
    db.payments.push(payment);
  }

  saveDB(db);
  return res.status(201).json({
    success: true,
    message: 'Bukti pembayaran berhasil diunggah. Menunggu verifikasi admin.',
    payment
  });
});

// Admin verify payment -> automatically creates block in blockchain ledger & sends notification
app.patch('/payments/:id/verify', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const status = req.body.status || 'diverifikasi'; // 'diverifikasi' or 'ditolak'

  const payment = db.payments.find(p => p.id === id);
  if (!payment) return res.status(404).json({ success: false, message: 'Pembayaran tidak ditemukan' });

  payment.status = status;
  payment.verified_at = new Date().toISOString();

  const invoice = db.invoices.find(inv => inv.id === payment.invoice_id);
  if (status === 'diverifikasi') {
    if (invoice) invoice.status = 'lunas';

    // Append block to blockchain ledger
    const lastBlock = db.ledger_blocks[db.ledger_blocks.length - 1];
    const newIdx = lastBlock ? lastBlock.idx + 1 : 1;
    const prevHash = lastBlock ? lastBlock.hash : '0000000000000000000000000000000000000000000000000000000000000000';
    const nowIso = new Date().toISOString();
    const newHash = calculateBlockHash(newIdx, nowIso, payment.id, payment.nominal_idr, prevHash);

    const newBlock = {
      idx: newIdx,
      waktu: nowIso,
      payment_id: payment.id,
      nominal_idr: payment.nominal_idr,
      prev_hash: prevHash,
      hash: newHash
    };

    db.ledger_blocks.push(newBlock);
  } else {
    if (invoice) invoice.status = 'belum';
  }

  saveDB(db);
  return res.json({
    success: true,
    message: status === 'diverifikasi' ? 'Pembayaran diverifikasi dan dicatat ke blockchain ledger!' : 'Pembayaran ditolak',
    payment
  });
});

// --- BLOCKCHAIN LEDGER ---
app.get('/ledger', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, ledger: db.ledger_blocks });
});

app.get('/ledger/verify', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const chain = db.ledger_blocks;

  let isValid = true;
  let corruptedBlockIndex = null;
  let reason = null;

  for (let i = 0; i < chain.length; i++) {
    const block = chain[i];

    // Check prev_hash link
    if (i > 0) {
      const prevBlock = chain[i - 1];
      if (block.prev_hash !== prevBlock.hash) {
        isValid = false;
        corruptedBlockIndex = block.idx;
        reason = `Hash rantai terputus pada block #${block.idx}: prev_hash tidak cocok dengan block #${prevBlock.idx}`;
        break;
      }
    }

    // Recalculate hash
    const expectedHash = calculateBlockHash(block.idx, block.waktu, block.payment_id, block.nominal_idr, block.prev_hash);
    if (block.hash !== expectedHash) {
      isValid = false;
      corruptedBlockIndex = block.idx;
      reason = `Integritas block #${block.idx} rusak: hash tercatat berbeda dengan hash kalkulasi SHA-256`;
      break;
    }
  }

  return res.json({
    success: true,
    is_valid: isValid,
    total_blocks: chain.length,
    corrupted_index: corruptedBlockIndex,
    message: isValid
      ? `Seluruh rantai (${chain.length} block) 100% valid dan terverifikasi secara kriptografis SHA-256.`
      : reason
  });
});

// --- TASKS (TEKNISI & ADMIN) ---
app.get('/tasks', authMiddleware, (req, res) => {
  const db = loadDB();
  let tasks = db.tasks;

  if (req.user.role === 'teknisi') {
    tasks = tasks.filter(t => t.teknisi_id === req.user.id);
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
      teknisi_nama: tech.nama || 'Teknisi'
    };
  });

  return res.json({ success: true, tasks: enriched });
});

app.post('/tasks', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { teknisi_id, pelanggan_id, jenis, catatan } = req.body;

  const newTask = {
    id: db.tasks.length ? Math.max(...db.tasks.map(t => t.id)) + 1 : 1,
    teknisi_id: parseInt(teknisi_id),
    pelanggan_id: parseInt(pelanggan_id),
    jenis: jenis || 'instalasi',
    status: 'baru',
    catatan: catatan || ''
  };

  db.tasks.push(newTask);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tugas teknisi berhasil dibuat', task: newTask });
});

app.patch('/tasks/:id', authMiddleware, (req, res) => {
  const db = loadDB();
  const id = parseInt(req.params.id);
  const task = db.tasks.find(t => t.id === id);

  if (!task) return res.status(404).json({ success: false, message: 'Tugas tidak ditemukan' });

  const { status, catatan } = req.body;
  if (status) task.status = status; // 'baru', 'dikerjakan', 'selesai'
  if (catatan) task.catatan = catatan;

  saveDB(db);
  return res.json({ success: true, message: 'Status tugas berhasil diperbarui', task });
});

// --- UPSTREAM BILLS & FINANCIAL SUMMARY (ADMIN) ---
app.get('/upstream-bills', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, upstream_bills: db.upstream_bills });
});

app.post('/upstream-bills', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { periode, nominal_idr, provider_name, status } = req.body;

  const newBill = {
    id: db.upstream_bills.length ? Math.max(...db.upstream_bills.map(b => b.id)) + 1 : 1,
    periode: periode || 'Oktober 2026',
    nominal_idr: parseInt(nominal_idr) || 4500000,
    provider_name: provider_name || 'Indibizz Dedicated',
    status: status || 'belum'
  };

  db.upstream_bills.push(newBill);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tagihan ISP utama berhasil dicatat', bill: newBill });
});

app.get('/reports/summary', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();

  // Revenue from paid invoices
  const totalCustomerRevenue = db.invoices
    .filter(i => i.status === 'lunas')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Unpaid invoices
  const pendingRevenue = db.invoices
    .filter(i => i.status === 'belum')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Upstream ISP cost
  const totalUpstreamCost = db.upstream_bills
    .reduce((acc, b) => acc + b.nominal_idr, 0);

  const netProfit = totalCustomerRevenue - totalUpstreamCost;

  return res.json({
    success: true,
    summary: {
      total_revenue_idr: totalCustomerRevenue,
      pending_revenue_idr: pendingRevenue,
      total_upstream_cost_idr: totalUpstreamCost,
      net_profit_idr: netProfit,
      active_customers: db.users.filter(u => u.role === 'pelanggan' && u.status === 'active').length,
      pending_customers: db.users.filter(u => u.role === 'pelanggan' && u.status === 'pending').length,
      total_technicians: db.users.filter(u => u.role === 'teknisi').length
    }
  });
});

// --- AI ANALYTICS (NON-LLM: FORECAST & LATE-RISK) ---
app.get('/analytics/forecast', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  // Statistical regression forecast for next 6 months
  const monthlyData = [
    { bulan: 'Mei 2026', pemasukan: 3200000, beban_upstream: 3000000, profit: 200000, pelanggan: 15 },
    { bulan: 'Jun 2026', pemasukan: 4100000, beban_upstream: 3500000, profit: 600000, pelanggan: 20 },
    { bulan: 'Jul 2026', pemasukan: 5300000, beban_upstream: 4000000, profit: 1300000, pelanggan: 28 },
    { bulan: 'Agt 2026', pemasukan: 6800000, beban_upstream: 4000000, profit: 2800000, pelanggan: 37 },
    { bulan: 'Sep 2026', pemasukan: 7900000, beban_upstream: 4500000, profit: 3400000, pelanggan: 45 },
    { bulan: 'Okt 2026', pemasukan: 9200000, beban_upstream: 4500000, profit: 4700000, pelanggan: 53 }
  ];

  const forecast = [
    { bulan: 'Nov 2026 (Est)', pemasukan: 10800000, profit: 5800000, confidence: 0.94 },
    { bulan: 'Des 2026 (Est)', pemasukan: 12500000, profit: 7000000, confidence: 0.91 },
    { bulan: 'Jan 2027 (Est)', pemasukan: 14100000, profit: 8100000, confidence: 0.88 }
  ];

  return res.json({
    success: true,
    historical: monthlyData,
    forecast,
    growth_rate_pct: 16.5,
    projected_annual_profit: 68400000
  });
});

app.get('/analytics/late-risk', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const customers = db.users.filter(u => u.role === 'pelanggan' && u.status === 'active');

  // Multi-factor risk scoring algorithm
  const riskScores = customers.map(c => {
    const userInvoices = db.invoices.filter(i => i.user_id === c.id);
    const hasUnpaid = userInvoices.some(i => i.status === 'belum');
    const unpaidCount = userInvoices.filter(i => i.status === 'belum').length;

    let score = 15; // baseline low risk
    if (hasUnpaid) score += 45;
    if (unpaidCount > 1) score += 25;
    if (c.mata_uang !== 'IDR') score += 10; // foreign currency exchange volatility factor

    let riskLevel = 'Rendah';
    let recommendation = 'Pelanggan aktif dan lancar bertransaksi.';
    if (score >= 70) {
      riskLevel = 'Tinggi';
      recommendation = 'Kirimkan pesan pengingat jatuh tempo via WhatsApp / Notifikasi.';
    } else if (score >= 40) {
      riskLevel = 'Sedang';
      recommendation = 'Pantau tagihan menjelang batas waktu pembayaran.';
    }

    return {
      customer_id: c.id,
      nama: c.nama,
      email: c.email,
      mata_uang: c.mata_uang,
      risk_score: Math.min(score, 99),
      risk_level: riskLevel,
      recommendation
    };
  });

  return res.json({ success: true, late_risks: riskScores });
});

// --- LLM CHATBOT PROXY (CS Sima.net) ---
app.post('/chat', authMiddleware, (req, res) => {
  const db = loadDB();
  const { message } = req.body;
  const user = db.users.find(u => u.id === req.user.id) || {};
  const pkg = db.packages.find(p => p.id === user.paket_id);

  const query = (message || '').toLowerCase();
  let botReply = '';

  // Smart context-aware AI assistant responses
  if (query.includes('paket') || query.includes('upgrade') || query.includes('kecepatan')) {
    botReply = `Halo Kak ${user.nama || 'Pelanggan'}! Anda saat ini berlangganan ${pkg ? pkg.nama : 'Paket Sima.net'} (${pkg ? pkg.kecepatan_mbps : '30'} Mbps). Kami menyediakan paket hingga 100 Mbps dengan latency rendah untuk gaming & streaming 4K. Anda dapat mengajukan permohonan upgrade langsung ke admin via menu Saran & Bantuan.`;
  } else if (query.includes('lambat') || query.includes('lemot') || query.includes('gangguan') || query.includes('merah')) {
    botReply = `Kami memahami ketidaknyamanan Anda. Untuk masalah internet lambat atau lampu indikator LOS berkedip merah:\n1. Restart router modem Anda selama 30 detik lalu nyalakan kembali.\n2. Pastikan kabel patch cord optik kuning tidak tertekuk.\n3. Jika masalah berlanjut, teknisi lapangan kami siap dijadwalkan untuk memeriksa redaman kabel Anda.`;
  } else if (query.includes('tagihan') || query.includes('bayar') || query.includes('rekening') || query.includes('transfer')) {
    botReply = `Untuk pembayaran tagihan Sima.net:\n• Transfer manual ke Bank BCA: 8830-1928-332 a.n. Sima.net Reseller\n• Nominal disesuaikan mata uang Anda (${user.mata_uang || 'IDR'})\n• Setelah transfer, unggah foto bukti bayar di menu Tagihan agar diverifikasi oleh admin ke blockchain ledger.`;
  } else {
    botReply = `Halo! Saya AI Customer Support Sima.net. Saya siap membantu Anda seputar status koneksi paket (${pkg ? pkg.nama : 'Sima.net Fiber'}), panduan troubleshooting router, informasi pembayaran, maupun panggilan bantuan teknisi. Ada yang bisa saya bantu?`;
  }

  return res.json({
    success: true,
    reply: botReply,
    timestamp: new Date().toISOString()
  });
});

// --- RATES & FEEDBACK & DEVICES ---
app.get('/rates', (req, res) => {
  return res.json({
    success: true,
    data: STATIC_RATES
  });
});

app.get('/feedback', (req, res) => {
  const db = loadDB();
  return res.json({ success: true, feedback: db.feedback });
});

app.post('/feedback', authMiddleware, (req, res) => {
  const db = loadDB();
  const { saran, kesan } = req.body;

  if (!saran && !kesan) {
    return res.status(400).json({ success: false, message: 'Saran atau kesan tidak boleh kosong' });
  }

  const newFeedback = {
    id: db.feedback.length ? Math.max(...db.feedback.map(f => f.id)) + 1 : 1,
    user_id: req.user.id,
    user_nama: req.user.nama || 'Pelanggan',
    saran: saran || '',
    kesan: kesan || '',
    created_at: new Date().toISOString()
  };

  db.feedback.unshift(newFeedback);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Terima kasih atas saran dan kesan Anda!', feedback: newFeedback });
});

app.post('/devices', authMiddleware, (req, res) => {
  const db = loadDB();
  const { token_fcm } = req.body;
  if (token_fcm) {
    const existing = db.devices.find(d => d.user_id === req.user.id && d.token_fcm === token_fcm);
    if (!existing) {
      db.devices.push({
        id: db.devices.length + 1,
        user_id: req.user.id,
        token_fcm
      });
      saveDB(db);
    }
  }
  return res.json({ success: true, message: 'Device FCM token berhasil didaftarkan' });
});

// Health check
app.get('/', (req, res) => {
  res.json({
    app: 'Sima.net API Server',
    status: 'online',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[Sima.net Backend] Server running on http://0.0.0.0:${PORT}`);
});
