// ==============================================================================
// PANDUAN PEMULA: VERCEL SERVERLESS FUNCTION ENTRY POINT
// ==============================================================================
// File ini berfungsi sebagai gerbang utama saat backend di-deploy ke Vercel Cloud:
// - Vercel membaca folder `/api` secara otomatis untuk menangani request serverless.
// - Request yang masuk diteruskan langsung ke instance Express `app` dari `../server.js`.
// - Dengan file ini, backend dapat berjalan fleksibel: bisa di komputer lokal (Node.js)
//   maupun di cloud serverless (Vercel) tanpa perlu mengubah kode server sama sekali.
// ==============================================================================

const app = require('../server');

module.exports = app;
