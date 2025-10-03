const express = require('express');
const Joi = require('joi');
const { getDatabase } = require('../database/init');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
const db = getDatabase();

// GET /api/user/profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await new Promise((resolve, reject) => {
      db.get(
        `SELECT u.id, u.email, u.name, u.is_email_verified, u.created_at, u.last_login_at,
                up.birth_date, up.cycle_length, up.last_period_start, up.average_period_length,
                up.fitness_level, up.goals, up.cycle_type, up.cycle_flow,
                up.has_recurring_symptoms, up.last_symptoms_start, up.average_symptom_days
         FROM users u
         LEFT JOIN user_profiles up ON u.id = up.user_id
         WHERE u.id = ?`,
        [userId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          isEmailVerified: user.is_email_verified,
          createdAt: user.created_at,
          lastLoginAt: user.last_login_at,
          profile: {
            birthDate: user.birth_date,
            cycleLength: user.cycle_length,
            lastPeriodStart: user.last_period_start,
            averagePeriodLength: user.average_period_length,
            fitnessLevel: user.fitness_level,
            goals: user.goals ? JSON.parse(user.goals) : [],
            cycleType: user.cycle_type,
            cycleFlow: user.cycle_flow,
            hasRecurringSymptoms: user.has_recurring_symptoms,
            lastSymptomsStart: user.last_symptoms_start,
            averageSymptomDays: user.average_symptom_days
          }
        }
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user profile'
    });
  }
});

// PUT /api/user/profile
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email } = req.body;

    const updateSchema = Joi.object({
      name: Joi.string().min(2).max(100).optional(),
      email: Joi.string().email().max(255).optional()
    });

    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    const updates = [];
    const values = [];

    if (value.name) {
      updates.push('name = ?');
      values.push(value.name);
    }

    if (value.email) {
      const emailLower = value.email.toLowerCase();
      
      // Check if email is already taken by another user
      const existingUser = await new Promise((resolve, reject) => {
        db.get('SELECT id FROM users WHERE email = ? AND id != ?', [emailLower, userId], (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });

      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'Email is already taken by another account'
        });
      }

      updates.push('email = ?, is_email_verified = 0');
      values.push(emailLower);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    values.push(userId);

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
        values,
        function(err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Profile updated successfully'
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile'
    });
  }
});

// POST /api/user/sync-data
router.post('/sync-data', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { dataType, dataJson } = req.body;

    const syncSchema = Joi.object({
      dataType: Joi.string().required(),
      dataJson: Joi.string().required()
    });

    const { error, value } = syncSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    // Check if data already exists
    const existingData = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id FROM user_data_sync WHERE user_id = ? AND data_type = ?',
        [userId, value.dataType],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (existingData) {
      // Update existing data
      await new Promise((resolve, reject) => {
        db.run(
          'UPDATE user_data_sync SET data_json = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ? AND data_type = ?',
          [value.dataJson, userId, value.dataType],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } else {
      // Create new data
      await new Promise((resolve, reject) => {
        db.run(
          'INSERT INTO user_data_sync (id, user_id, data_type, data_json) VALUES (?, ?, ?, ?)',
          [require('uuid').v4(), userId, value.dataType, value.dataJson],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    res.json({
      success: true,
      message: 'Data synced successfully'
    });

  } catch (error) {
    console.error('Sync data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync data'
    });
  }
});

// GET /api/user/sync-data
router.get('/sync-data', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { dataType } = req.query;

    let query = 'SELECT data_type, data_json, last_synced_at FROM user_data_sync WHERE user_id = ?';
    let params = [userId];

    if (dataType) {
      query += ' AND data_type = ?';
      params.push(dataType);
    }

    const data = await new Promise((resolve, reject) => {
      db.all(query, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });

    const result = {};
    data.forEach(row => {
      result[row.data_type] = {
        data: JSON.parse(row.data_json),
        lastSyncedAt: row.last_synced_at
      };
    });

    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    console.error('Get sync data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch sync data'
    });
  }
});

module.exports = router;
