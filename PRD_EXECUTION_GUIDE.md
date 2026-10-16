# Panduan Eksekusi & Pengujian Aplikasi Sima.net

Aplikasi mobile Flutter **Sima.net** (Reseller ISP & Smart Billing Operations) dan backend terpisah Express REST API telah selesai diimplementasikan sesuai seluruh ketentuan PRD & checklist dosen.

---

## 1. Menjalankan Backend Terpisah

Backend dibangun menggunakan **Node.js + Express** dengan database terstruktur, hashing password `bcrypt`, sesi `JWT`, blockchain ledger `SHA-256`, proxy LLM Chatbot CS, dan AI Forecasting.

### Langkah Menjalankan:
```bash
cd backend
npm install
node server.js
```
> Server berjalan di: `http://localhost:3000` (atau `http://0.0.0.0:3000`).

---

## 2. Menjalankan Aplikasi Flutter

```bash
cd apk_wifi
flutter run
```

### Konfigurasi Alamat Backend di Flutter:
Aplikasi telah dilengkapi pengaturan dinamis Base URL yang dapat diakses langsung dari tombol ikon di pojok kanan atas layar login atau di menu profil:
- **Emulator Android:** `http://10.0.2.2:3000`
- **Windows / Web / Desktop:** `http://localhost:3000`
- **Device Fisik Android via Wi-Fi:** `http://<IP_KOMPUTER_ANDA>:3000` (misal: `http://192.168.1.10:3000`)

---

## 3. Akun Kredensial Pengujian (Demo Seed)

Pada halaman Login, telah disediakan **tombol pintasan cepat (Quick Autofill)** untuk langsung mengisi akun tanpa mengetik manual:

| Role | Username / Email / IP | Password | Catatan Pengujian |
|---|---|---|---|
| **Admin** | `admin@sima.net` atau `192.168.1.1` | `123` | Akses penuh: Aktivasi pelanggan, AI forecast chart, skor risiko telat bayar, verifikasi bukti bayar, blockchain ledger SHA-256, tagihan Indibizz, tugas teknisi. |
| **Pelanggan Lokal (IDR)** | `budi@gmail.com` | `123` | Paket Turbo 50 Mbps, tagihan dalam Rupiah (WIB). |
| **Pelanggan Diaspora (USD)** | `sarah@gmail.com` | `123` | Paket Ultimate 100 Mbps, tagihan terkonversi ke **USD ($)** dengan kurs terkunci, jatuh tempo di zona waktu **London**. |
| **Teknisi Lapangan** | `teknisi@sima.net` | `123` | Daftar tugas instalasi/perbaikan, peta lapangan OpenStreetMap (LBS), kompas magnetometer digital menuju rumah pelanggan, pengubah status (Baru, Dikerjakan, Selesai). |

---

## 4. Checklist Pemenuhan Syarat PRD & Dosen

1. [x] **Login Terenkripsi & Sesi Tanpa Firebase:** Bcrypt password di server, JWT disimpan di `flutter_secure_storage`.
2. [x] **Login Biometrik:** Menggunakan `local_auth` sebagai pintasan sidik jari di Login dan Profil.
3. [x] **Penyimpanan Lokal & Online:** `sqflite` (dengan dukungan FFI desktop) sebagai cache offline paket, tagihan, kurs, dan tugas; database online di backend Express.
4. [x] **Web Service / REST API:** CRUD endpoint lengkap untuk seluruh role.
5. [x] **LBS (Location Based Service):** `flutter_map` (OpenStreetMap) dan `geolocator` untuk pin koordinat rumah saat registrasi pelanggan dan marker titik tugas teknisi.
6. [x] **Bottom Navigation:** Beranda, Menu Utama sesuai role dinamis, Saran & Kesan, Profil (dengan `image_picker`), Logout.
7. [x] **Konversi Mata Uang (3 Valuta):** IDR, USD, EUR dengan kurs referensi terintegrasi.
8. [x] **Konversi Waktu Dunia:** 4 zona waktu operasional (WIB, WITA, WIT, London) dengan jam digital live ticking sync.
9. [x] **Integrasi Klien Luar Negeri:** Negara registrasi menentukan mata uang dan zona waktu tampilan; kurs dikunci saat pembuatan invoice.
10. [x] **Minimal 2 Sensor:** `sensors_plus` Accelerometer (Mini Game Tilt Fiber) dan Magnetometer (Kompas Navigasi Teknisi).
11. [x] **Fitur AI (Non-LLM):** Forecast pemasukan 6 bulan ke depan dengan grafik interaktif `fl_chart` + Skor risiko telat bayar pelanggan.
12. [x] **Fitur LLM Terpisah dari AI:** Chatbot AI Customer Support via proxy backend `/chat` tanpa menyimpan API key di aplikasi client.
13. [x] **Mini Game Tilt:** "Sambungkan Kabel Fiber" menggerakkan pulsa optik ke Port ODP menggunakan sensor kemiringan (accelerometer) + tombol kontrol fallback.
14. [x] **Notifikasi Mobile:** `flutter_local_notifications` untuk pengingat jatuh tempo tagihan dan verifikasi pembayaran.
15. [x] **Blockchain Sederhana:** Hash-chain SHA-256 untuk pembayaran terverifikasi dengan verifikasi integritas rantai secara matematis oleh admin.
