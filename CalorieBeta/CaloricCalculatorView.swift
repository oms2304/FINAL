import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - Gender Button Picker
struct GenderButtonPicker: View {
    @Binding var selectedGender: String
    let genders = ["🙋‍♂️ Male", "🙋‍♀️ Female"]
    let accentColor = Color(red: 61/255, green: 156/255, blue: 86/255)

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 10) {
                ForEach(genders, id: \.self) { gender in
                    Button(action: {
                        selectedGender = gender
                    }) {
                        Text(gender)
                            .frame(width: 100)
                            .padding(.vertical, 10)
                            .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedGender == gender ? accentColor : Color.clear, lineWidth: 2)
                                    )
                            )
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }
}

// MARK: - Caloric Calculator View
struct CaloricCalculatorView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @State private var showSaveConfirmation = false

    private let activityLevels = [
        ("Sedentary", 1.2),
        ("Lightly Active", 1.375),
        ("Moderately Active", 1.55),
        ("Very Active", 1.725),
        ("Extremely Active", 1.9)
    ]

    private let goals = ["Lose", "Maintain", "Gain"]
    private let accentColor = Color(red: 61/255, green: 156/255, blue: 86/255)

    var body: some View {
        Form {
            personalInfoSection
            macronutrientSection

            Section(header: Text("Recommended Calorie Intake")) {
                Text("\(goalSettings.calories ?? 0, specifier: "%.0f") kcal")
                    .font(.title)
                    .foregroundColor(accentColor)
            }

            Button(action: saveCaloricGoal) {
                Text("Save Calorie Goal")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Calorie Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Calorie Calculator")
                    .font(.headline)
            }
        }
        .onAppear(perform: fetchCaloricGoal)
        .alert(isPresented: $showSaveConfirmation) {
            Alert(title: Text("Success"), message: Text("Calorie goal saved!"), dismissButton: .default(Text("OK")))
        }
        .onChange(of: goalSettings.activityLevel) { _ in goalSettings.recalculateCalorieGoal() }
        .onChange(of: goalSettings.goal) { _ in goalSettings.recalculateCalorieGoal() }
        .onChange(of: goalSettings.age) { _ in goalSettings.recalculateCalorieGoal() }
        .onChange(of: goalSettings.gender) { _ in goalSettings.recalculateCalorieGoal() }
    }

    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        Section(header: Text("Your Information")) {
            HStack {
                Text("Age")
                Spacer()
                TextField("Age (years)", value: $goalSettings.age, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            GenderButtonPicker(selectedGender: $goalSettings.gender)
                .padding(.vertical, 5)

            Picker("Activity Level", selection: $goalSettings.activityLevel) {
                ForEach(activityLevels, id: \.1) { level in
                    Text(level.0).tag(level.1)
                }
            }
            .tint(accentColor)
            .pickerStyle(MenuPickerStyle())

            Picker("Goal", selection: $goalSettings.goal) {
                ForEach(goals, id: \.self) { goal in
                    Text(goal)
                }
            }
            .tint(accentColor)
            .pickerStyle(MenuPickerStyle())
        }
    }

    // MARK: - Macronutrient Section
    private var macronutrientSection: some View {
        Section(header: Text("Macronutrient Distribution (%)")) {
            VStack(spacing: 20) {
                macroSlider(title: "Protein", value: $goalSettings.proteinPercentage)
                macroSlider(title: "Carbs", value: $goalSettings.carbsPercentage)
                macroSlider(title: "Fats", value: $goalSettings.fatsPercentage)
            }
        }
    }

    private func macroSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
            }

            ZStack(alignment: .leading) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, accentColor]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 6)
                .cornerRadius(5)

                Slider(value: value, in: 10...40, step: 5)
                    .accentColor(.clear)
            }
        }
    }

    // MARK: - Save/Load
    private func saveCaloricGoal() {
        goalSettings.saveUserGoals(userID: Auth.auth().currentUser?.uid ?? "")
        showSaveConfirmation = true
    }

    private func fetchCaloricGoal() {
        goalSettings.loadUserGoals(userID: Auth.auth().currentUser?.uid ?? "")
    }
}
