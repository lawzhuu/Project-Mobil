const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config');

// Authentication middleware verifying JWT token
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'Token otentikasi tidak disediakan' });
  }
  const token = authHeader.replace(/^Bearer\s+/i, '');
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
}

// Role-based access control middleware
function roleMiddleware(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Akses ditolak: role tidak memiliki izin' });
    }
    next();
  };
}

module.exports = {
  authMiddleware,
  roleMiddleware
};
