const { createClient } = require('@supabase/supabase-js');
const { SUPABASE_URL, SUPABASE_KEY, SUPABASE_STORAGE_BUCKET } = require('./index');

let supabase = null;

function isSupabaseConfigured() {
  const url = process.env.SUPABASE_URL || SUPABASE_URL || '';
  const key = process.env.SUPABASE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || SUPABASE_KEY || '';
  
  if (!url || !key) return false;
  if (url.includes('your-project-id') || key.includes('your-supabase')) return false;
  return true;
}

function getSupabaseClient() {
  if (!isSupabaseConfigured()) {
    return null;
  }

  if (!supabase) {
    const url = (process.env.SUPABASE_URL || SUPABASE_URL).trim();
    const key = (process.env.SUPABASE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || SUPABASE_KEY).trim();
    
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
