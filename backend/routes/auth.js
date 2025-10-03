const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');
const { getDatabase } = require('../database/init');
const { sendPasswordResetEmail, sendVerificationEmail } = require('../utils/email');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
const db = getDatabase();

// Validation schemas
const registerSchema = Joi.object({
  email: Joi.string().email().required().max(255),
  password: Joi.string().min(8).max(128).required(),
  name: Joi.string().min(2).max(100).required()
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required()
});

const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  newPassword: Joi.string().min(8).max(128).required()
});

// Helper functions
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId, type: 'access' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
  );
  
  const refreshToken = jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '90d' }
  );
  
  return { accessToken, refreshToken };
};

const createSession = (userId, tokens, deviceInfo, ipAddress) => {
  return new Promise((resolve, reject) => {
    const sessionId = uuidv4();
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
    const refreshExpiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 90 days
    
    db.run(
      `INSERT INTO user_sessions (id, user_id, token, refresh_token, device_info, ip_address, expires_at, refresh_expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [sessionId, userId, tokens.accessToken, tokens.refreshToken, deviceInfo, ipAddress, expiresAt, refreshExpiresAt],
      function(err) {
        if (err) reject(err);
        else resolve({ sessionId, ...tokens });
      }
    );
  });
};

// Routes

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    const { email, password, name } = value;
    const emailLower = email.toLowerCase();

    // Check if user already exists
    const existingUser = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM users WHERE email = ?', [emailLower], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists'
      });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const userId = uuidv4();
    const userProfileId = uuidv4();

    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)',
        [userId, emailLower, passwordHash, name],
        function(err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Create user profile
    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO user_profiles (id, user_id, name) VALUES (?, ?, ?)',
        [userProfileId, userId, name],
        function(err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Generate tokens and create session
    const tokens = generateTokens(userId);
    const deviceInfo = req.headers['user-agent'] || 'Unknown Device';
    const ipAddress = req.ip || req.connection.remoteAddress;
    
    await createSession(userId, tokens, deviceInfo, ipAddress);

    // Send verification email (optional)
    try {
      await sendVerificationEmail(emailLower, tokens.accessToken);
    } catch (emailError) {
      console.warn('Failed to send verification email:', emailError.message);
    }

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        user: {
          id: userId,
          email: emailLower,
          name: name,
          isEmailVerified: false
        },
        tokens
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed. Please try again.'
    });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    const { email, password } = value;
    const emailLower = email.toLowerCase();

    // Find user
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, email, password_hash, name, is_account_active FROM users WHERE email = ?',
        [emailLower],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user || !user.is_account_active) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Update last login
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?',
        [user.id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Generate tokens and create session
    const tokens = generateTokens(user.id);
    const deviceInfo = req.headers['user-agent'] || 'Unknown Device';
    const ipAddress = req.ip || req.connection.remoteAddress;
    
    await createSession(user.id, tokens, deviceInfo, ipAddress);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        },
        tokens
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed. Please try again.'
    });
  }
});

// POST /api/auth/logout
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    // Deactivate session
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE user_sessions SET is_active = 0 WHERE token = ?',
        [token],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Logged out successfully'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Logout failed'
    });
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    
    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    // Check if session exists and is active
    const session = await new Promise((resolve, reject) => {
      db.get(
        `SELECT user_id, refresh_expires_at FROM user_sessions 
         WHERE refresh_token = ? AND is_active = 1 AND refresh_expires_at > datetime('now')`,
        [refreshToken],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!session) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token'
      });
    }

    // Generate new tokens
    const tokens = generateTokens(session.user_id);
    
    // Update session with new tokens
    await new Promise((resolve, reject) => {
      const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
      const refreshExpiresAt = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000); // 90 days
      
      db.run(
        'UPDATE user_sessions SET token = ?, refresh_token = ?, expires_at = ?, refresh_expires_at = ? WHERE refresh_token = ?',
        [tokens.accessToken, tokens.refreshToken, expiresAt, refreshExpiresAt, refreshToken],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: { tokens }
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token'
    });
  }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
  try {
    const { error, value } = forgotPasswordSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    const { email } = value;
    const emailLower = email.toLowerCase();

    // Find user
    const user = await new Promise((resolve, reject) => {
      db.get('SELECT id, name FROM users WHERE email = ? AND is_account_active = 1', [emailLower], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    // Always return success to prevent email enumeration
    if (!user) {
      return res.json({
        success: true,
        message: 'If an account with that email exists, a password reset link has been sent.'
      });
    }

    // Generate reset token
    const resetToken = uuidv4();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await new Promise((resolve, reject) => {
      db.run(
        'INSERT INTO password_reset_tokens (id, user_id, token, expires_at) VALUES (?, ?, ?, ?)',
        [uuidv4(), user.id, resetToken, expiresAt],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Send reset email
    try {
      await sendPasswordResetEmail(emailLower, resetToken, user.name);
    } catch (emailError) {
      console.warn('Failed to send password reset email:', emailError.message);
    }

    res.json({
      success: true,
      message: 'If an account with that email exists, a password reset link has been sent.'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process password reset request'
    });
  }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req, res) => {
  try {
    const { error, value } = resetPasswordSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    const { token, newPassword } = value;

    // Find valid reset token
    const resetToken = await new Promise((resolve, reject) => {
      db.get(
        `SELECT rt.user_id, rt.expires_at FROM password_reset_tokens rt
         JOIN users u ON rt.user_id = u.id
         WHERE rt.token = ? AND rt.is_used = 0 AND rt.expires_at > datetime('now') AND u.is_account_active = 1`,
        [token],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!resetToken) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token'
      });
    }

    // Hash new password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password and mark token as used
    await new Promise((resolve, reject) => {
      db.serialize(() => {
        db.run('UPDATE users SET password_hash = ? WHERE id = ?', [passwordHash, resetToken.user_id]);
        db.run('UPDATE password_reset_tokens SET is_used = 1 WHERE token = ?', [token], (err) => {
          if (err) reject(err);
          else resolve();
        });
      });
    });

    // Invalidate all existing sessions
    await new Promise((resolve, reject) => {
      db.run('UPDATE user_sessions SET is_active = 0 WHERE user_id = ?', [resetToken.user_id], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    res.json({
      success: true,
      message: 'Password reset successfully. Please log in with your new password.'
    });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reset password'
    });
  }
});

module.exports = router;
