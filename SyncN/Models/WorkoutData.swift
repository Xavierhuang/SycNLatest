import Foundation

struct WorkoutData {
    static func getSampleWorkouts() -> [Workout] {
        return [
            // ===== LIZZY'S WORKOUTS =====
            
            // Ovulatory Phase
            Workout(
                title: "Intervals Guided Cardio",
                description: "High-intensity interval training with guided coaching. Perfect for peak energy during ovulation phase.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .ovulatory,
                difficulty: .advanced,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Run%20Ovulation.%2012.10.m4a",
                isVideo: false
            ),
            Workout(
                title: "Circuit: Form Focus",
                description: "Circuit training with emphasis on proper form and technique. Great for building strength and endurance.",
                duration: 18,
                workoutType: .strength,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Circuit%20form%20focus.mov",
                isVideo: true
            ),
            Workout(
                title: "Fresh Start Guided Cardio",
                description: "Energizing cardio session to kickstart your follicular phase. Perfect for building momentum and energy.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20run%20-%2012_30_23,%209.13%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Endurance Guided Cardio",
                description: "Steady-state cardio focused on building endurance. Ideal for luteal phase when energy is moderate.",
                duration: 30,
                workoutType: .cardio,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Run%20-%2012_16_23,%203.25%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Reflection Guided Cardio",
                description: "Gentle, reflective cardio session perfect for menstrual phase. Low-impact movement with mindfulness.",
                duration: 20,
                workoutType: .cardio,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Lizzy",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstrual%20run%20-%2012_30_23,%207.54%20PM.m4a",
                isVideo: false
            ),
            Workout(
                title: "Dance Cardio, Affirmations Blast",
                description: "High-energy dance cardio with positive affirmations. Perfect for boosting mood and energy.",
                duration: 20,
                workoutType: .dance,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//im%20Dance%20Cardio%20Affirmations%20Blast.mp4",
                isVideo: true
            ),
            Workout(
                title: "Dance Cardio - the short one, Affirmations Blast",
                description: "Quick dance cardio session with affirmations. Perfect for when you're short on time but need energy.",
                duration: 5,
                workoutType: .dance,
                cyclePhase: .ovulatory,
                difficulty: .intermediate,
                instructor: "Lizzy",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//im%20Dance%20Cardio%20Affirmations%20Blast%20the%20short%20one.mp4",
                isVideo: true
            ),
            
            // ===== CRYSTAL'S WORKOUTS =====
            
            // Follicular Phase
            Workout(
                title: "Follicular Meditation",
                description: "Guided meditation specifically designed for the follicular phase. Set intentions and build energy.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .follicular,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20Meditation%20(1).m4a",
                isVideo: false
            ),
            Workout(
                title: "Spring Into Life Yoga",
                description: "Dynamic yoga flow to harness the energy of the follicular phase. Build strength and flexibility.",
                duration: 45,
                workoutType: .yoga,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Follicular%20Phase%20Sync%20N%20Official.mp4",
                isVideo: true
            ),
            
            // Menstrual Phase
            Workout(
                title: "Reflection Yoga",
                description: "Gentle, reflective yoga practice perfect for menstrual phase. Honor your body's need for rest and reflection.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Video%20SYNC%20N%20Official.mp4",
                isVideo: true
            ),
            Workout(
                title: "Menstration Meditation",
                description: "Guided meditation to support you during menstruation. Reduce stress and honor this phase of your cycle.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .menstrual,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Meditation.m4a",
                isVideo: false
            ),
            
            // Ovulatory Phase
            Workout(
                title: "Expansive Yoga",
                description: "Powerful yoga practice to harness peak energy during ovulation. Challenge yourself and expand your limits.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .ovulatory,
                difficulty: .advanced,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Ovulation%20Sync%20N.mp4",
                isVideo: true
            ),
            Workout(
                title: "Ovulation Meditation",
                description: "Guided meditation for the ovulatory phase. Connect with your peak energy and creative power.",
                duration: 4,
                workoutType: .meditation,
                cyclePhase: .ovulatory,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Ovulation%20Meditation.m4a",
                isVideo: false
            ),
            
            // Luteal Phase
            Workout(
                title: "Luteal Meditation",
                description: "Gentle meditation to support emotional balance during the luteal phase. Find peace and stability.",
                duration: 5,
                workoutType: .meditation,
                cyclePhase: .luteal,
                difficulty: .beginner,
                instructor: "Crystal",
                audioURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Menstruation%20Meditation.m4a",
                isVideo: false
            ),
            Workout(
                title: "Let Go Yoga",
                description: "Restorative yoga practice for the luteal phase. Release tension and prepare for the next cycle.",
                duration: 30,
                workoutType: .yoga,
                cyclePhase: .luteal,
                difficulty: .beginner,
                instructor: "Crystal",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Luteal%20Phase%20Sync%20N.mp4",
                isVideo: true
            ),
            
            // ===== BRI'S WORKOUTS =====
            
            // Luteal Phase
            Workout(
                title: "Anger Workout",
                description: "High-intensity workout to channel and release energy. Perfect for managing emotions during luteal phase.",
                duration: 15,
                workoutType: .strength,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Anger%20Workout.mp4",
                isVideo: true
            ),
            Workout(
                title: "Pilates",
                description: "Classic pilates workout focusing on core strength and body awareness. Suitable for any phase.",
                duration: 30,
                workoutType: .pilates,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Pilates.mp4",
                isVideo: true
            ),
            Workout(
                title: "Pilates: Core Focus",
                description: "Targeted pilates session emphasizing core strength and stability. Perfect for building foundational strength.",
                duration: 18,
                workoutType: .pilates,
                cyclePhase: .luteal,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Pilates%20core%20focus.mp4",
                isVideo: true
            ),
            
            
            // Any Phase
            Workout(
                title: "Strength",
                description: "Comprehensive strength training workout. Adapt intensity based on your current cycle phase.",
                duration: 21,
                workoutType: .strength,
                cyclePhase: .follicular,
                difficulty: .intermediate,
                instructor: "Bri",
                videoURL: "https://ukdcoxglckpfbeuieqvl.supabase.co/storage/v1/object/public/Videos//Strength.mp4",
                isVideo: true
            )
        ]
    }
}
