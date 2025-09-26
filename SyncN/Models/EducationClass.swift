import Foundation

// MARK: - Education Class Model
struct EducationClass: Identifiable, Codable {
    let id: UUID
    let title: String
    let duration: String
    let order: Int
    let section: String
    let videoURL: String
    
    init(title: String, duration: String, order: Int, section: String, videoURL: String) {
        self.id = UUID()
        self.title = title
        self.duration = duration
        self.order = order
        self.section = section
        self.videoURL = videoURL
    }
}

// MARK: - Education Classes Data
class EducationClassesData {
    static let shared = EducationClassesData()
    
    private init() {}
    
    func getEducationClasses() -> [EducationClass] {
        // Use cached data if available
        if let cached = CacheManager.shared.getCachedEducationClasses() {
            return cached
        }
        
        let classes = [
            // Meet Your Hormones Section
            EducationClass(
                title: "Meet Your Menstrual Cycle",
                duration: "2 min",
                order: 1,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Meet%20your%20Menstrual%20Cycle.mp4"
            ),
            EducationClass(
                title: "Estrogen",
                duration: "5 min",
                order: 2,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Estrogen%20v2.mp4"
            ),
            EducationClass(
                title: "Progesterone",
                duration: "3 min",
                order: 3,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Progesterone%20(1).mp4"
            ),
            EducationClass(
                title: "Follicle Stimulating Hormone (FSH)",
                duration: "3 min",
                order: 4,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicle-Stimulating%20Hormone%20(FHS).mp4"
            ),
            EducationClass(
                title: "Lutenizing Hormone (LH)",
                duration: "2 min",
                order: 5,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteinizing%20Hormone%20(LH).mp4"
            ),
            EducationClass(
                title: "Testosterone",
                duration: "2 min",
                order: 6,
                section: "Meet Your Hormones",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Testosterone%20.mp4"
            ),
            
            // Phase Video Section
            EducationClass(
                title: "Follicular Phase Video",
                duration: "2 min",
                order: 7,
                section: "Phase Video",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20Phase.mp4"
            ),
            EducationClass(
                title: "Ovulation Phase Video",
                duration: "2 min",
                order: 8,
                section: "Phase Video",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Ovulation%20Phase.mp4"
            ),
            EducationClass(
                title: "Luteal Phase Video",
                duration: "3 min",
                order: 9,
                section: "Phase Video",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Phase.mp4"
            ),
            EducationClass(
                title: "Menstrual Phase Video",
                duration: "2 min",
                order: 10,
                section: "Phase Video",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstrual%20Phase%20Video.mp4"
            )
        ]
        
        // Cache the result
        CacheManager.shared.setCachedEducationClasses(classes)
        return classes
    }
    
    func getHormoneClasses() -> [EducationClass] {
        return getEducationClasses().filter { $0.section == "Meet Your Hormones" }
    }
    
    func getPhaseVideoClasses() -> [EducationClass] {
        return getEducationClasses().filter { $0.section == "Phase Video" }
    }
}
