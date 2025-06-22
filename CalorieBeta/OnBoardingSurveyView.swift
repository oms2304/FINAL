import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// A view that presents an onboarding survey for new users to set their fitness goals.
/// Collects weight, height, age, gender, activity level, and fitness goal, calculates BMI,
/// updates the user's goals in GoalSettings and Firestore, and schedules a daily reminder.
struct OnboardingSurveyView: View {
    // MARK: - Environment and State Properties
    
    /// Environment object to access and modify the user's goal settings.
    @EnvironmentObject var goalSettings: GoalSettings
    
    /// Environment variable to dismiss the view when the survey is complete or cancelled.
    @Environment(\.dismiss) var dismiss
    
    /// State variables to manage user input for the survey form.
    @State private var weight: String = "" // User's weight in pounds.
    @State private var feet: String = "" // Height in feet.
    @State private var inches: String = "" // Height in inches.
    @State private var age: String = "" // User's age in years.
    @State private var gender: String = "Male" // User's gender, default to Male.
    @State private var activityLevel: Double = 1.2 // Activity level multiplier, default to Sedentary.
    @State private var goal: String = "Maintain" // Fitness goal, default to Maintain.
    @State private var reminderTime = Date() // Time for the daily reminder, default to now.
    @State private var bmi: Double? // Calculated BMI, nil until computed.
    @State private var showError: Bool = false // Flag to show validation errors.
    @State private var errorMessage: String = "" // Error message to display to the user.

    // MARK: - Constants
    
    /// Array of gender options for the picker.
    private let genders = ["Male", "Female"]
    
    /// Array of activity levels with their corresponding multipliers.
    private let activityLevels = [
        ("Sedentary", 1.2), // Little or no exercise.
        ("Lightly Active", 1.375), // Light exercise 1-3 days/week.
        ("Moderately Active", 1.55), // Moderate exercise 3-5 days/week.
        ("Very Active", 1.725), // Hard exercise 6-7 days/week.
        ("Extremely Active", 1.9) // Very hard exercise, physical job, or training twice a day.
    ]
    
    /// Array of fitness goal options for the picker.
    private let goals = ["Lose", "Maintain", "Gain"]

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Personal Information Section
                Section(header: Text("Personal Information")) {
                    // Weight input field in pounds.
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad) // Numeric keyboard with decimal support.
                    
                    // Height input fields for feet and inches.
                    HStack {
                        TextField("Feet", text: $feet)
                            .keyboardType(.numberPad) // Numeric keyboard for integers.
                            .frame(width: 100) // Fixed width for better layout.
                        Text("'") // Visual indicator for feet.
                        TextField("Inches", text: $inches)
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                        Text("\"") // Visual indicator for inches.
                    }
                    
                    // Age input field in years.
                    TextField("Age (years)", text: $age)
                        .keyboardType(.numberPad)
                    
                    // Gender selection picker.
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle()) // Segmented control for a clean UI.
                }

                // MARK: - Activity Level Section
                Section(header: Text("Activity Level")) {
                    // Activity level picker to determine the user's daily activity multiplier.
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityLevels, id: \.1) { level in
                            Text(level.0).tag(level.1)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown menu for better space usage.
                }

                // MARK: - Fitness Goal Section
                Section(header: Text("Fitness Goal")) {
                    // Fitness goal picker to determine if the user wants to lose, maintain, or gain weight.
                    Picker("Goal", selection: $goal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // MARK: - Daily Reminder Section
                Section(header: Text("Daily Reminder Time")) {
                    // Date picker for selecting the time of the daily reminder.
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }

                // MARK: - BMI Display Section
                if let bmi = bmi {
                    Section(header: Text("Your BMI")) {
                        // Display the calculated BMI.
                        Text(String(format: "%.1f", bmi))
                            .font(.title2)
                            .foregroundColor(.blue)
                        // Display the BMI category (e.g., Normal, Overweight).
                        Text(bmiCategory(bmi: bmi))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                // MARK: - Error Message Section
                if showError {
                    Section {
                        // Display validation errors to the user.
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // MARK: - Save Button
                Button(action: saveSurveyData) {
                    Text("Save and Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Set Up Your Goals")
            .toolbar {
                // Cancel button to dismiss the survey without saving.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    
    /// Calculates the user's BMI using the formula: (weight in lbs * 703) / (height in inches)^2.
    /// - Parameters:
    ///   - weight: The user's weight in pounds.
    ///   - heightInInches: The user's height in inches.
    /// - Returns: The calculated BMI as a Double.
    private func calculateBMI(weight: Double, heightInInches: Double) -> Double {
        return (weight * 703) / (heightInInches * heightInInches)
    }

    /// Determines the BMI category based on the calculated BMI value.
    /// - Parameter bmi: The calculated BMI.
    /// - Returns: A string representing the BMI category (e.g., "Normal weight").
    private func bmiCategory(bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal weight"
        case 25..<30:
            return "Overweight"
        case 30...:
            return "Obese"
        default:
            return "Unknown"
        }
    }

    /// Validates user input, calculates BMI, updates GoalSettings, saves the data to Firestore,
    /// and schedules a daily reminder to log food.
    private func saveSurveyData() {
        // Validate weight input.
        guard let weightValue = Double(weight), weightValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid weight."
            return
        }
        
        // Validate height input (feet and inches).
        guard let feetValue = Int(feet), let inchesValue = Int(inches),
              feetValue >= 0, inchesValue >= 0, inchesValue < 12 else {
            showError = true
            errorMessage = "Please enter a valid height (feet >= 0, inches 0-11)."
            return
        }
        
        // Validate age input.
        guard let ageValue = Int(age), ageValue > 0 else {
            showError = true
            errorMessage = "Please enter a valid age."
            return
        }

        // Calculate total height in inches for BMI calculation.
        let totalInches = (feetValue * 12) + inchesValue
        guard totalInches > 0 else {
            showError = true
            errorMessage = "Height must be greater than 0."
            return
        }

        // Calculate and store BMI.
        bmi = calculateBMI(weight: weightValue, heightInInches: Double(totalInches))

        // Update GoalSettings with survey data.
        goalSettings.weight = weightValue
        goalSettings.setHeight(feet: feetValue, inches: inchesValue)
        goalSettings.age = ageValue
        goalSettings.gender = gender
        goalSettings.activityLevel = activityLevel
        goalSettings.goal = goal

        // Recalculate the calorie goal based on the new data.
        goalSettings.recalculateCalorieGoal()

        // Save the updated goals to Firestore and schedule the reminder.
        if let userID = Auth.auth().currentUser?.uid {
            goalSettings.saveUserGoals(userID: userID)
            
            // Mark the user as having completed the survey by setting isFirstLogin to false.
            let db = Firestore.firestore()
            db.collection("users").document(userID).setData(["isFirstLogin": false], merge: true) { error in
                if let error = error {
                    print("❌ Error marking survey as complete: \(error.localizedDescription)")
                } else {
                    print("✅ Survey marked as complete for user \(userID)")
                }
            }

            // Schedule the daily reminder at the user-selected time.
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminderTime)
            let minute = calendar.component(.minute, from: reminderTime)
            NotificationManager.shared.scheduleDailyReminder(atHour: hour, minute: minute)
        }

        // Dismiss the survey view.
        dismiss()
    }
}
