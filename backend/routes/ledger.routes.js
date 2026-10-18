const express = require('express');
const { loadDB } = require('../db');
const { calculateBlockHash } = require('../utils/hash');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// Get full blockchain ledger blocks (Admin only)
router.get('/ledger', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, ledger: db.ledger_blocks });
});

// Verify cryptographic integrity of entire blockchain ledger
router.get('/ledger/verify', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const chain = db.ledger_blocks;

  let isValid = true;
  let corruptedBlockIndex = null;
  let reason = null;

  for (let i = 0; i < chain.length; i++) {
    const block = chain[i];

    // Check prev_hash link
    if (i > 0) {
      const prevBlock = chain[i - 1];
      if (block.prev_hash !== prevBlock.hash) {
        isValid = false;
        corruptedBlockIndex = block.idx;
        reason = `Hash rantai terputus pada block #${block.idx}: prev_hash tidak cocok dengan block #${prevBlock.idx}`;
        break;
      }
    }

    // Recalculate hash
    const expectedHash = calculateBlockHash(block.idx, block.waktu, block.payment_id, block.nominal_idr, block.prev_hash);
    if (block.hash !== expectedHash) {
      isValid = false;
      corruptedBlockIndex = block.idx;
      reason = `Integritas block #${block.idx} rusak: hash tercatat berbeda dengan hash kalkulasi SHA-256`;
      break;
    }
  }

  return res.json({
    success: true,
    is_valid: isValid,
    total_blocks: chain.length,
    corrupted_index: corruptedBlockIndex,
    message: isValid
      ? `Seluruh rantai (${chain.length} block) 100% valid dan terverifikasi secara kriptografis SHA-256.`
      : reason
  });
});

module.exports = router;
