const jwt = require('jsonwebtoken');
const { getDatabase } = require('../database/init');

const db = getDatabase();

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    if (decoded.type !== 'access') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    // Check if session exists and is active
    const session = await new Promise((resolve, reject) => {
      db.get(
        `SELECT s.user_id, s.expires_at, u.is_account_active 
         FROM user_sessions s
         JOIN users u ON s.user_id = u.id
         WHERE s.token = ? AND s.is_active = 1 AND s.expires_at > datetime('now')`,
        [token],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!session) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired session'
      });
    }

    if (!session.is_account_active) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Add user info to request
    req.user = {
      id: session.user_id
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error'
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      req.user = null;
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    if (decoded.type !== 'access') {
      req.user = null;
      return next();
    }

    const session = await new Promise((resolve, reject) => {
      db.get(
        `SELECT s.user_id, s.expires_at, u.is_account_active 
         FROM user_sessions s
         JOIN users u ON s.user_id = u.id
         WHERE s.token = ? AND s.is_active = 1 AND s.expires_at > datetime('now')`,
        [token],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (session && session.is_account_active) {
      req.user = { id: session.user_id };
    } else {
      req.user = null;
    }

    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

module.exports = {
  authenticateToken,
  optionalAuth
};
