# Fitness Plan Debug Guide

This guide explains how to use the new fitness plan debugging features to test and verify the 14-day fitness plan generation logic.

## Features Added

### 1. Automatic JSON Export
Every time a fitness plan is generated, it's automatically saved to a JSON file in the app's Documents directory with the following information:
- Complete 14-day plan with all workout details
- User profile data used for generation
- User preferences and settings
- Generation timestamp
- Cycle phase information for each day

### 2. Debug View
A dedicated debug view that allows you to:
- Generate new fitness plans with sample data
- View saved JSON files
- Load and inspect previous plans
- See detailed console output

### 3. Console Logging
Enhanced console output showing:
- Step-by-step filtering process
- Available classes at each stage
- Final plan summary with counts
- File save locations

## How to Access Debug Features

### Method 1: Debug View (Recommended)
1. Open the app and navigate to the **Profile** tab
2. **Triple-tap** on the "Profile" title at the top
3. The debug view will open as a sheet
4. Use the buttons to generate plans and view saved files

### Method 2: Console Output
1. Run the app in Xcode
2. Generate a fitness plan (through normal app usage)
3. Check the Xcode console for detailed logging
4. Look for messages starting with 🎯

## JSON File Structure

Each saved fitness plan JSON file contains:

```json
{
  "generatedAt": "2024-01-15T10:30:00Z",
  "startDate": "2024-01-15T00:00:00Z",
  "userProfile": {
    "cycleLength": 28,
    "lastPeriodStart": "2024-01-01T00:00:00Z",
    "cycleType": "regular",
    "currentCyclePhase": "follicular"
  },
  "userPreferences": {
    "fitnessLevel": "intermediate",
    "workoutFrequency": 4,
    "favoriteWorkouts": ["Strength", "Yoga"],
    "dislikedWorkouts": ["HIIT"],
    "preferredRestDays": ["Sunday"]
  },
  "plan": [
    {
      "date": "2024-01-15T00:00:00Z",
      "workoutTitle": "Strength",
      "duration": 21,
      "workoutType": "strength",
      "cyclePhase": "follicular",
      "difficulty": "intermediate"
    }
    // ... 13 more days
  ]
}
```

## File Locations

- **iOS Simulator**: `~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/`
- **Physical Device**: Use Xcode's Window > Devices and Simulators to access the Documents folder

## Testing Different Scenarios

### 1. Test Different User Preferences
Modify the `createSampleUserProfile()` function in `FitnessPlanDebugView.swift` to test:
- Different workout frequencies (2-6 days/week)
- Various favorite/disliked workouts
- Different fitness levels
- Various cycle phases

### 2. Test Cycle Phase Logic
- Change the `currentCyclePhase` in the sample profile
- Verify that appropriate classes are selected for each phase
- Check intensity filtering (menstrual=low, ovulation=high, etc.)

### 3. Test Class Filtering
- Add/remove classes from `fitness_classes.json`
- Test injury restrictions
- Verify meditation vs workout separation

## Common Issues to Check

### 1. No Classes Available
- Check if `fitness_classes.json` is loading properly
- Verify class phase assignments match cycle phases
- Ensure intensity values match filtering logic

### 2. Wrong Day Distribution
- Verify workout frequency parsing
- Check preferred rest day logic
- Ensure plan start choice is respected

### 3. Incorrect Phase Filtering
- Check cycle phase calculation logic
- Verify phase name matching (case sensitivity)
- Test both backend and fallback phase detection

## Console Output Examples

```
🎯 SwiftFitnessEngine: Loaded 20 fitness classes
🎯 Day type distribution: [0: workout, 1: rest, 2: workout, ...]
🎯 Day 0: 2024-01-15 - Day type: workout
🎯 Day 0: Current phase: follicular
🎯 Day 0: Found 8 classes for phase 'follicular' (excluding meditations)
🎯 Day 0: After preference filtering: 6 classes
🎯 Day 0: After injury filtering: 5 classes
🎯 Day 0: After intensity filtering: 4 classes
🎯 Selected workout by weighted random: Strength
🎯 Fitness plan saved to: /path/to/fitness_plan_2024-01-15_10-30-45.json
```

## Troubleshooting

### JSON Files Not Saving
- Check app permissions for Documents directory
- Verify file path is accessible
- Check console for error messages

### Debug View Not Opening
- Ensure you're triple-tapping the "Profile" title
- Check that the sheet presentation is working
- Verify the debug view is properly imported

### Plan Generation Failing
- Check if user profile data is complete
- Verify fitness classes are loaded
- Look for error messages in console

## Next Steps

1. Generate several test plans with different user preferences
2. Compare the JSON outputs to verify logic correctness
3. Test edge cases (very high/low workout frequencies, all classes disliked, etc.)
4. Verify cycle phase transitions work correctly
5. Check that meditation and workout separation is working

This debugging system should help you identify exactly where the fitness generation logic might be producing incorrect results.
