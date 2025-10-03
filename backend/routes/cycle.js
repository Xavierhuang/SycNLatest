const express = require('express');
const Joi = require('joi');
const { getDatabase } = require('../database/init');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
const db = getDatabase();

// POST /api/cycle/predictions
router.post('/predictions', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { cycleLength, lastPeriodStart, averagePeriodLength, cycleType, hasRecurringSymptoms } = req.body;

    const predictionSchema = Joi.object({
      cycleLength: Joi.number().integer().min(20).max(40).optional(),
      lastPeriodStart: Joi.date().optional(),
      averagePeriodLength: Joi.number().integer().min(1).max(10).optional(),
      cycleType: Joi.string().valid('regular', 'irregular', 'no_period', 'symptomatic').optional(),
      hasRecurringSymptoms: Joi.boolean().optional()
    });

    const { error, value } = predictionSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => detail.message)
      });
    }

    // Update user profile with cycle data
    if (Object.keys(value).length > 0) {
      const updates = [];
      const updateValues = [];

      Object.entries(value).forEach(([key, val]) => {
        if (val !== undefined) {
          updates.push(`${key} = ?`);
          updateValues.push(val);
        }
      });

      if (updates.length > 0) {
        updateValues.push(userId);
        
        await new Promise((resolve, reject) => {
          db.run(
            `UPDATE user_profiles SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?`,
            updateValues,
            (err) => {
              if (err) reject(err);
              else resolve();
            }
          );
        });
      }
    }

    // Generate cycle predictions (simplified version)
    const predictions = generateCyclePredictions(value);

    res.json({
      success: true,
      data: {
        predictions: predictions.map(date => date.toISOString()),
        cycleInfo: {
          cycleLength: value.cycleLength || 28,
          lastPeriodStart: value.lastPeriodStart,
          averagePeriodLength: value.averagePeriodLength || 5,
          cycleType: value.cycleType || 'regular'
        }
      }
    });

  } catch (error) {
    console.error('Cycle predictions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate cycle predictions'
    });
  }
});

// GET /api/cycle/phases
router.get('/phases', authenticateToken, async (req, res) => {
  try {
    const { date } = req.query;
    
    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Date parameter is required'
      });
    }

    const queryDate = new Date(date);
    if (isNaN(queryDate.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid date format'
      });
    }

    // Get user's cycle data
    const userId = req.user.id;
    const userProfile = await new Promise((resolve, reject) => {
      db.get(
        'SELECT cycle_length, last_period_start, average_period_length, cycle_type FROM user_profiles WHERE user_id = ?',
        [userId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!userProfile) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found'
      });
    }

    // Calculate cycle phase for the given date
    const phaseInfo = calculateCyclePhase(queryDate, userProfile);

    res.json({
      success: true,
      data: {
        date: queryDate.toISOString(),
        phase: phaseInfo.phase,
        day: phaseInfo.day,
        description: phaseInfo.description,
        recommendations: phaseInfo.recommendations
      }
    });

  } catch (error) {
    console.error('Cycle phases error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate cycle phase'
    });
  }
});

// Helper functions
function generateCyclePredictions(cycleData) {
  const predictions = [];
  const cycleLength = cycleData.cycleLength || 28;
  const lastPeriodStart = cycleData.lastPeriodStart ? new Date(cycleData.lastPeriodStart) : new Date();
  
  // Generate predictions for the next 6 cycles
  for (let i = 1; i <= 6; i++) {
    const nextPeriodStart = new Date(lastPeriodStart);
    nextPeriodStart.setDate(nextPeriodStart.getDate() + (cycleLength * i));
    predictions.push(nextPeriodStart);
  }
  
  return predictions;
}

function calculateCyclePhase(date, userProfile) {
  const cycleLength = userProfile.cycle_length || 28;
  const lastPeriodStart = userProfile.last_period_start ? new Date(userProfile.last_period_start) : new Date();
  
  // Calculate days since last period
  const daysDiff = Math.floor((date - lastPeriodStart) / (1000 * 60 * 60 * 24));
  const cycleDay = ((daysDiff % cycleLength) + cycleLength) % cycleLength;
  
  let phase, description, recommendations;
  
  if (cycleDay >= 0 && cycleDay <= 5) {
    phase = 'menstrual';
    description = 'Menstrual Phase - Focus on gentle movement and recovery';
    recommendations = ['Yoga', 'Walking', 'Stretching', 'Rest'];
  } else if (cycleDay >= 6 && cycleDay <= 14) {
    phase = 'follicular';
    description = 'Follicular Phase - Great time for building strength and endurance';
    recommendations = ['Strength Training', 'Cardio', 'HIIT', 'High-intensity workouts'];
  } else if (cycleDay >= 15 && cycleDay <= 16) {
    phase = 'ovulatory';
    description = 'Ovulatory Phase - Peak performance time';
    recommendations = ['High-intensity training', 'Sports', 'Dance', 'Challenging workouts'];
  } else {
    phase = 'luteal';
    description = 'Luteal Phase - Moderate exercise with stress management';
    recommendations = ['Moderate cardio', 'Pilates', 'Mindfulness', 'Stress-relief activities'];
  }
  
  return {
    phase,
    day: cycleDay,
    description,
    recommendations
  };
}

module.exports = router;
