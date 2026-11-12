// ==============================================================================
// PANDUAN PEMULA: FUNGSI HASH KRIPTOGRAFI SHA-256 (BLOCKCHAIN UTILITY)
// ==============================================================================
// SHA-256 (Secure Hash Algorithm 256-bit) adalah fungsi hash satu arah:
// - Input: Gabungan string `idx|waktu|payment_id|nominal_idr|prev_hash`.
// - Output: String heksadesimal 64 karakter yang unik.
// - Sifat Penting:
//   1. Deterministik: Input yang sama selalu menghasilkan hash yang identik.
//   2. Efek Longsor (Avalanche Effect): Mengubah 1 digit angka atau 1 spasi akan mengubah total hasil hash.
//   3. Satu Arah: Tidak bisa di-dekripsi balik menjadi data asli.
// ==============================================================================

const crypto = require('crypto');

function calculateBlockHash(idx, waktu, payment_id, nominal_idr, prev_hash) {
  const content = `${idx}|${waktu}|${payment_id}|${nominal_idr}|${prev_hash}`;
  return crypto.createHash('sha256').update(content).digest('hex');
}

module.exports = {
  calculateBlockHash
};
