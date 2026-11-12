// ==============================================================================
// PANDUAN PEMULA: MIDDLEWARE UPLOAD FILE (MULTER IN-MEMORY BUFFER)
// ==============================================================================
// Package `multer` menangani request HTTP bertipe `multipart/form-data` (kirim file):
// - memoryStorage: Menyimpan file yang diunggah sementara ke dalam RAM Buffer (`req.file.buffer`).
//   Kelebihan: File dapat langsung di-streaming ke Supabase Cloud Storage tanpa harus disimpan
//   ke harddisk server terlebih dahulu, sangat cocok untuk lingkungan Vercel Serverless!
// - limits: Membatasi ukuran maksimal file yang diizinkan (maksimal 10 MB).
// ==============================================================================

const multer = require('multer');

const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 } // Batas ukuran 10 MB per file
});

module.exports = upload;
