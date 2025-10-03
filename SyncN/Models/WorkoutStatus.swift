import Foundation
import SwiftUI

enum WorkoutStatus: String, Codable, CaseIterable {
    case suggested
    case scheduled
    case completed
    case skipped
    case confirmed
    
    var color: Color {
        switch self {
        case .suggested:
            return .blue
        case .scheduled:
            return .orange
        case .completed:
            return .green
        case .skipped:
            return .red
        case .confirmed:
            return .purple
        }
    }
}