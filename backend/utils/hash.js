const crypto = require('crypto');

function calculateBlockHash(idx, waktu, payment_id, nominal_idr, prev_hash) {
  const content = `${idx}|${waktu}|${payment_id}|${nominal_idr}|${prev_hash}`;
  return crypto.createHash('sha256').update(content).digest('hex');
}

module.exports = {
  calculateBlockHash
};
