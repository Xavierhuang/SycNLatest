import Foundation

// MARK: - Notification Message Model
struct NotificationMessage: Identifiable, Codable {
    let id: UUID
    let header: String
    let body: String
    let phase: CyclePhase
    let category: String?
    
    init(header: String, body: String, phase: CyclePhase, category: String? = nil) {
        self.id = UUID()
        self.header = header
        self.body = body
        self.phase = phase
        self.category = category
    }
}

// MARK: - Notification Messages Data
struct NotificationMessagesData {
    static let allMessages: [NotificationMessage] = [
        // Follicular Phase
        NotificationMessage(
            header: "Nutrient-rich foods",
            body: "Want to enhance your follicular glow? Focus on colorful, nutrient-dense foods– like fruits, whole grains, and healthy fats– to fuel your rising energy levels and curb cravings.",
            phase: .follicular
        ),
        
        // Ovulation Phase
        NotificationMessage(
            header: "Anti-oxidant rich foods",
            body: "Looking to reduce cramps and inflammation? Try antioxidant-rich foods like berries, leafy greens, and dark chocolate today – they help protect egg quality and support reproductive wellbeing.",
            phase: .ovulatory,
            category: "Ovulation Phase Tips"
        ),
        
        NotificationMessage(
            header: "Protein",
            body: "Support muscle growth and keep cravings in check. Reach for protein-rich foods like lean meats, eggs, Greek yogurt, tofu, and beans to regulate blood sugar and help muscles recover.",
            phase: .ovulatory,
            category: "Ovulation Phase Tips"
        ),
        
        NotificationMessage(
            header: "Vitamin-D rich foods",
            body: "Looking to enahnce fertility during ovulation? Incorporate vitamin D rich foods into your meals like salmon, eggs, spinach, and fortified milk to support egg maturation and help regulate mood.",
            phase: .ovulatory,
            category: "Ovulation Phase Tips"
        ),
        
        NotificationMessage(
            header: "Extra hydration to support extra movement",
            body: "Feeling amazing? Boost your energy and performance with extra hydration and consider electrolytes if you sweat heavily during workouts. Let's stay hydrated!",
            phase: .ovulatory,
            category: "Ovulation Phase Tips"
        ),
        
        // Luteal Phase
        NotificationMessage(
            header: "Complex carbohydrates",
            body: "Steady blood sugar = better mood. Eat complex carbohydrates to sustain energy and stabilize blood sugar, easing mood and anxiety during luteal phase.",
            phase: .luteal,
            category: "Luteal Phase Tips"
        ),
        
        NotificationMessage(
            header: "Magnesium-rich foods",
            body: "Feeling tense, anxious or tired? Include magnesium-rich foods to calm muscles, reduce cramps, and support better sleep quality in your luteal phase. Nuts, quinoa, dark chocolate, leafy greens, and avocado will be your best friends!",
            phase: .luteal,
            category: "Luteal Phase Tips"
        ),
        
        // Menstrual Phase
        NotificationMessage(
            header: "Pass on processed, packaged snack bags",
            body: "Let's snack smarter this week! Processed snacks are often loaded with sodium and additives that can lead to bloating and water retention. Try fruits, vegetables, and nuts instead to feel lighter during your period and support healthy weight management.",
            phase: .menstrual,
            category: "Menstural Phase Tips"
        ),
        
        NotificationMessage(
            header: "Extra water",
            body: "Don't forget your water! Hydrate your body with extra water with week to boost energy, reduce bloating, and support weight regulation. Even mild dehydration can lead to headaches and fatigue.",
            phase: .menstrual,
            category: "Menstural Phase Tips"
        ),
        
        NotificationMessage(
            header: "Iron-rich foods",
            body: "Replenish & Recharge with Iron! Reach for iron-rich foods like lean beef, beans, spinach, and dried fruit to restore lost nutrients and fight period fatigue.",
            phase: .menstrual,
            category: "Menstural Phase Tips"
        ),
        
        // Follicular & Ovulation Phase
        NotificationMessage(
            header: "Eat enough to support extra movement",
            body: "Noursih & Elevate Yourself During Follicular and Ovulation Phases! As your energy and activity levels rise, slightly increase your portions. Fill your plate with whole, nutrient-dense foods to power through your workouts and reach optimal endurance levels. You've got this!",
            phase: .follicular,
            category: "Follicular & Ovulation Phase Tips"
        ),
        
        NotificationMessage(
            header: "Eat enough to support extra movement",
            body: "Noursih & Elevate Yourself During Follicular and Ovulation Phases! As your energy and activity levels rise, slightly increase your portions. Fill your plate with whole, nutrient-dense foods to power through your workouts and reach optimal endurance levels. You've got this!",
            phase: .ovulatory,
            category: "Follicular & Ovulation Phase Tips"
        ),
        
        // Luteal & Menstrual Phase
        NotificationMessage(
            header: "Reduce alcohol intake",
            body: "Thinking about your cycle health? Limiting alcohol intake can support hormone balance, aid with sleep, and ease PMS symptoms naturally",
            phase: .luteal,
            category: "Luteal & Menstural Phase Tips"
        ),
        
        NotificationMessage(
            header: "Reduce alcohol intake",
            body: "Thinking about your cycle health? Limiting alcohol intake can support hormone balance, aid with sleep, and ease PMS symptoms naturally",
            phase: .menstrual,
            category: "Luteal & Menstural Phase Tips"
        ),
        
        NotificationMessage(
            header: "Pass on fried foods",
            body: "Feeling off? Fried foods might be making it worse. Choose baked, grilled, or steamed options instead to ease inflammation and to support digestion and hormonal balance.",
            phase: .luteal,
            category: "Luteal & Menstural Phase Tips"
        ),
        
        NotificationMessage(
            header: "Pass on fried foods",
            body: "Feeling off? Fried foods might be making it worse. Choose baked, grilled, or steamed options instead to ease inflammation and to support digestion and hormonal balance.",
            phase: .menstrual,
            category: "Luteal & Menstural Phase Tips"
        ),
        
        // All Phases
        NotificationMessage(
            header: "Don't skip meals",
            body: "Stay satisfied & don't skip meals! Eating regular, balanced meals and snacks helps prevent blood sugar swings that trigger cravings and binge eating. Keep your energy steady and support healthy weight management by fueling your body consistently throughout your cycle.",
            phase: .follicular,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Don't skip meals",
            body: "Stay satisfied & don't skip meals! Eating regular, balanced meals and snacks helps prevent blood sugar swings that trigger cravings and binge eating. Keep your energy steady and support healthy weight management by fueling your body consistently throughout your cycle.",
            phase: .ovulatory,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Don't skip meals",
            body: "Stay satisfied & don't skip meals! Eating regular, balanced meals and snacks helps prevent blood sugar swings that trigger cravings and binge eating. Keep your energy steady and support healthy weight management by fueling your body consistently throughout your cycle.",
            phase: .luteal,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Don't skip meals",
            body: "Stay satisfied & don't skip meals! Eating regular, balanced meals and snacks helps prevent blood sugar swings that trigger cravings and binge eating. Keep your energy steady and support healthy weight management by fueling your body consistently throughout your cycle.",
            phase: .menstrual,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Combine protien and fiber",
            body: "Pair protein and fiber for lasting satiety. An apple with almond butter, or a salad with grilled chicken can help stabilize your blood sugar levels, reduce cravings, support weight loss, and balance your hormones to ease symptoms.",
            phase: .follicular,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Combine protien and fiber",
            body: "Pair protein and fiber for lasting satiety. An apple with almond butter, or a salad with grilled chicken can help stabilize your blood sugar levels, reduce cravings, support weight loss, and balance your hormones to ease symptoms.",
            phase: .ovulatory,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Combine protien and fiber",
            body: "Pair protein and fiber for lasting satiety. An apple with almond butter, or a salad with grilled chicken can help stabilize your blood sugar levels, reduce cravings, support weight loss, and balance your hormones to ease symptoms.",
            phase: .luteal,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Combine protien and fiber",
            body: "Pair protein and fiber for lasting satiety. An apple with almond butter, or a salad with grilled chicken can help stabilize your blood sugar levels, reduce cravings, support weight loss, and balance your hormones to ease symptoms.",
            phase: .menstrual,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Choose whole grain over refined",
            body: "Choose whole grains over refined for steady energy! Swap white rice for brown rice and opt for whole-wheat bread instead of white. Whole grains are rich in fiber and nutrients that help stabilize blood sugar, reduce cravings, and support hormone balance throughout your cycle. You'll feel the difference in your energy levels!",
            phase: .follicular,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Choose whole grain over refined",
            body: "Choose whole grains over refined for steady energy! Swap white rice for brown rice and opt for whole-wheat bread instead of white. Whole grains are rich in fiber and nutrients that help stabilize blood sugar, reduce cravings, and support hormone balance throughout your cycle. You'll feel the difference in your energy levels!",
            phase: .ovulatory,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Choose whole grain over refined",
            body: "Choose whole grains over refined for steady energy! Swap white rice for brown rice and opt for whole-wheat bread instead of white. Whole grains are rich in fiber and nutrients that help stabilize blood sugar, reduce cravings, and support hormone balance throughout your cycle. You'll feel the difference in your energy levels!",
            phase: .luteal,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Choose whole grain over refined",
            body: "Choose whole grains over refined for steady energy! Swap white rice for brown rice and opt for whole-wheat bread instead of white. Whole grains are rich in fiber and nutrients that help stabilize blood sugar, reduce cravings, and support hormone balance throughout your cycle. You'll feel the difference in your energy levels!",
            phase: .menstrual,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Avoid sugary drinks",
            body: "Let's choose drinks that fuel our flow! Sugary drinks spike your energy and then quickly crash it. They're packed with empty calories that fuel cravings, bloating, and binge eating. Do your best to stick with water, unsweetened tea, or sparkling water instead to stay energized, in control, and support long-term weight loss.",
            phase: .follicular,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Avoid sugary drinks",
            body: "Let's choose drinks that fuel our flow! Sugary drinks spike your energy and then quickly crash it. They're packed with empty calories that fuel cravings, bloating, and binge eating. Do your best to stick with water, unsweetened tea, or sparkling water instead to stay energized, in control, and support long-term weight loss.",
            phase: .ovulatory,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Avoid sugary drinks",
            body: "Let's choose drinks that fuel our flow! Sugary drinks spike your energy and then quickly crash it. They're packed with empty calories that fuel cravings, bloating, and binge eating. Do your best to stick with water, unsweetened tea, or sparkling water instead to stay energized, in control, and support long-term weight loss.",
            phase: .luteal,
            category: "All Phases Tips"
        ),
        
        NotificationMessage(
            header: "Avoid sugary drinks",
            body: "Let's choose drinks that fuel our flow! Sugary drinks spike your energy and then quickly crash it. They're packed with empty calories that fuel cravings, bloating, and binge eating. Do your best to stick with water, unsweetened tea, or sparkling water instead to stay energized, in control, and support long-term weight loss.",
            phase: .menstrual,
            category: "All Phases Tips"
        )
    ]
    
    // MARK: - Helper Methods
    
    static func messagesForPhase(_ phase: CyclePhase) -> [NotificationMessage] {
        return allMessages.filter { $0.phase == phase }
    }
    
    static func messagesForCategory(_ category: String) -> [NotificationMessage] {
        return allMessages.filter { $0.category == category }
    }
    
    static func randomMessageForPhase(_ phase: CyclePhase) -> NotificationMessage? {
        let phaseMessages = messagesForPhase(phase)
        return phaseMessages.randomElement()
    }
    
    static func allCategories() -> [String] {
        return Array(Set(allMessages.compactMap { $0.category })).sorted()
    }
    
    static func allPhases() -> [CyclePhase] {
        return Array(Set(allMessages.map { $0.phase })).sorted { $0.rawValue < $1.rawValue }
    }
}

