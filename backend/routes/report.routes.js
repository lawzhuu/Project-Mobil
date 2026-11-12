// ==============================================================================
// PANDUAN PEMULA: MODUL LAPORAN KEUANGAN & UPSTREAM ISP (FINANCIAL SUMMARY)
// ==============================================================================
// Bisnis Reseller ISP membeli kuota bandwidth besar dari ISP Utama (Upstream seperti Indibizz),
// lalu membagikannya ke pelanggan rumahan. Modul ini menghitung performa laba rugi:
// 1. GET  /upstream-bills : Melihat riwayat tagihan beban bandwidth upstream.
// 2. POST /upstream-bills : Mencatat tagihan pembayaran ke ISP utama.
// 3. GET  /reports/summary:
//    - Total Revenue  : Jumlah rupiah dari seluruh invoice pelanggan berstatus 'lunas'.
//    - Pending Revenue: Potensi omset dari invoice pelanggan yang 'belum' bayar.
//    - Total Cost     : Total beban biaya bandwidth ISP utama.
//    - Net Profit     : Laba Bersih = Total Revenue - Total Upstream Cost.
// ==============================================================================

const express = require('express');
const { loadDB, saveDB } = require('../db');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// 1. ENDPOINT MELIHAT TAGIHAN UPSTREAM (GET /upstream-bills - Khusus Admin)
router.get('/upstream-bills', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, upstream_bills: db.upstream_bills });
});

// 2. ENDPOINT MENCATAT TAGIHAN UPSTREAM BARU (POST /upstream-bills - Khusus Admin)
router.post('/upstream-bills', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const { periode, nominal_idr, provider_name, status } = req.body;

  const newBill = {
    id: db.upstream_bills.length ? Math.max(...db.upstream_bills.map(b => b.id)) + 1 : 1,
    periode: periode || 'Oktober 2026',
    nominal_idr: parseInt(nominal_idr) || 4500000,
    provider_name: provider_name || 'Indibizz Dedicated',
    status: status || 'belum'
  };

  db.upstream_bills.push(newBill);
  saveDB(db);
  return res.status(201).json({ success: true, message: 'Tagihan ISP utama berhasil dicatat', bill: newBill });
});

// 3. ENDPOINT RINGKASAN LAPORAN KEUANGAN & LABA BERSIH (GET /reports/summary - Khusus Admin)
router.get('/reports/summary', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();

  // Pemasukan riil dari seluruh invoice yang berstatus 'lunas'
  const totalCustomerRevenue = db.invoices
    .filter(i => i.status === 'lunas')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Tagihan yang masih tertunda/belum lunas
  const pendingRevenue = db.invoices
    .filter(i => i.status === 'belum')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Beban biaya sewa bandwidth ke ISP utama (Indibizz)
  const totalUpstreamCost = db.upstream_bills
    .reduce((acc, b) => acc + b.nominal_idr, 0);

  // Rumus Laba Bersih: Pendapatan Riil - Beban Operasional Upstream
  const netProfit = totalCustomerRevenue - totalUpstreamCost;

  return res.json({
    success: true,
    summary: {
      total_revenue_idr: totalCustomerRevenue,
      pending_revenue_idr: pendingRevenue,
      total_upstream_cost_idr: totalUpstreamCost,
      net_profit_idr: netProfit,
      active_customers: db.users.filter(u => u.role === 'pelanggan' && u.status === 'active').length,
      pending_customers: db.users.filter(u => u.role === 'pelanggan' && u.status === 'pending').length,
      total_technicians: db.users.filter(u => u.role === 'teknisi').length
    }
  });
});

module.exports = router;
