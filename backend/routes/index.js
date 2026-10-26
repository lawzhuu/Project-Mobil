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
