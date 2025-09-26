import Foundation

// MARK: - Fitness Class Model
struct FitnessClassData: Codable, Identifiable {
    let id: String
    let className: String
    let duration: String
    let phases: [String] // Cycle phases this class is suitable for
    let types: [String] // Workout types (e.g., "Strength", "Cardio", "Pilates")
    let instructor: String
    let intensity: String // "Low", "Mid", "High"
    let equipment: [String]?
    let benefits: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "__id__"
        case className = "Class_Name"
        case duration
        case phases = "phase"
        case types = "type"
        case instructor
        case intensity
        case equipment
        case benefits
    }
}

// MARK: - Fitness Classes Data Manager
class FitnessClassesManager {
    static let shared = FitnessClassesManager()
    
    private var fitnessClasses: [FitnessClassData] = []
    
    private init() {
        loadFitnessClasses()
        // Test the loading
        print("🔍 FitnessClassesManager: Total classes loaded: \(fitnessClasses.count)")
        if fitnessClasses.count > 0 {
            print("🔍 First class: \(fitnessClasses[0].className)")
        }
    }
    
    private func loadFitnessClasses() {
        // Load the embedded fitness classes data
        print("🔍 Attempting to load fitness_classes.json from bundle...")
        
        guard let url = Bundle.main.url(forResource: "fitness_classes", withExtension: "json") else {
            print("❌ Could not find fitness_classes.json in bundle")
            print("🔍 Bundle path: \(Bundle.main.bundlePath)")
            print("🔍 Bundle contents: \(String(describing: try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)))")
            return
        }
        
        print("✅ Found fitness_classes.json at: \(url.path)")
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Could not read data from fitness_classes.json")
            return
        }
        
        print("✅ Read \(data.count) bytes from fitness_classes.json")
        
        do {
            let classes = try JSONDecoder().decode([FitnessClassData].self, from: data)
            self.fitnessClasses = classes
            print("✅ Loaded \(classes.count) fitness classes from bundle")
            if classes.count > 0 {
                print("🔍 Sample class: \(classes[0].className) - \(classes[0].phases) - \(classes[0].types)")
            }
        } catch {
            print("❌ Could not decode fitness_classes.json: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("🔍 Missing key: \(key) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("🔍 Type mismatch for type: \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("🔍 Value not found for type: \(type) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("🔍 Data corrupted at path: \(context.codingPath)")
                @unknown default:
                    print("🔍 Unknown decoding error")
                }
            }
            print("🔍 JSON content preview: \(String(data: data.prefix(500), encoding: .utf8) ?? "Could not convert to string")")
            return
        }
    }
    
    func getAllClasses() -> [FitnessClassData] {
        return fitnessClasses
    }
    
    func getClassesForPhase(_ phase: String) -> [FitnessClassData] {
        // First, get classes specifically for this phase
        let phaseSpecificClasses = fitnessClasses.filter { fitnessClass in
            fitnessClass.phases.contains { $0.lowercased() == phase.lowercased() }
        }
        
        // If we have phase-specific classes, use only those
        if !phaseSpecificClasses.isEmpty {
            return phaseSpecificClasses
        }
        
        // Otherwise, fall back to "All" classes
        return fitnessClasses.filter { fitnessClass in
            fitnessClass.phases.contains { $0.lowercased() == "all" }
        }
    }
    
    func getClassesByType(_ type: String) -> [FitnessClassData] {
        return fitnessClasses.filter { fitnessClass in
            fitnessClass.types.contains { $0.lowercased() == type.lowercased() }
        }
    }
    
    func getClassesByIntensity(_ intensity: String) -> [FitnessClassData] {
        return fitnessClasses.filter { fitnessClass in
            fitnessClass.intensity.lowercased() == intensity.lowercased()
        }
    }
}
