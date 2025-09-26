import SwiftUI
import SwiftData

struct NutritionPreferencesOnePagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var personalizationData: [PersonalizationData]
    
    @State private var isEditing = false
    @State private var nutritionGoals: Set<NutritionGoal> = []
    @State private var eatingApproaches: Set<EatingApproach> = []
    @State private var breakfastFrequency: MealFrequency?
    @State private var lunchFrequency: MealFrequency?
    @State private var dinnerFrequency: MealFrequency?
    @State private var snacksFrequency: MealFrequency?
    @State private var dessertFrequency: MealFrequency?
    @State private var periodSymptoms: Set<PeriodSymptom> = []
    @State private var weightChange: WeightChange?
    @State private var eatingDisorderHistory: EatingDisorderHistory?
    @State private var birthYear: Int? = nil
    @State private var weight: Double?
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 6
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var personalization: PersonalizationData? {
        personalizationData.first { $0.userId == userProfile?.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "leaf")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Nutrition Preferences")
                            .font(.custom("Sofia Pro", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your nutrition goals and eating habits")
                            .font(.custom("Sofia Pro", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Current Nutrition Status
                    VStack(spacing: 16) {
                        Text("Nutrition Overview")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 20) {
                            NutritionStatusCard(
                                title: "BMI",
                                value: bmiString,
                                icon: "scalemass.fill",
                                color: .blue
                            )
                            
                            NutritionStatusCard(
                                title: "Age",
                                value: age,
                                icon: "calendar.badge.clock",
                                color: .purple
                            )
                        }
                        
                        HStack(spacing: 20) {
                            NutritionStatusCard(
                                title: "Weight",
                                value: weightString,
                                icon: "scalemass",
                                color: .orange
                            )
                            
                            NutritionStatusCard(
                                title: "Height",
                                value: "\(heightFeet)'\(heightInches)\"",
                                icon: "ruler",
                                color: .green
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Edit Button Section
                    HStack {
                        Spacer()
                        
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveNutritionPreferences()
                            }
                            isEditing.toggle()
                        }
                        .font(.custom("Sofia Pro", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal, 20)
                    
                    // Nutrition Goals Section
                    VStack(spacing: 16) {
                        Text("Nutrition Goals")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            if nutritionGoals.isEmpty {
                                Text("No nutrition goals selected")
                                    .font(.custom("Sofia Pro", size: 14))
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(Array(nutritionGoals), id: \.self) { goal in
                                        HStack {
                                            Image(systemName: "target")
                                                .foregroundColor(.green)
                                                .font(.system(size: 12))
                                            
                                            Text(goal.rawValue)
                                                .font(.custom("Sofia Pro", size: 12))
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            if isEditing {
                                VStack(spacing: 12) {
                                    Text("Select your nutrition goals:")
                                        .font(.custom("Sofia Pro", size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(NutritionGoal.allCases, id: \.self) { goal in
                                            Button(action: {
                                                if nutritionGoals.contains(goal) {
                                                    nutritionGoals.remove(goal)
                                                } else {
                                                    nutritionGoals.insert(goal)
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: nutritionGoals.contains(goal) ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(nutritionGoals.contains(goal) ? .green : .gray)
                                                        .font(.system(size: 16))
                                                    
                                                    Text(goal.rawValue)
                                                        .font(.custom("Sofia Pro", size: 12))
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(2)
                                                    
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(nutritionGoals.contains(goal) ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(nutritionGoals.contains(goal) ? Color.green : Color.clear, lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Eating Approaches Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Eating Approaches")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if eatingApproaches.isEmpty {
                            Text("No eating approaches selected")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(eatingApproaches), id: \.self) { approach in
                                    HStack {
                                        Image(systemName: "leaf.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 12))
                                        
                                        Text(approach.rawValue)
                                            .font(.custom("Sofia Pro", size: 12))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        if isEditing {
                            VStack(spacing: 12) {
                                Text("Select your eating approaches:")
                                    .font(.custom("Sofia Pro", size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(EatingApproach.allCases, id: \.self) { approach in
                                        Button(action: {
                                            if eatingApproaches.contains(approach) {
                                                eatingApproaches.remove(approach)
                                            } else {
                                                eatingApproaches.insert(approach)
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: eatingApproaches.contains(approach) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(eatingApproaches.contains(approach) ? .green : .gray)
                                                    .font(.system(size: 16))
                                                
                                                Text(approach.rawValue)
                                                    .font(.custom("Sofia Pro", size: 12))
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(eatingApproaches.contains(approach) ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(eatingApproaches.contains(approach) ? Color.green : Color.clear, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Meal Frequency Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meal Frequency")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NutritionDetailRow(
                                title: "Breakfast",
                                value: breakfastFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    ResponsiveButtonLayout(
                                        options: MealFrequency.allCases,
                                        selectedOption: breakfastFrequency,
                                        onSelection: { mealFreq in
                                            breakfastFrequency = mealFreq
                                        }
                                    )
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Lunch",
                                value: lunchFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    ResponsiveButtonLayout(
                                        options: MealFrequency.allCases,
                                        selectedOption: lunchFrequency,
                                        onSelection: { mealFreq in
                                            lunchFrequency = mealFreq
                                        }
                                    )
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Dinner",
                                value: dinnerFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    ResponsiveButtonLayout(
                                        options: MealFrequency.allCases,
                                        selectedOption: dinnerFrequency,
                                        onSelection: { mealFreq in
                                            dinnerFrequency = mealFreq
                                        }
                                    )
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Snacks",
                                value: snacksFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    ResponsiveButtonLayout(
                                        options: MealFrequency.allCases,
                                        selectedOption: snacksFrequency,
                                        onSelection: { mealFreq in
                                            snacksFrequency = mealFreq
                                        }
                                    )
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Dessert",
                                value: dessertFrequency?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    ResponsiveButtonLayout(
                                        options: MealFrequency.allCases,
                                        selectedOption: dessertFrequency,
                                        onSelection: { mealFreq in
                                            dessertFrequency = mealFreq
                                        }
                                    )
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Personal Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            NutritionDetailRow(
                                title: "Birth Year",
                                value: birthYear != nil ? "\(birthYear!)" : "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(spacing: 8) {
                                        if let currentBirthYear = birthYear {
                                            HStack {
                                                Stepper("\(currentBirthYear)", value: Binding(
                                                    get: { currentBirthYear },
                                                    set: { birthYear = $0 }
                                                ), in: 1920...2010)
                                                
                                                Button("Remove") {
                                                    birthYear = nil
                                                }
                                                .font(.custom("Sofia Pro", size: 12))
                                                .foregroundColor(.red)
                                            }
                                        } else {
                                            Button("Add Birth Year") {
                                                birthYear = Calendar.current.component(.year, from: Date()) - 25
                                            }
                                            .font(.custom("Sofia Pro", size: 14))
                                            .foregroundColor(.blue)
                                        }
                                    }
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Weight",
                                value: weightString,
                                isEditing: isEditing,
                                editContent: {
                                    HStack {
                                        TextField("Enter weight", value: $weight, format: .number)
                                            .keyboardType(.decimalPad)
                                        Text("lbs")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                            
                            if isEditing {
                                HStack {
                                    Text("Height")
                                        .font(.custom("Sofia Pro", size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Picker("Feet", selection: $heightFeet) {
                                            ForEach(3...8, id: \.self) { feet in
                                                Text("\(feet) ft").tag(feet)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        
                                        Picker("Inches", selection: $heightInches) {
                                            ForEach(0...11, id: \.self) { inches in
                                                Text("\(inches) in").tag(inches)
                                            }
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                NutritionDetailRow(
                                    title: "Height",
                                    value: "\(heightFeet)'\(heightInches)\"",
                                    isEditing: false,
                                    editContent: { EmptyView() }
                                )
                            }
                            
                            NutritionDetailRow(
                                title: "Weight Change Goals",
                                value: weightChange?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(spacing: 8) {
                                        ForEach(WeightChange.allCases, id: \.self) { change in
                                            Button(action: {
                                                weightChange = change
                                            }) {
                                                HStack {
                                                    Image(systemName: weightChange == change ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(weightChange == change ? .blue : .gray)
                                                    
                                                    Text(change.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(weightChange == change ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                            
                            NutritionDetailRow(
                                title: "Eating Disorder History",
                                value: eatingDisorderHistory?.rawValue ?? "Not set",
                                isEditing: isEditing,
                                editContent: {
                                    VStack(spacing: 8) {
                                        ForEach(EatingDisorderHistory.allCases, id: \.self) { history in
                                            Button(action: {
                                                eatingDisorderHistory = history
                                            }) {
                                                HStack {
                                                    Image(systemName: eatingDisorderHistory == history ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(eatingDisorderHistory == history ? .blue : .gray)
                                                    
                                                    Text(history.rawValue)
                                                        .font(.custom("Sofia Pro", size: 14))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(eatingDisorderHistory == history ? Color.blue.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    
                    // Period Symptoms Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Period Symptoms")
                            .font(.custom("Sofia Pro", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if periodSymptoms.isEmpty {
                            Text("No symptoms selected")
                                .font(.custom("Sofia Pro", size: 14))
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(periodSymptoms), id: \.self) { symptom in
                                    HStack {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 12))
                                        
                                        Text(symptom.rawValue)
                                            .font(.custom("Sofia Pro", size: 12))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        if isEditing {
                            VStack(spacing: 12) {
                                Text("Select symptoms you experience:")
                                    .font(.custom("Sofia Pro", size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(PeriodSymptom.allCases, id: \.self) { symptom in
                                        Button(action: {
                                            if periodSymptoms.contains(symptom) {
                                                periodSymptoms.remove(symptom)
                                            } else {
                                                periodSymptoms.insert(symptom)
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: periodSymptoms.contains(symptom) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(periodSymptoms.contains(symptom) ? .orange : .gray)
                                                    .font(.system(size: 16))
                                                
                                                Text(symptom.rawValue)
                                                    .font(.custom("Sofia Pro", size: 12))
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(1)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(periodSymptoms.contains(symptom) ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(periodSymptoms.contains(symptom) ? Color.orange : Color.clear, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Nutrition Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Sofia Pro", size: 16))
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
    }
    
    // MARK: - Computed Properties
    
    private var age: String {
        guard let birthYear = birthYear else { return "Not set" }
        let currentYear = Calendar.current.component(.year, from: Date())
        return "\(currentYear - birthYear) years"
    }
    
    private var weightString: String {
        if let weight = weight {
            return "\(Int(weight)) lbs"
        } else {
            return "Not set"
        }
    }
    
    private var bmiString: String {
        guard let weight = weight else { return "Not set" }
        
        let heightInInches = Double(heightFeet * 12 + heightInches)
        let bmi = (weight / (heightInInches * heightInInches)) * 703
        
        return String(format: "%.1f", bmi)
    }
    
    // MARK: - Methods
    
    private func loadCurrentData() {
        guard let personalization = personalization else { return }
        
        breakfastFrequency = personalization.breakfastFrequency
        lunchFrequency = personalization.lunchFrequency
        dinnerFrequency = personalization.dinnerFrequency
        snacksFrequency = personalization.snacksFrequency
        dessertFrequency = personalization.dessertFrequency
        weightChange = personalization.weightChange
        eatingDisorderHistory = personalization.eatingDisorderHistory
        birthYear = personalization.birthYear ?? Calendar.current.component(.year, from: Date()) - 25
        weight = personalization.weight
        heightFeet = personalization.heightFeet ?? 5
        heightInches = personalization.heightInches ?? 6
        
        // Load nutrition goals
        if let goalsString = personalization.nutritionGoalsString {
            let goals = goalsString.components(separatedBy: ",").compactMap { NutritionGoal(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            nutritionGoals = Set(goals)
        }
        
        // Load eating approaches
        if let approachesString = personalization.eatingApproachesString {
            let approaches = approachesString.components(separatedBy: ",").compactMap { EatingApproach(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            eatingApproaches = Set(approaches)
        }
        
        // Load period symptoms
        if let symptomsString = personalization.periodSymptomsString {
            let symptoms = symptomsString.components(separatedBy: ",").compactMap { PeriodSymptom(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            periodSymptoms = Set(symptoms)
        }
    }
    
    private func saveNutritionPreferences() {
        guard let personalization = personalization else { return }
        
        personalization.breakfastFrequency = breakfastFrequency
        personalization.lunchFrequency = lunchFrequency
        personalization.dinnerFrequency = dinnerFrequency
        personalization.snacksFrequency = snacksFrequency
        personalization.dessertFrequency = dessertFrequency
        personalization.weightChange = weightChange
        personalization.eatingDisorderHistory = eatingDisorderHistory
        personalization.birthYear = birthYear
        personalization.weight = weight
        personalization.heightFeet = heightFeet
        personalization.heightInches = heightInches
        personalization.nutritionGoalsString = nutritionGoals.isEmpty ? nil : nutritionGoals.map { $0.rawValue }.joined(separator: ",")
        personalization.eatingApproachesString = eatingApproaches.isEmpty ? nil : eatingApproaches.map { $0.rawValue }.joined(separator: ",")
        personalization.periodSymptomsString = periodSymptoms.isEmpty ? nil : periodSymptoms.map { $0.rawValue }.joined(separator: ",")
        personalization.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving nutrition preferences: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct NutritionStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Sofia Pro", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.custom("Sofia Pro", size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct NutritionDetailRow<EditContent: View>: View {
    let title: String
    let value: String
    let isEditing: Bool
    @ViewBuilder let editContent: () -> EditContent
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Sofia Pro", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                editContent()
            } else {
                Text(value)
                    .font(.custom("Sofia Pro", size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Chip Layout
struct ResponsiveButtonLayout<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    let selectedOption: T?
    let onSelection: (T) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(options), id: \.self) { option in
                Button(action: {
                    onSelection(option)
                }) {
                    Text(option.rawValue)
                        .font(.custom("Sofia Pro", size: 12))
                        .fontWeight(.medium)
                        .foregroundColor(selectedOption == option ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedOption == option ? Color.blue : Color.gray.opacity(0.2))
                        .cornerRadius(16)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    NutritionPreferencesOnePagerView()
        .modelContainer(for: [UserProfile.self, PersonalizationData.self], inMemory: true)
}
