// ==============================================================================
// PANDUAN PEMULA: SERVER UTAMA EXPRESS.JS (SIMA.NET BACKEND API)
// ==============================================================================
// File ini adalah pintu masuk (entry point) dari aplikasi server backend:
// 1. Membaca konfigurasi dari file `.env` (Port, JWT Secret, URL Supabase).
// 2. Menginisialisasi web framework Express.js.
// 3. Memasang Middleware global: CORS (Cross-Origin Resource Sharing), JSON Parser.
// 4. Mendaftarkan seluruh rute API modular (`./routes`).
// 5. Menjalankan server lokal pada IP `0.0.0.0` dan Port yang ditentukan.
// ==============================================================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PORT, UPLOAD_DIR } = require('./config');

const routes = require('./routes');
const { initDB, refreshDBFromSupabase, getLastSupabasePull } = require('./db');
const { ensureBucketExists } = require('./services/storage.service');

// Membuat instance aplikasi Express
const app = express();

// ==============================================================================
// GLOBAL MIDDLEWARES (Dijalankan pada SETIAP request HTTP yang masuk)
// ==============================================================================
// cors()                : Mengizinkan request dari domain/IP berbeda (misal Flutter Web & Mobile).
// express.json()        : Mem-parsing body request berformat JSON menjadi objek JavaScript (req.body).
// express.urlencoded()  : Mem-parsing data form url-encoded.
// express.static()      : Melayani file gambar/bukti bayar statis dari folder lokal uploads.
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(UPLOAD_DIR));

// Flag penanda apakah database dan bucket storage sudah siap digunakan
let isInitialized = false;
let initPromise = null;

// Fungsi inisialisasi database dan storage (Aman untuk Vercel Serverless maupun Local Server)
async function ensureAppInitialized() {
  if (isInitialized) return;
  if (!initPromise) {
    initPromise = (async () => {
      try {
        await initDB();
        await ensureBucketExists();
        isInitialized = true;
      } catch (err) {
        console.warn('[Sima.net Backend] Init notice:', err.message);
      }
    })();
  }
  return initPromise;
}

// Middleware penjamin inisialisasi & kesegaran database sebelum request ditangani controller
app.use(async (req, res, next) => {
  if (!isInitialized) {
    await ensureAppInitialized();
  } else if (req.method === 'GET' && (Date.now() - getLastSupabasePull() > 4000)) {
    // Segarkan cache RAM dari Supabase jika ada request GET dan data di RAM sudah lebih dari 4 detik
    await refreshDBFromSupabase().catch(() => {});
  }
  next();
});

// Mendaftarkan Master Router yang menggabungkan seluruh endpoint API modular
app.use(routes);

// Menjalankan server pada mode lokal (diabaikan jika dihosting di Vercel Serverless Function)
if (!process.env.VERCEL) {
  app.listen(PORT, '0.0.0.0', async () => {
    console.log(`[Sima.net Backend] Server running on http://0.0.0.0:${PORT}`);
    await ensureAppInitialized();
  });
}

module.exports = app;
