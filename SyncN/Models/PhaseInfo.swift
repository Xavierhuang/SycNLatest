import Foundation

// MARK: - Phase Information Model
struct PhaseInfo: Identifiable, Codable {
    let id: UUID
    let name: String
    let affirmation: String
    let energy: String
    let phase: String
    let phaseDurationDays: String
    let season: String
    let foodRec: [String]
    let tips: String
    let bodyFeel: [String]
    let emotions: [String]
    let hormones: [String]
    let intensity: String
    let movementDescription: String
    let movementRec: String
    let mediaVideo: String
    
    init(name: String, affirmation: String, energy: String, phase: String, phaseDurationDays: String, season: String, foodRec: [String], tips: String, bodyFeel: [String], emotions: [String], hormones: [String], intensity: String, movementDescription: String, movementRec: String, mediaVideo: String) {
        self.id = UUID()
        self.name = name
        self.affirmation = affirmation
        self.energy = energy
        self.phase = phase
        self.phaseDurationDays = phaseDurationDays
        self.season = season
        self.foodRec = foodRec
        self.tips = tips
        self.bodyFeel = bodyFeel
        self.emotions = emotions
        self.hormones = hormones
        self.intensity = intensity
        self.movementDescription = movementDescription
        self.movementRec = movementRec
        self.mediaVideo = mediaVideo
    }
}

// MARK: - Phase Info Data
class PhaseInfoData {
    static let shared = PhaseInfoData()
    
    private init() {}
    
    func getAllPhases() -> [PhaseInfo] {
        return [
            PhaseInfo(
                name: "luteal",
                affirmation: "I love and approve of my body",
                energy: "decreasing energy",
                phase: "luteal",
                phaseDurationDays: "14 days",
                season: "fall",
                foodRec: ["Complex carbohydrates (whole grains,legumes)", "Lemon water (to minimize cramps)"],
                tips: "",
                bodyFeel: ["High strength,increased soreness,delayed recovery,may feel winded more easily,bloating,increased cravings"],
                emotions: ["Lower sense of confidence and motivation to workout (especially at end of phase)", "feeling 'down'", "mood swings"],
                hormones: ["Progesterone increases and works with estrogen to maintain the uterine lining"],
                intensity: "Moderate - Low intensity",
                movementDescription: "Your body is strong, yet it doesn't need your heart rate to be pushed too much during this time",
                movementRec: "",
                mediaVideo: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Phase.mp4"
            ),
            PhaseInfo(
                name: "follicular",
                affirmation: "I am worthy.",
                energy: "increasing energy",
                phase: "follicular",
                phaseDurationDays: "10-14 days",
                season: "spring",
                foodRec: ["nutrient rich foods (fruits,veggies,whole grains)", "omega-3 fatty acids (fatty fish,flaxseeds)"],
                tips: "thing",
                bodyFeel: ["less pain sensitivity", "capable of higher volume"],
                emotions: ["optimistic", "more social", "ideas flowing"],
                hormones: ["estrogen increases", "FSH increases to develop the follicles"],
                intensity: "Moderate - High intensity",
                movementDescription: "great time to engage in more rigorous physical activies as your body's strength and endurance are on the upswing",
                movementRec: "",
                mediaVideo: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20Phase.mp4"
            ),
            PhaseInfo(
                name: "ovulation",
                affirmation: "I am powerful",
                energy: "outwards energy",
                phase: "ovulation",
                phaseDurationDays: "2-3 days",
                season: "summer",
                foodRec: ["Antioxidant-Rich foods (berries,broccoli,potatoes,avocados,leafy greens)", "protein", "Vitamin D foods (salmon,milk,eggs,spinach,kale)"],
                tips: "Be sure you are drinking enough water and eating enough during this phase, in addition to support the higher intensity workouts you might be during at this time.",
                bodyFeel: ["rise in body temperature (reduce heat tolerance)", "high strength"],
                emotions: ["positive", "social"],
                hormones: ["Estrogen and FSH put the final touches to mature the egg", "LH levels increase with helps trigger the release of the egg from the ovaries"],
                intensity: "Moderate - High intensity",
                movementDescription: "Add more stretching as you need more ligament laxity Great time to workout with a friend or do a group workout class",
                movementRec: "",
                mediaVideo: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Ovulation%20Phase.mp4"
            ),
            PhaseInfo(
                name: "menstrual",
                affirmation: "I surrender. I am willing to let go.",
                energy: "inward energy",
                phase: "menstrual",
                phaseDurationDays: "4-7 days",
                season: "winter",
                foodRec: ["lemon juice (minimizes cramping)", "water", "Iron-rich foods (lean beef,turkey,beans,spinach)"],
                tips: "thing",
                bodyFeel: ["quicker to fatigue", ""],
                emotions: ["emotional rollercoaster", "irritable"],
                hormones: ["Majority of females hormones are low"],
                intensity: "Low intensity",
                movementDescription: "This is a great time to go slow, listen to yourself",
                movementRec: "",
                mediaVideo: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstrual%20Phase%20Video.mp4"
            )
        ]
    }
    
    func getPhase(by name: String) -> PhaseInfo? {
        return getAllPhases().first { $0.name.lowercased() == name.lowercased() }
    }
}
