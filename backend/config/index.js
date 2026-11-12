// ==============================================================================
// PANDUAN PEMULA: KONFIGURASI PUSAT SISTEM (ENVIRONMENT & APP CONFIG)
// ==============================================================================
// File ini mengumpulkan seluruh variabel lingkungan (.env) ke satu tempat:
// - PORT          : Port HTTP server backend berjalan (default 3000).
// - JWT_SECRET    : Kunci rahasia untuk menandatangani (sign) token JWT login.
// - DB_FILE       : Jalur file database JSON lokal (fallback offline/serverless).
// - UPLOAD_DIR    : Direktori penyimpanan file lokal jika Supabase tidak aktif.
// - STATIC_RATES  : Nilai kurs konversi mata uang statis (IDR, USD, EUR).
// - SUPABASE_*    : Kredensial koneksi cloud database & cloud storage Supabase.
// ==============================================================================

const path = require('path');

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'simanet-super-secret-jwt-key-2026';
const DB_FILE = path.join(__dirname, '..', 'database.json');
const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');

// Nilai kurs mata uang referensi tetap (Sesuai kebutuhan PRD konversi IDR, USD, EUR)
// Diperbarui ke nilai pasar valuta aktual (~16.300 IDR / USD & ~17.600 IDR / EUR)
const STATIC_RATES = {
  base: 'IDR',
  date: '2026-11-13',
  rates: {
    IDR: 1.0,
    USD: 0.00006135,  // ~16.300 IDR per 1 USD
    EUR: 0.00005682   // ~17.600 IDR per 1 EUR
  },
  idrPerCurrency: {
    IDR: 1.0,
    USD: 16300.0,
    EUR: 17600.0
  }
};

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_KEY = process.env.SUPABASE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '';
const SUPABASE_STORAGE_BUCKET = process.env.SUPABASE_STORAGE_BUCKET || 'profile-photos';

module.exports = {
  PORT,
  JWT_SECRET,
  DB_FILE,
  UPLOAD_DIR,
  STATIC_RATES,
  SUPABASE_URL,
  SUPABASE_KEY,
  SUPABASE_STORAGE_BUCKET
};
