const path = require('path');

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'simanet-super-secret-jwt-key-2026';
const DB_FILE = path.join(__dirname, '..', 'database.json');
const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');

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
