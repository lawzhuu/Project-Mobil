// ==============================================================================
// PANDUAN PEMULA: MODUL BLOCKCHAIN LEDGER AUDIT (TRANSPARANSI KEUANGAN ISP)
// ==============================================================================
// Blockchain adalah buku besar digital (distributed ledger) yang tidak dapat diubah (Immutable):
// 1. GET /ledger       : Mengambil seluruh riwayat blok pembayaran yang telah diverifikasi.
// 2. GET /ledger/verify: Melakukan audit menyeluruh terhadap rantai blok secara matematis:
//    - Linkage Test    : Memeriksa apakah `prev_hash` blok N identik dengan `hash` blok N-1.
//    - Digest Recalc   : Menghitung ulang SHA-256 dari data mentah blok tersebut.
//      Jika ada hacker yang mengubah Rp 275.000 menjadi Rp 50.000 di database,
//      audit scan langsung menemukan ketidakcocokan (Tamper Detected).
// ==============================================================================

const express = require('express');
const { loadDB } = require('../db');
const { calculateBlockHash } = require('../utils/hash');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

const router = express.Router();

// 1. ENDPOINT MENGAMBIL SELURUH BLOK BLOCKCHAIN (GET /ledger - Khusus Admin)
router.get('/ledger', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  return res.json({ success: true, ledger: db.ledger_blocks });
});

// 2. ENDPOINT AUDIT & VERIFIKASI INTEGRITAS KRIPTOGRAFI RANTAI BLOK (GET /ledger/verify)
router.get('/ledger/verify', authMiddleware, roleMiddleware(['admin']), (req, res) => {
  const db = loadDB();
  const chain = db.ledger_blocks;

  let isValid = true;
  let corruptedBlockIndex = null;
  let reason = null;

  for (let i = 0; i < chain.length; i++) {
    const block = chain[i];

    // Tes 1: Pemeriksaan sambungan rantai (prev_hash)
    if (i > 0) {
      const prevBlock = chain[i - 1];
      if (block.prev_hash !== prevBlock.hash) {
        isValid = false;
        corruptedBlockIndex = block.idx;
        reason = `Hash rantai terputus pada block #${block.idx}: prev_hash tidak cocok dengan block #${prevBlock.idx}`;
        break;
      }
    }

    // Tes 2: Perhitungan ulang hash SHA-256 (Anti-manipulasi data)
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
