// ==============================================================================
// PANDUAN PEMULA: KONEKSI SUPABASE CLOUD (POSTGRESQL & OBJECT STORAGE)
// ==============================================================================
// File ini mengelola inisialisasi client Supabase menggunakan package `@supabase/supabase-js`.
// - isSupabaseConfigured() : Memeriksa apakah URL & API Key Supabase valid di file .env.
// - getSupabaseClient()    : Mengembalikan instance singleton client Supabase untuk query DB.
// - BUCKET_NAME            : Nama bucket penyimpanan foto struk & foto profil di cloud storage.
// ==============================================================================

const { createClient } = require('@supabase/supabase-js');
const { SUPABASE_URL, SUPABASE_KEY, SUPABASE_STORAGE_BUCKET } = require('./index');

let supabase = null;

// Memeriksa kelayakan kredensial Supabase
function isSupabaseConfigured() {
  const url = (SUPABASE_URL || process.env.SUPABASE_URL || '').trim();
  const key = (SUPABASE_KEY || process.env.SUPABASE_KEY || '').trim();
  
  if (!url || !key) return false;
  if (url.includes('your-project-id') || key.includes('your-supabase')) return false;
  return true;
}

// Inisialisasi client Supabase dengan pola Singleton (hanya 1 instance dibuat)
function getSupabaseClient() {
  if (!isSupabaseConfigured()) {
    return null;
  }

  if (!supabase) {
    const url = (SUPABASE_URL || process.env.SUPABASE_URL || '').trim();
    const key = (SUPABASE_KEY || process.env.SUPABASE_KEY || '').trim();
    
    try {
      supabase = createClient(url, key, {
        auth: {
          persistSession: false,
          autoRefreshToken: false
        }
      });
      console.log(`[Supabase] Client initialized successfully for: ${url}`);
    } catch (err) {
      console.error('[Supabase] Failed to initialize Supabase client:', err.message);
      return null;
    }
  }

  return supabase;
}

const BUCKET_NAME = process.env.SUPABASE_STORAGE_BUCKET || SUPABASE_STORAGE_BUCKET || 'profile-photos';

module.exports = {
  getSupabaseClient,
  isSupabaseConfigured,
  BUCKET_NAME
};
