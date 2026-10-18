# 🚀 Panduan Setup & Migrasi Backend Sima.net ke Supabase

Setup backend telah berhasil dimigrasikan secara bersih ke **Supabase** (PostgreSQL Database + Storage Bucket).
Backend dirancang secara cerdas:
- Jika environment Supabase (`SUPABASE_URL` & `SUPABASE_KEY`) sudah diisi, sistem otomatis menggunakan **Supabase PostgreSQL** dan **Supabase Storage** untuk foto profil.
- Jika kunci belum diisi, backend tetap berjalan mulus dalam mode lokal tanpa error/crash (`local fallback`).

---

## 📋 Langkah-langkah Penggunaan

### 1. Eksekusi Skrip SQL di Supabase
1. Buka dashboard proyek Supabase Anda: [https://supabase.com/dashboard](https://supabase.com/dashboard).
2. Pilih proyek Anda, lalu buka menu **SQL Editor** di sidebar kiri.
3. Buka file [`supabase_schema.sql`](file:///c:/Users/Zaky%20Surya%20Fadillah/OneDrive/Documents/Semester%205/MOBILE/Project-Mobil/supabase_schema.sql) di root workspace (atau copy isinya).
4. Paste seluruh isi skrip ke SQL Editor Supabase, lalu klik tombol **Run**.
   > Skrip ini otomatis:
   > - Membuat semua tabel: `users`, `packages`, `invoices`, `payments`, `ledger_blocks`, `tasks`, `upstream_bills`, `feedback`, `devices`.
   > - Membuat public storage bucket `profile-photos` dengan permission public read & insert.
   > - Mengisi data awal (seed) seperti akun default Admin, Pelanggan, Teknisi (password: `123`), paket internet, dan transaksi.

---

### 2. Memasukkan Kunci API ke File `.env`
Buka file [`backend/.env`](file:///c:/Users/Zaky%20Surya%20Fadillah/OneDrive/Documents/Semester%205/MOBILE/Project-Mobil/backend/.env) dan lengkapi konfigurasi berikut:

```env
PORT=3000
JWT_SECRET=simanet-super-secret-jwt-key-2026

# Groq API Configuration
GROQ_API_KEY=gsk_your_groq_api_key_here
GROQ_MODEL=openai/gpt-oss-120b

# ==============================================================================
# Supabase Configuration
# Dapatkan dari: Supabase Dashboard -> Project Settings -> API
# ==============================================================================
SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxx.supabase.co
SUPABASE_KEY=...

# Nama Storage Bucket untuk foto profil & bukti pembayaran
# (Default: profile-photos, otomatis dibuat dan diset Public)
SUPABASE_STORAGE_BUCKET=profile-photos
```

> **Catatan Kunci:**
> - `SUPABASE_URL`: Project URL (contoh: `https://xyzproject.supabase.co`).
> - `SUPABASE_KEY`: Anda bisa menggunakan **anon (public)** key atau **service_role (secret)** key.

---

### 3. Migrasi Data Lokal ke Supabase (Opsional / Sekali Jalan)
Jika Anda ingin menyinkronkan seluruh isi `database.json` lokal ke Supabase secara langsung melalui CLI:
Buka terminal di folder `backend`, lalu jalankan:
```bash
npm run migrate:supabase
```
Skrip ini akan memverifikasi bucket storage dan meng-upload semua data lokal ke tabel Supabase.

---

### 4. Menjalankan Backend
Restart atau jalankan server backend:
```bash
node server.js
# atau
npm run dev
```

Pada log terminal akan muncul konfirmasi:
```
[Sima.net Backend] Server running on http://0.0.0.0:3000
[Database] Supabase is configured. Initializing sync from Supabase...
[Database] Local cache successfully synced with Supabase PostgreSQL.
[Supabase Storage] Public bucket "profile-photos" is ready.
```

---

## 📸 Fitur Upload Foto Profil ke Supabase Storage
1. Pengguna membuka menu **Profil** di aplikasi mobile.
2. Klik ikon kamera pada avatar -> pilih **Kamera Langsung** atau **Galeri Gambar**.
3. Foto akan otomatis diunggah langsung ke **Supabase Storage** pada bucket `profile-photos/avatars/`.
4. URL publik gambar (contoh: `https://...supabase.co/storage/v1/object/public/profile-photos/avatars/...`) disimpan ke kolom `foto` pada tabel `users`.
5. Avatar di aplikasi langsung memperbarui tampilan dengan gambar dari Supabase Storage.
