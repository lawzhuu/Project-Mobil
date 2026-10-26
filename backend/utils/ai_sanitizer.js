/**
 * Utility untuk membersihkan simbol-simbol formatting AI (seperti **, *, ###, backticks)
 * agar output teks di mobile terlihat bersih, alami, dan rapi tanpa sisa sintaks markdown.
 */
function sanitizeAiText(text) {
  if (!text || typeof text !== 'string') return '';
  return text
    // Hapus format bold (**teks**)
    .replace(/\*\*(.*?)\*\*/g, '$1')
    // Hapus format italic (*teks* atau _teks_)
    .replace(/\*(.*?)\*/g, '$1')
    .replace(/__(.*?)__/g, '$1')
    .replace(/_([^_]+)_/g, '$1')
    // Hapus heading markdown (### Judul -> Judul)
    .replace(/^#{1,6}\s+/gm, '')
    // Konversi bullet asteris menjadi bullet standar bullet dot (•)
    .replace(/^\s*[\*\-]\s+/gm, '• ')
    // Hapus backtick kode (`kode`)
    .replace(/```[\s\S]*?```/g, '')
    .replace(/`([^`]+)`/g, '$1')
    // Rapikan baris kosong berlebih
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

module.exports = { sanitizeAiText };
