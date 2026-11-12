// ==============================================================================
// PANDUAN PEMULA: MIDDLEWARE KEAMANAN (JWT AUTH & ROLE-BASED ACCESS CONTROL)
// ==============================================================================
// Middleware adalah fungsi penjaga gerbang yang dieksekusi sebelum request mencapai controller.
// 1. authMiddleware:
//    - Memeriksa header HTTP: `Authorization: Bearer <token_jwt>`.
//    - Memverifikasi keaslian tanda tangan token dengan `jwt.verify(token, JWT_SECRET)`.
//    - Jika valid, payload token (id, email, role, nama) ditempelkan ke objek `req.user`.
//    - Jika tidak ada / expired, server mengembalikan status code 401 Unauthorized.
//
// 2. roleMiddleware(allowedRoles):
//    - Memeriksa apakah `req.user.role` termasuk dalam role yang diizinkan (misal ['admin']).
//    - Jika tidak berhak, server mengembalikan status code 403 Forbidden.
// ==============================================================================

const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config');

// Middleware otentikasi verifikasi token JWT
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'Token otentikasi tidak disediakan' });
  }
  // Menghapus prefix "Bearer " dari header jika ada
  const token = authHeader.replace(/^Bearer\s+/i, '');
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // Tempelkan data user ke request untuk dipakai di endpoint berikutnya
    next(); // Lanjutkan ke middleware atau handler route berikutnya
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
}

// Middleware otorisasi berbasis hak akses peran pengguna (RBAC)
function roleMiddleware(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Akses ditolak: role tidak memiliki izin' });
    }
    next(); // Lanjutkan jika role diizinkan
  };
}

module.exports = {
  authMiddleware,
  roleMiddleware
};
