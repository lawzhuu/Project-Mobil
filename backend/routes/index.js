// ==============================================================================
// PANDUAN PEMULA: MASTER ROUTER INDEX (PENGGABUNG SELURUH MODUL API)
// ==============================================================================
// File ini mengumpulkan seluruh berkas rute modular menjadi satu router utama.
// Dengan pendekatan modular ini, kode backend menjadi rapi, terisolasi per fitur,
// dan mudah dipelihara atau diuji.
//
// DAFTAR MODUL API YANG DIGABUNGKAN:
// 1. authRoutes      : /auth/register, /auth/login, /me (Profil & Foto)
// 2. packageRoutes   : /packages (Daftar paket internet Wi-Fi)
// 3. customerRoutes  : /customers (Kelola data & kuota pelanggan)
// 4. invoiceRoutes   : /invoices, /payments (Tagihan & Bukti Pembayaran)
// 5. ledgerRoutes    : /ledger (Blockchain SHA-256 verifikasi transparansi)
// 6. taskRoutes      : /tasks (Tugas instalasi & perbaikan teknisi lapangan)
// 7. reportRoutes    : /reports (Laporan manajerial ringkasan)
// 8. analyticsRoutes : /analytics (Prediksi pendapatan & analisis risiko telat bayar)
// 9. chatRoutes      : /chat (Layanan obrolan CS / Bot bantuan)
// 10. aiAdvisorRoutes: /ai-advisor (AI rekomendasi bandwidth rumah tangga)
// 11. commonRoutes   : /health, /rates (Pengecekan server aktif & kurs mata uang)
// ==============================================================================

const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const packageRoutes = require('./package.routes');
const customerRoutes = require('./customer.routes');
const invoiceRoutes = require('./invoice.routes');
const ledgerRoutes = require('./ledger.routes');
const taskRoutes = require('./task.routes');
const reportRoutes = require('./report.routes');
const analyticsRoutes = require('./analytics.routes');
const chatRoutes = require('./chat.routes');
const aiAdvisorRoutes = require('./ai_advisor.routes');
const commonRoutes = require('./common.routes');

router.use(authRoutes);
router.use(packageRoutes);
router.use(customerRoutes);
router.use(invoiceRoutes);
router.use(ledgerRoutes);
router.use(taskRoutes);
router.use(reportRoutes);
router.use(analyticsRoutes);
router.use(chatRoutes);
router.use(aiAdvisorRoutes);
router.use(commonRoutes);

module.exports = router;
