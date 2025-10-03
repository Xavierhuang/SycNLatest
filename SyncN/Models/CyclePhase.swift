import Foundation
import SwiftUI

enum CyclePhase: String, CaseIterable, Codable {
    case menstrual = "Menstrual"
    case follicular = "Follicular"
    case ovulatory = "Ovulatory"
    case luteal = "Luteal"
    case menstrualMoon = "Menstrual Moon"
    case follicularMoon = "Follicular Moon"
    case ovulatoryMoon = "Ovulatory Moon"
    case lutealMoon = "Luteal Moon"
    
    var displayName: String {
        switch self {
        case .menstrual:
            return "Menstrual"
        case .follicular:
            return "Follicular"
        case .ovulatory:
            return "Ovulatory"
        case .luteal:
            return "Luteal"
        case .menstrualMoon:
            return "Menstrual Moon"
        case .follicularMoon:
            return "Follicular Moon"
        case .ovulatoryMoon:
            return "Ovulatory Moon"
        case .lutealMoon:
            return "Luteal Moon"
        }
    }
    
    var description: String {
        switch self {
        case .menstrual:
            return "Focus on gentle movement and recovery"
        case .follicular:
            return "Perfect time for building strength and endurance"
        case .ovulatory:
            return "Peak energy for high-intensity workouts"
        case .luteal:
            return "Moderate exercise with stress management"
        case .menstrualMoon:
            return "Focus on gentle movement and recovery"
        case .follicularMoon:
            return "Perfect time for building strength and endurance"
        case .ovulatoryMoon:
            return "Peak energy for high-intensity workouts"
        case .lutealMoon:
            return "Moderate exercise with stress management"
        }
    }
    
    var fitnessFocus: String {
        switch self {
        case .menstrual:
            return "Gentle yoga, walking, stretching"
        case .follicular:
            return "Strength training, cardio, HIIT"
        case .ovulatory:
            return "High-intensity workouts, sports, dance"
        case .luteal:
            return "Moderate cardio, pilates, mindfulness"
        case .menstrualMoon:
            return "Gentle yoga, walking, stretching"
        case .follicularMoon:
            return "Strength training, cardio, HIIT"
        case .ovulatoryMoon:
            return "High-intensity workouts, sports, dance"
        case .lutealMoon:
            return "Moderate cardio, pilates, mindfulness"
        }
    }
    
    var color: Color {
        switch self {
        case .menstrual: return .red
        case .follicular: return .green
        case .ovulatory: return .orange
        case .luteal: return .purple
        case .menstrualMoon: return .red
        case .follicularMoon: return .green
        case .ovulatoryMoon: return .orange
        case .lutealMoon: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .menstrual: return "Menstrual Icon" // Custom menstrual icon
        case .follicular: return "Follicular Icon" // Custom follicular icon
        case .ovulatory: return "Ovulation Icon" // Custom ovulatory icon
        case .luteal: return "Luteal Icon" // Custom luteal icon
        case .menstrualMoon: return "Menstrual Moon Icon"
        case .follicularMoon: return "Follicular Moon Icon"
        case .ovulatoryMoon: return "Ovulatory Moon Icon"
        case .lutealMoon: return "Luteal Moon Icon"
        }
    }
    
    // SF Symbol fallback icons
    var systemIcon: String {
        switch self {
        case .menstrual: return "drop.fill"
        case .follicular: return "leaf.fill"
        case .ovulatory: return "sun.max.fill"
        case .luteal: return "moon.fill"
        case .menstrualMoon: return "drop.circle"
        case .follicularMoon: return "leaf.circle"
        case .ovulatoryMoon: return "sun.max.circle"
        case .lutealMoon: return "moon.circle"
        }
    }
    
    var frameImage: String {
        switch self {
        case .menstrual: return "menstrual frame" // Menstrual frame image
        case .follicular: return "follicular frame" // Follicular frame image
        case .ovulatory: return "ovulation frame" // Ovulatory frame image
        case .luteal: return "luteal frame" // Luteal frame image
        case .menstrualMoon: return "menstrual moon frame"
        case .follicularMoon: return "follicular moon frame"
        case .ovulatoryMoon: return "ovulatory moon frame"
        case .lutealMoon: return "luteal moon frame"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .menstrual:
            return [
                Color(red: 0.894, green: 0.843, blue: 0.953), // #E4D7F3
                Color(red: 0.961, green: 0.961, blue: 0.941)  // #F5F5F0
            ]
        case .follicular:
            return [
                Color(red: 0.380, green: 0.859, blue: 0.984), // #61DBFB
                Color(red: 0.420, green: 0.835, blue: 0.694)  // #6BD5B1
            ]
        case .ovulatory:
            return [
                Color(red: 0.608, green: 0.431, blue: 0.953), // #9B6EF3
                Color(red: 0.925, green: 0.286, blue: 0.600)  // #EC4899
            ]
        case .luteal:
            return [
                Color(red: 0.976, green: 0.451, blue: 0.086), // #F97316
                Color(red: 0.910, green: 0.788, blue: 0.627)  // #E8C9A0
            ]
        case .menstrualMoon, .follicularMoon, .ovulatoryMoon, .lutealMoon:
            return [
                Color(red: 0.894, green: 0.843, blue: 0.953), // #E4D7F3
                Color(red: 0.961, green: 0.961, blue: 0.941)  // #F5F5F0
            ]
        }
    }
    
    var headerColor: Color {
        switch self {
        case .menstrual:
            return Color(red: 0.957, green: 0.408, blue: 0.573) // #F46892 - Pink
        case .follicular:
            return Color(red: 0.976, green: 0.851, blue: 0.157) // #F9D928 - Yellow
        case .ovulatory:
            return Color(red: 0.157, green: 0.851, blue: 0.851) // #28D9D9 - Teal
        case .luteal:
            return Color(red: 0.557, green: 0.671, blue: 0.557) // #8EAB8E - Sage green
        case .menstrualMoon, .follicularMoon, .ovulatoryMoon, .lutealMoon:
            return Color(red: 0.957, green: 0.408, blue: 0.573) // #F46892 - Pink
        }
    }
    
    var isMoonBased: Bool {
        switch self {
        case .menstrualMoon, .follicularMoon, .ovulatoryMoon, .lutealMoon:
            return true
        default:
            return false
        }
    }
}