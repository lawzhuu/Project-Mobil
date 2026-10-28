const fs = require('fs');
const path = require('path');
const { UPLOAD_DIR } = require('../config');
const { getSupabaseClient, isSupabaseConfigured, BUCKET_NAME } = require('../config/supabase');

// Ensure local upload dir exists for fallback (safe for read-only serverless environment)
try {
  if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
  }
} catch (err) {
  // Read-only filesystem in serverless environments (Vercel)
}

let bucketChecked = false;

/**
 * Ensures the public storage bucket exists in Supabase.
 */
async function ensureBucketExists() {
  if (!isSupabaseConfigured() || bucketChecked) return;
  const supabase = getSupabaseClient();
  if (!supabase) return;

  try {
    const { data: buckets, error } = await supabase.storage.listBuckets();
    if (error) {
      console.warn('[Supabase Storage] Could not list buckets:', error.message);
      return;
    }

    const exists = buckets && buckets.some(b => b.name === BUCKET_NAME || b.id === BUCKET_NAME);
    if (!exists) {
      console.log(`[Supabase Storage] Bucket "${BUCKET_NAME}" does not exist. Creating public bucket...`);
      const { data, error: createErr } = await supabase.storage.createBucket(BUCKET_NAME, {
        public: true,
        fileSizeLimit: 10485760 // 10MB
      });

      if (createErr) {
        console.warn('[Supabase Storage] Bucket creation note:', createErr.message);
      } else {
        console.log(`[Supabase Storage] Public bucket "${BUCKET_NAME}" created successfully!`);
      }
    } else {
      bucketChecked = true;
    }
  } catch (err) {
    console.warn('[Supabase Storage] Bucket verification note:', err.message);
  }
}

/**
 * Upload a file buffer to Supabase Storage (or fallback to local disk).
 * @param {Object} file - Multer file object (with buffer, originalname, mimetype)
 * @param {String} folder - Subfolder name inside bucket (default: 'avatars')
 * @returns {Promise<String>} The public URL or relative path of the uploaded file
 */
async function uploadFile(file, folder = 'avatars') {
  if (!file) return '';

  const ext = path.extname(file.originalname) || '.jpg';
  const fileName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
  const filePath = `${folder}/${fileName}`;

  // 1. Try Supabase Storage if configured
  if (isSupabaseConfigured()) {
    const supabase = getSupabaseClient();
    if (supabase) {
      try {
        await ensureBucketExists();
        console.log(`[Supabase Storage] Uploading file to bucket "${BUCKET_NAME}" path "${filePath}"...`);
        
        const { data, error } = await supabase.storage
          .from(BUCKET_NAME)
          .upload(filePath, file.buffer, {
            contentType: file.mimetype || 'image/jpeg',
            upsert: true
          });

        if (error) {
          console.warn(`[Supabase Storage Warning]: ${error.message}. Falling back to local storage.`);
        } else {
          const { data: publicData } = supabase.storage
            .from(BUCKET_NAME)
            .getPublicUrl(filePath);

          console.log(`[Supabase Storage] Upload successful: ${publicData.publicUrl}`);
          return publicData.publicUrl;
        }
      } catch (err) {
        console.error('[Supabase Storage Error]:', err.message);
      }
    }
  }

  // 2. Local Fallback
  try {
    const localDiskPath = path.join(UPLOAD_DIR, fileName);
    fs.writeFileSync(localDiskPath, file.buffer);
    console.log(`[Storage] Saved file to local storage: /uploads/${fileName}`);
    return `/uploads/${fileName}`;
  } catch (err) {
    console.warn('[Storage] Local storage write skipped (read-only filesystem):', err.message);
    return '';
  }
}

module.exports = {
  uploadFile,
  ensureBucketExists,
  BUCKET_NAME
};
