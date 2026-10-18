const express = require('express');
const { loadDB, saveDB } = require('../db');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get upstream ISP bills (Admin only)
router.get('/upstream-bills', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, upstream_bills: db.upstream_bills });
});

// Admin record upstream ISP bill
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

// Admin financial summary report
router.get('/reports/summary', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();

  // Revenue from paid invoices
  const totalCustomerRevenue = db.invoices
    .filter(i => i.status === 'lunas')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Unpaid invoices
  const pendingRevenue = db.invoices
    .filter(i => i.status === 'belum')
    .reduce((acc, i) => acc + i.nominal_idr, 0);

  // Upstream ISP cost
  const totalUpstreamCost = db.upstream_bills
    .reduce((acc, b) => acc + b.nominal_idr, 0);

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
