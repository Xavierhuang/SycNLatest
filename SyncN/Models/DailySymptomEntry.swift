import Foundation
import SwiftData

@Model
class DailySymptomEntry {
    var id: UUID
    var date: Date
    var headacheSeverity: SymptomSeverity?
    var kneeInjurySeverity: SymptomSeverity?
    var notes: String?
    var selectedBleed: String?
    var selectedMood: String?
    var selectedEnergy: String?
    var selectedPhysicalSymptoms: [String]?
    var selectedDischarge: String?
    var currentInjuriesString: String? // JSON string of current injuries with severity
    var createdAt: Date
    
    init(date: Date, headacheSeverity: SymptomSeverity? = nil, kneeInjurySeverity: SymptomSeverity? = nil, notes: String? = nil, selectedBleed: String? = nil, selectedMood: String? = nil, selectedEnergy: String? = nil, selectedPhysicalSymptoms: [String]? = nil, selectedDischarge: String? = nil, currentInjuriesString: String? = nil) {
        self.id = UUID()
        self.date = date
        self.headacheSeverity = headacheSeverity
        self.kneeInjurySeverity = kneeInjurySeverity
        self.notes = notes
        self.selectedBleed = selectedBleed
        self.selectedMood = selectedMood
        self.selectedEnergy = selectedEnergy
        self.selectedPhysicalSymptoms = selectedPhysicalSymptoms
        self.selectedDischarge = selectedDischarge
        self.currentInjuriesString = currentInjuriesString
        self.createdAt = Date()
    }
    
    // MARK: - Current Injuries
    var currentInjuries: [InjuryEntry] {
        get {
            guard let data = currentInjuriesString?.data(using: .utf8) else { return [] }
            do {
                return try JSONDecoder().decode([InjuryEntry].self, from: data)
            } catch {
                print("❌ Failed to decode current injuries: \(error)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                currentInjuriesString = String(data: data, encoding: .utf8)
            } catch {
                print("❌ Failed to encode current injuries: \(error)")
                currentInjuriesString = nil
            }
        }
    }
}

enum SymptomSeverity: String, CaseIterable, Codable {
    case none = "None"
    case mild = "Mild"
    case severe = "Severe"
}
