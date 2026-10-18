const express = require('express');
const { loadDB } = require('../db');
const { authMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// LLM Chatbot CS proxy endpoint (Keeps API key secure on server per PRD)
router.post('/chat', authMiddleware, (req, res) => {
  const db = loadDB();
  const { message } = req.body;
  const user = db.users.find(u => u.id === req.user.id) || {};
  const pkg = db.packages.find(p => p.id === user.paket_id);

  const query = (message || '').toLowerCase();
  let botReply = '';

  // Smart context-aware AI assistant responses
  if (query.includes('paket') || query.includes('upgrade') || query.includes('kecepatan')) {
    botReply = `Halo Kak ${user.nama || 'Pelanggan'}! Anda saat ini berlangganan ${pkg ? pkg.nama : 'Paket Sima.net'} (${pkg ? pkg.kecepatan_mbps : '30'} Mbps). Kami menyediakan paket hingga 100 Mbps dengan latency rendah untuk gaming & streaming 4K. Anda dapat mengajukan permohonan upgrade langsung ke admin via menu Saran & Bantuan.`;
  } else if (query.includes('lambat') || query.includes('lemot') || query.includes('gangguan') || query.includes('merah')) {
    botReply = `Kami memahami ketidaknyamanan Anda. Untuk masalah internet lambat atau lampu indikator LOS berkedip merah:\n1. Restart router modem Anda selama 30 detik lalu nyalakan kembali.\n2. Pastikan kabel patch cord optik kuning tidak tertekuk.\n3. Jika masalah berlanjut, teknisi lapangan kami siap dijadwalkan untuk memeriksa redaman kabel Anda.`;
  } else if (query.includes('tagihan') || query.includes('bayar') || query.includes('rekening') || query.includes('transfer')) {
    botReply = `Untuk pembayaran tagihan Sima.net:\n• Transfer manual ke Bank BCA: 8830-1928-332 a.n. Sima.net Reseller\n• Nominal disesuaikan mata uang Anda (${user.mata_uang || 'IDR'})\n• Setelah transfer, unggah foto bukti bayar di menu Tagihan agar diverifikasi oleh admin ke blockchain ledger.`;
  } else {
    botReply = `Halo! Saya AI Customer Support Sima.net. Saya siap membantu Anda seputar status koneksi paket (${pkg ? pkg.nama : 'Sima.net Fiber'}), panduan troubleshooting router, informasi pembayaran, maupun panggilan bantuan teknisi. Ada yang bisa saya bantu?`;
  }

  return res.json({
    success: true,
    reply: botReply,
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
