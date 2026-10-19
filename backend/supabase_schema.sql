-- ==============================================================================
-- SIMA.NET ISP RESELLER & OPERATIONS - SUPABASE SQL SCHEMA MIGRATION
-- Jalankan skrip ini langsung di menu "SQL Editor" pada dashboard Supabase Anda.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL USERS (Admin, Pelanggan, Teknisi)
CREATE TABLE IF NOT EXISTS public.users (
  id SERIAL PRIMARY KEY,
  nama TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  no_hp TEXT DEFAULT '',
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'pelanggan' CHECK (role IN ('admin', 'pelanggan', 'teknisi')),
  negara TEXT DEFAULT 'Indonesia',
  mata_uang TEXT DEFAULT 'IDR' CHECK (mata_uang IN ('IDR', 'USD', 'EUR')),
  zona_waktu TEXT DEFAULT 'WIB' CHECK (zona_waktu IN ('WIB', 'WITA', 'WIT', 'London')),
  alamat TEXT DEFAULT '',
  lat DOUBLE PRECISION DEFAULT -7.7956,
  lng DOUBLE PRECISION DEFAULT 110.3695,
  foto TEXT DEFAULT '',
  status TEXT DEFAULT 'pending' CHECK (status IN ('active', 'pending', 'inactive')),
  paket_id INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABEL PACKAGES (Paket Layanan Internet Fiber)
CREATE TABLE IF NOT EXISTS public.packages (
  id SERIAL PRIMARY KEY,
  nama TEXT NOT NULL,
  kecepatan_mbps INTEGER NOT NULL,
  harga_idr BIGINT NOT NULL,
  deskripsi TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABEL INVOICES (Tagihan Bulanan Berbasis Kurs Terkunci)
CREATE TABLE IF NOT EXISTS public.invoices (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  periode TEXT NOT NULL,
  nominal_idr BIGINT NOT NULL,
  mata_uang TEXT DEFAULT 'IDR',
  kurs_terkunci DOUBLE PRECISION DEFAULT 1.0,
  jatuh_tempo TIMESTAMPTZ,
  status TEXT DEFAULT 'belum' CHECK (status IN ('belum', 'lunas', 'lewat_tempo')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABEL PAYMENTS (Bukti & Verifikasi Pembayaran Tagihan)
CREATE TABLE IF NOT EXISTS public.payments (
  id SERIAL PRIMARY KEY,
  invoice_id INTEGER NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  bukti_path TEXT DEFAULT '',
  nominal_idr BIGINT NOT NULL,
  status TEXT DEFAULT 'menunggu' CHECK (status IN ('menunggu', 'diverifikasi', 'ditolak')),
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABEL LEDGER BLOCKS (Buku Kas Terdistribusi Kriptografis SHA-256)
CREATE TABLE IF NOT EXISTS public.ledger_blocks (
  idx INTEGER PRIMARY KEY,
  waktu TIMESTAMPTZ NOT NULL,
  payment_id INTEGER,
  nominal_idr BIGINT NOT NULL,
  prev_hash TEXT NOT NULL,
  hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. TABEL TASKS (Penugasan Instalasi & Perbaikan Lapangan Teknisi)
CREATE TABLE IF NOT EXISTS public.tasks (
  id SERIAL PRIMARY KEY,
  teknisi_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
  pelanggan_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  jenis TEXT DEFAULT 'instalasi' CHECK (jenis IN ('instalasi', 'perbaikan', 'pemeliharaan')),
  status TEXT DEFAULT 'baru' CHECK (status IN ('baru', 'dikerjakan', 'selesai')),
  catatan TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABEL UPSTREAM BILLS (Beban Tagihan ISP Utama / Indibizz)
CREATE TABLE IF NOT EXISTS public.upstream_bills (
  id SERIAL PRIMARY KEY,
  periode TEXT NOT NULL,
  nominal_idr BIGINT NOT NULL,
  provider_name TEXT NOT NULL,
  status TEXT DEFAULT 'belum' CHECK (status IN ('belum', 'lunas')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. TABEL FEEDBACK (Saran & Kesan Layanan & Matakuliah Mobile)
CREATE TABLE IF NOT EXISTS public.feedback (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
  user_nama TEXT DEFAULT 'Pelanggan',
  saran TEXT DEFAULT '',
  kesan TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. TABEL DEVICES (FCM Push Notification Token)
CREATE TABLE IF NOT EXISTS public.devices (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_fcm TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. TABEL PACKAGE REQUESTS (Pengajuan Ubah / Upgrade / Downgrade Paket)
CREATE TABLE IF NOT EXISTS public.package_requests (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_nama TEXT NOT NULL,
  user_email TEXT NOT NULL,
  user_alamat TEXT DEFAULT '',
  user_no_hp TEXT DEFAULT '',
  paket_lama_id INTEGER,
  paket_lama_nama TEXT DEFAULT '',
  paket_lama_kecepatan INTEGER DEFAULT 0,
  paket_lama_harga BIGINT DEFAULT 0,
  paket_baru_id INTEGER NOT NULL,
  paket_baru_nama TEXT NOT NULL,
  paket_baru_kecepatan INTEGER NOT NULL,
  paket_baru_harga BIGINT NOT NULL,
  selisih_harga BIGINT DEFAULT 0,
  tipe TEXT DEFAULT 'Upgrade Kecepatan',
  alasan TEXT DEFAULT '',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_catatan TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 11. STORAGE BUCKET (Untuk Foto Profil Pengguna & Bukti Bayar)
-- ==============================================================================

-- Buat bucket penyimpanan 'profile-photos' jika belum ada
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-photos',
  'profile-photos',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE 
SET public = true, file_size_limit = 10485760;

-- Kebijakan Akses Storage: Izinkan publik membaca foto profil
DROP POLICY IF EXISTS "Public Read Profile Photos" ON storage.objects;
CREATE POLICY "Public Read Profile Photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-photos');

-- Kebijakan Akses Storage: Izinkan upload ke bucket profile-photos
DROP POLICY IF EXISTS "Allow Upload Profile Photos" ON storage.objects;
CREATE POLICY "Allow Upload Profile Photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'profile-photos');

-- Kebijakan Akses Storage: Izinkan update foto
DROP POLICY IF EXISTS "Allow Update Profile Photos" ON storage.objects;
CREATE POLICY "Allow Update Profile Photos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'profile-photos');

-- ==============================================================================
-- 12. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upstream_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.package_requests ENABLE ROW LEVEL SECURITY;

-- Berikan akses penuh untuk backend API (anon & service_role)
DROP POLICY IF EXISTS "Backend access users" ON public.users;
CREATE POLICY "Backend access users" ON public.users FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access packages" ON public.packages;
CREATE POLICY "Backend access packages" ON public.packages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access invoices" ON public.invoices;
CREATE POLICY "Backend access invoices" ON public.invoices FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access payments" ON public.payments;
CREATE POLICY "Backend access payments" ON public.payments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access ledger_blocks" ON public.ledger_blocks;
CREATE POLICY "Backend access ledger_blocks" ON public.ledger_blocks FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access tasks" ON public.tasks;
CREATE POLICY "Backend access tasks" ON public.tasks FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access upstream_bills" ON public.upstream_bills;
CREATE POLICY "Backend access upstream_bills" ON public.upstream_bills FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access feedback" ON public.feedback;
CREATE POLICY "Backend access feedback" ON public.feedback FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access devices" ON public.devices;
CREATE POLICY "Backend access devices" ON public.devices FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend access package_requests" ON public.package_requests;
CREATE POLICY "Backend access package_requests" ON public.package_requests FOR ALL USING (true) WITH CHECK (true);

-- ==============================================================================
-- 13. SEED DATA AWAL (Default Password: "123")
-- ==============================================================================

-- Password hash bcrypt untuk '123': $2a$10$wT0l0hX5x111tFvhM6y2aOPbFw08e8t8C154l0M0z8u8v8y8x8
-- Kita gunakan hash bcrypt terstandar yang kompatibel dengan server
INSERT INTO public.users (id, nama, email, no_hp, password_hash, role, negara, mata_uang, zona_waktu, alamat, lat, lng, foto, status, paket_id)
VALUES 
  (1, 'Administrator Sima.net', 'admin@sima.net', '081234567890', '$2a$10$JEiDspHii0IOovPCDHMJYeTZkhqfb0ztUfQd8.Fo2eUXDIqtZ5vqO', 'admin', 'Indonesia', 'IDR', 'WIB', 'Kantor Pusat Sima.net, Jl. Telekomunikasi No. 1, Yogyakarta', -7.7956, 110.3695, '', 'active', NULL),
  (2, 'Budi Santoso', 'budi@gmail.com', '085678912345', '$2a$10$JEiDspHii0IOovPCDHMJYeTZkhqfb0ztUfQd8.Fo2eUXDIqtZ5vqO', 'pelanggan', 'Indonesia', 'IDR', 'WIB', 'Jl. Kaliurang KM 5 No. 12, Sleman', -7.7612, 110.3802, '', 'active', 2),
  (3, 'Sarah Jenkins (Diaspora)', 'sarah@gmail.com', '+14155552671', '$2a$10$JEiDspHii0IOovPCDHMJYeTZkhqfb0ztUfQd8.Fo2eUXDIqtZ5vqO', 'pelanggan', 'United States', 'USD', 'London', 'Rumah Keluarga: Jl. Gejayan No. 45, Yogyakarta', -7.7735, 110.3921, '', 'active', 3),
  (4, 'Rahmat Hidayat (Teknisi)', 'teknisi@sima.net', '081987654321', '$2a$10$JEiDspHii0IOovPCDHMJYeTZkhqfb0ztUfQd8.Fo2eUXDIqtZ5vqO', 'teknisi', 'Indonesia', 'IDR', 'WIB', 'Basecamp Teknisi Sima, Jl. Palagan, Sleman', -7.7550, 110.3750, '', 'active', NULL),
  (5, 'Ahmad Faisal (Pending)', 'ahmad@gmail.com', '082233445566', '$2a$10$JEiDspHii0IOovPCDHMJYeTZkhqfb0ztUfQd8.Fo2eUXDIqtZ5vqO', 'pelanggan', 'Indonesia', 'IDR', 'WITA', 'Perumahan Graha Asri Blok C-3, Sleman', -7.7420, 110.3680, '', 'pending', 1)
ON CONFLICT (id) DO UPDATE SET password_hash = EXCLUDED.password_hash;

SELECT setval('users_id_seq', (SELECT MAX(id) FROM public.users));

-- SEED PACKAGES
INSERT INTO public.packages (id, nama, kecepatan_mbps, harga_idr, deskripsi)
VALUES
  (1, 'Paket Hemat Fiber 20', 20, 175000, 'Akses internet stabil unlimited untuk kebutuhan browsing dan media sosial keluarga kecil.'),
  (2, 'Paket Turbo Home 50', 50, 275000, 'Kecepatan tinggi untuk streaming 4K tanpa buffering, Zoom meeting, dan online gaming.'),
  (3, 'Paket Ultimate Pro 100', 100, 450000, 'Koneksi ultra-cepat fiber optic simetris untuk profesional, content creator, dan smart home.'),
  (4, 'Paket Fast Fiber 30', 30, 215000, 'Internet fiber optic handal untuk WFH, download cepat, dan streaming HD bebas lag.'),
  (5, 'Paket Turbo Home 75', 75, 340000, 'Keluarga besar aktif & smart TV multi-room, download file besar dalam hitungan detik.'),
  (6, 'Paket Gamer Sakti 100', 100, 399000, 'Jalur khusus gaming prioritas rendah latensi (<5ms), anti spike & zero packet loss.'),
  (7, 'Paket Gamer Pro 150', 150, 520000, 'Bandwidth simetris 1:1, live streaming YouTube/Twitch kualitas 1080p 60fps tanpa jeda.'),
  (8, 'Paket Promo Flash 60', 60, 239000, 'Promo spesial kuota unlimited kecepatan ekstra fiber optic hemat bulanan.'),
  (9, 'Paket Promo Pelajar Hemat', 25, 150000, 'Paket ramah kantong untuk pelajar & mahasiswa, riset kuliah & Google Classroom.')
ON CONFLICT (id) DO NOTHING;

SELECT setval('packages_id_seq', (SELECT MAX(id) FROM public.packages));

-- SEED INVOICES
INSERT INTO public.invoices (id, user_id, periode, nominal_idr, mata_uang, kurs_terkunci, jatuh_tempo, status)
VALUES
  (1, 2, 'Oktober 2026', 275000, 'IDR', 1.0, '2026-10-25 23:59:59+00', 'belum'),
  (2, 3, 'Oktober 2026', 450000, 'USD', 15500.0, '2026-10-25 23:59:59+00', 'lunas'),
  (3, 2, 'September 2026', 275000, 'IDR', 1.0, '2026-09-25 23:59:59+00', 'lunas')
ON CONFLICT (id) DO NOTHING;

SELECT setval('invoices_id_seq', (SELECT MAX(id) FROM public.invoices));

-- SEED PAYMENTS
INSERT INTO public.payments (id, invoice_id, user_id, bukti_path, nominal_idr, status, verified_at)
VALUES
  (1, 2, 3, '', 450000, 'diverifikasi', '2026-10-10 14:20:00+00'),
  (2, 3, 2, '', 275000, 'diverifikasi', '2026-09-20 10:15:00+00')
ON CONFLICT (id) DO NOTHING;

SELECT setval('payments_id_seq', (SELECT MAX(id) FROM public.payments));

-- SEED GENESIS LEDGER BLOCK
INSERT INTO public.ledger_blocks (idx, waktu, payment_id, nominal_idr, prev_hash, hash)
VALUES
  (0, '2026-10-01 08:00:00+00', 0, 0, '0000000000000000000000000000000000000000000000000000000000000000', 'c6374a3f4e3c4aa485df6496e7195bb263fa7907f185ef03bf7d101dcf2a6948')
ON CONFLICT (idx) DO NOTHING;

-- SEED TASKS
INSERT INTO public.tasks (id, teknisi_id, pelanggan_id, jenis, status, catatan)
VALUES
  (1, 4, 2, 'perbaikan', 'baru', 'Pengecekan redaman kabel optik dan ganti drop core port 2.'),
  (2, 4, 5, 'instalasi', 'dikerjakan', 'Tarik kabel FO dari ODP-SLM-08 ke rumah pelanggan baru.')
ON CONFLICT (id) DO NOTHING;

SELECT setval('tasks_id_seq', (SELECT MAX(id) FROM public.tasks));

-- SEED UPSTREAM BILLS
INSERT INTO public.upstream_bills (id, periode, nominal_idr, provider_name, status)
VALUES
  (1, 'September 2026', 4500000, 'Indibizz Dedicated 500M', 'lunas'),
  (2, 'Oktober 2026', 4500000, 'Indibizz Dedicated 500M', 'belum')
ON CONFLICT (id) DO NOTHING;

SELECT setval('upstream_bills_id_seq', (SELECT MAX(id) FROM public.upstream_bills));

-- SEED FEEDBACK
INSERT INTO public.feedback (id, user_id, user_nama, saran, kesan, created_at)
VALUES
  (1, 2, 'Budi Santoso', 'Mohon tambahkan opsi pembayaran otomatis via QRIS di rilis berikutnya.', 'Pelayanan Sima.net luar biasa cepat, teknisi ramah dan internet sangat stabil!', '2026-10-12 11:00:00+00')
ON CONFLICT (id) DO NOTHING;

SELECT setval('feedback_id_seq', (SELECT MAX(id) FROM public.feedback));

-- SEED PACKAGE REQUESTS
INSERT INTO public.package_requests (
  id, user_id, user_nama, user_email, user_alamat, user_no_hp,
  paket_lama_id, paket_lama_nama, paket_lama_kecepatan, paket_lama_harga,
  paket_baru_id, paket_baru_nama, paket_baru_kecepatan, paket_baru_harga,
  selisih_harga, tipe, alasan, status, admin_catatan, created_at, updated_at
) VALUES (
  1, 2, 'Budi Santoso', 'budi@gmail.com', 'Jl. Kaliurang KM 5 No. 12, Sleman', '085678912345',
  1, 'Paket Hemat Fiber 20', 20, 175000,
  2, 'Paket Turbo Home 50', 50, 275000,
  100000, 'Upgrade Kecepatan', 'Membutuhkan bandwidth lebih tinggi untuk streaming 4K dan gaming stabil.',
  'approved', 'Disetujui. Perangkat & konfigurasi siap disesuaikan.',
  '2026-10-18 17:23:23+00', '2026-10-18 17:24:15+00'
) ON CONFLICT (id) DO NOTHING;

SELECT setval('package_requests_id_seq', COALESCE((SELECT MAX(id) FROM public.package_requests), 1));
