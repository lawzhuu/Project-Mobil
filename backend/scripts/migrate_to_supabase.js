require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { isSupabaseConfigured, getSupabaseClient, BUCKET_NAME } = require('../config/supabase');
const supabaseDb = require('../services/supabase_db.service');
const { ensureBucketExists } = require('../services/storage.service');
const { loadDB } = require('../db');

async function main() {
  console.log('====================================================');
  console.log(' SIMA.NET - SUPABASE DATABASE & STORAGE MIGRATION');
  console.log('====================================================\n');

  if (!isSupabaseConfigured()) {
    console.error('❌ ERROR: Supabase belum dikonfigurasi di file .env');
    console.log('Harap isi environment variable berikut di file backend/.env:');
    console.log('- SUPABASE_URL=https://your-project-id.supabase.co');
    console.log('- SUPABASE_KEY=your-supabase-anon-or-service-role-key');
    console.log('- SUPABASE_STORAGE_BUCKET=profile-photos (opsional, default: profile-photos)\n');
    process.exit(1);
  }

  const supabase = getSupabaseClient();
  if (!supabase) {
    console.error('❌ ERROR: Gagal menginisialisasi klien Supabase.');
    process.exit(1);
  }

  console.log('1. Memeriksa & Menginisialisasi Storage Bucket Supabase...');
  try {
    await ensureBucketExists();
    console.log(`   ✓ Bucket "${BUCKET_NAME}" siap digunakan untuk upload foto profil.`);
  } catch (err) {
    console.warn(`   ⚠️ Warning Storage: ${err.message}`);
  }

  console.log('\n2. Membaca data lokal dari database.json...');
  const localData = loadDB();
  console.log(`   - Users: ${localData.users?.length || 0}`);
  console.log(`   - Packages: ${localData.packages?.length || 0}`);
  console.log(`   - Invoices: ${localData.invoices?.length || 0}`);
  console.log(`   - Payments: ${localData.payments?.length || 0}`);
  console.log(`   - Ledger Blocks: ${localData.ledger_blocks?.length || 0}`);
  console.log(`   - Tasks: ${localData.tasks?.length || 0}`);
  console.log(`   - Upstream Bills: ${localData.upstream_bills?.length || 0}`);
  console.log(`   - Feedback: ${localData.feedback?.length || 0}`);
  console.log(`   - Devices: ${localData.devices?.length || 0}`);

  console.log('\n3. Mengunggah data ke tabel Supabase PostgreSQL...');
  try {
    await supabaseDb.pushAll(localData);
    console.log('\n====================================================');
    console.log('🎉 MIGRASI KE SUPABASE BERHASIL 100%!');
    console.log('Semua tabel dan storage bucket Supabase telah sinkron.');
    console.log('====================================================\n');
  } catch (err) {
    console.error('\n❌ Terjadi kesalahan saat migrasi:', err.message);
    console.log('\n💡 Tips: Pastikan Anda telah menjalankan skrip backend/supabase_schema.sql');
    console.log('   di menu SQL Editor dashboard Supabase terlebih dahulu.');
    process.exit(1);
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
