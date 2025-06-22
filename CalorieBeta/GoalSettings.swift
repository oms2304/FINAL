import Foundation
import FirebaseFirestore
import FirebaseAuth

// This class manages the user's goal settings (e.g., calories, macros, weight, height) and
// integrates with Firebase Firestore for persistence. It acts as an ObservableObject to
// notify views of changes.
class GoalSettings: ObservableObject {
    // Published properties to track and update user goals, observable by SwiftUI views:
    @Published var calories: Double?
    @Published var protein: Double = 150
    @Published var fats: Double = 70
    @Published var carbs: Double = 250
    @Published var weight: Double = 150.0 // Current weight
    @Published var height: Double = 170.0
    @Published var weightHistory: [(id: String, date: Date, weight: Double)] = []
    @Published var isUpdatingGoal: Bool = false
    @Published var proteinPercentage: Double = 30.0
    @Published var carbsPercentage: Double = 50.0
    @Published var fatsPercentage: Double = 20.0
    @Published var activityLevel: Double = 1.2
    @Published var age: Int = 25
    @Published var gender: String = "Male"
    @Published var goal: String = "Maintain"
    @Published var showingBubbles: Bool = true
    @Published var targetWeight: Double?
    @Published var waterGoal: Double = 64.0

    // Private properties for Firebase and state management:
    private let db = Firestore.firestore()
    private var isFetchingGoals = false
    private var isGoalsLoaded = false

    // ... (updateMacros, recalculateCalorieGoal, loadUserGoals, saveUserGoals remain the same) ...
    func updateMacros() {
        guard let calorieGoal = calories else { return }
        let totalPercentage = proteinPercentage + carbsPercentage + fatsPercentage
        guard totalPercentage == 100 else {
            print("❌ Macronutrient percentages do not sum to 100%")
            return
        }
        let proteinCalories = (proteinPercentage / 100) * calorieGoal
        let carbsCalories = (carbsPercentage / 100) * calorieGoal
        let fatsCalories = (fatsPercentage / 100) * calorieGoal
        self.protein = proteinCalories / 4
        self.carbs = carbsCalories / 4
        self.fats = fatsCalories / 9
        print("✅ Updated Macros: \(self.protein)g Protein, \(self.carbs)g Carbs, \(self.fats)g Fats")
    }

    func recalculateCalorieGoal() {
        let weightInKg = weight * 0.453592
        let heightInCm = height
        let bmr: Double
        if gender == "Male" { bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) + 5 }
        else { bmr = 10 * weightInKg + 6.25 * heightInCm - 5 * Double(age) - 161 }
        var calories = bmr * activityLevel
        switch goal {
            case "Lose": calories -= 500
            case "Gain": calories += 500
            default: break
        }
        if let targetWeight = targetWeight {
            let weightDifference = weight - targetWeight
            if weightDifference > 0 { calories -= 250 }
            else if weightDifference < 0 { calories += 250 }
        }
        print("Calories: \(calories)")
        self.calories = max(calories, 0)
        updateMacros()
    }

     func loadUserGoals(userID: String, completion: @escaping () -> Void = {}) {
         guard !isFetchingGoals else { return }
         isFetchingGoals = true
         db.collection("users").document(userID).getDocument { [weak self] document, error in
             defer { self?.isFetchingGoals = false; self?.isGoalsLoaded = true; completion() }
             guard let self = self else { return }
             if let document = document, document.exists, let data = document.data() {
                 DispatchQueue.main.async {
                     if let goals = data["goals"] as? [String: Any] {
                         self.calories = goals["calories"] as? Double ?? self.calories
                         self.protein = goals["protein"] as? Double ?? self.protein
                         self.fats = goals["fats"] as? Double ?? self.fats
                         self.carbs = goals["carbs"] as? Double ?? self.carbs
                         self.proteinPercentage = goals["proteinPercentage"] as? Double ?? self.proteinPercentage
                         self.carbsPercentage = goals["carbsPercentage"] as? Double ?? self.carbsPercentage
                         self.fatsPercentage = goals["fatsPercentage"] as? Double ?? self.fatsPercentage
                         self.activityLevel = goals["activityLevel"] as? Double ?? self.activityLevel
                         self.age = goals["age"] as? Int ?? self.age
                         self.gender = goals["gender"] as? String ?? self.gender
                         self.goal = goals["goal"] as? String ?? self.goal
                         self.targetWeight = goals["targetWeight"] as? Double
                         self.waterGoal = (goals["waterGoal"] as? Double) ?? 64.0
                     }
                     self.weight = data["weight"] as? Double ?? self.weight
                     self.height = data["height"] as? Double ?? self.height
                     self.recalculateCalorieGoal()
                     print("✅ Loaded user goals: \(self.calories ?? 0) calories")
                 }
             } else {
                 print("❌ Error fetching user goals: \(error?.localizedDescription ?? "Unknown error")")
             }
         }
     }

     func saveUserGoals(userID: String) {
         self.isUpdatingGoal = true
         self.updateMacros()
         let goalData = [ "calories": calories ?? 2000, "protein": protein, "fats": fats, "carbs": carbs, "proteinPercentage": proteinPercentage, "carbsPercentage": carbsPercentage, "fatsPercentage": fatsPercentage, "activityLevel": activityLevel, "age": age, "gender": gender, "goal": goal, "targetWeight" : targetWeight ?? NSNull() ] as [String: Any]
         let userData = [ "goals": goalData, "weight": weight, "height": height ] as [String: Any]
         db.collection("users").document(userID).setData(userData, merge: true) { [weak self] error in
             guard let self = self else { return }
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isUpdatingGoal = false }
             if let error = error { print("❌ Error saving user goals: \(error.localizedDescription)") }
             else { DispatchQueue.main.async { print("✅ User goals saved successfully.") } }
         }
     }

    func loadWeightHistory() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).collection("weightHistory")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error { print("❌ Error fetching weight history: \(error.localizedDescription)"); return }
                DispatchQueue.main.async {
                    self.weightHistory = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        if let weight = data["weight"] as? Double, let timestamp = data["timestamp"] as? Timestamp {
                            return (id: doc.documentID, date: timestamp.dateValue(), weight: weight)
                        }
                        return nil
                    } ?? []
                     self.weightHistory.sort { $0.date < $1.date }
                     print("✅ Loaded weight history count: \(self.weightHistory.count)")
                }
            }
    }

    func updateUserWeight(_ newWeight: Double) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let oldWeight = weight
        weight = newWeight
        recalculateCalorieGoal()
        let weightData: [String: Any] = [ "weight": newWeight, "timestamp": Timestamp(date: Date()) ]
        db.collection("users").document(userID).setData(["weight": newWeight], merge: true) { error in if let error = error { print("❌ Error updating current weight: \(error.localizedDescription)") } else { print("✅ Updated current weight successfully.") } }
        var ref: DocumentReference? = nil
        ref = db.collection("users").document(userID).collection("weightHistory")
            .addDocument(data: weightData) { [weak self] error in
                guard let self = self else { return }
                if let error = error { print("❌ Error saving new weight history entry: \(error.localizedDescription)") }
                else { if let newID = ref?.documentID { DispatchQueue.main.async { self.weightHistory.append((id: newID, date: Date(), weight: newWeight)); self.weightHistory.sort { $0.date < $1.date }; print("✅ New weight history entry added successfully locally and remotely.") } } }
            }
        saveUserGoals(userID: userID)
    }

    func deleteWeightEntry(entryID: String, completion: @escaping (Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "GoalSettings", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        db.collection("users").document(userID).collection("weightHistory").document(entryID).delete { [weak self] error in
            guard let self = self else { completion(error); return }
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error deleting weight entry \(entryID): \(error.localizedDescription)")
                    completion(error)
                } else {
                    self.weightHistory.removeAll { $0.id == entryID }
                    print("✅ Deleted weight entry \(entryID) successfully.")
                    completion(nil)
                }
            }
        }
    }

    func getHeightInFeetAndInches() -> (feet: Int, inches: Int) {
        let totalInches = Int(height / 2.54); let feet = totalInches / 12; let inches = totalInches % 12; return (feet, inches)
    }
    func setHeight(feet: Int, inches: Int) { let totalInches = (feet * 12) + inches; height = Double(totalInches) * 2.54 }
    func calculateWeightProgress() -> Double? {
        guard let targetWeight = targetWeight, !weightHistory.isEmpty else { return nil }
        let initialWeight = weightHistory.first?.weight ?? weight
        let currentWeight = weight
        let totalChangeNeeded = initialWeight - targetWeight
        let changeSoFar = initialWeight - currentWeight
        guard totalChangeNeeded != 0 else { return currentWeight == targetWeight ? 100.0 : 0 }
        print("weight progress: \((changeSoFar / totalChangeNeeded) * 100)")
        return (changeSoFar / totalChangeNeeded) * 100
    }

    // *** Corrected calculateWeeklyWeightChange ***
    func calculateWeeklyWeightChange() -> Double? {
        guard weightHistory.count >= 2 else { return nil }

        // *** FIX: Correctly declare endDate ***
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: endDate)! // Use corrected endDate

        let recentHistory = weightHistory.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
        guard recentHistory.count >= 2, let firstRecord = recentHistory.first, let lastRecord = recentHistory.last else { return nil }

        let weightChange = lastRecord.weight - firstRecord.weight
        // Calculate time difference in seconds (TimeInterval is Double)
        let timeDifferenceInSeconds = lastRecord.date.timeIntervalSince(firstRecord.date)

        // Define seconds in a week as Double
        let secondsPerWeek: Double = 7 * 24 * 60 * 60

        // Calculate weeks difference
        guard secondsPerWeek > 0 else { return 0 } // Avoid division by zero just in case
        let weeksDifference = timeDifferenceInSeconds / secondsPerWeek

        guard weeksDifference > 0 else { return 0 } // Avoid division by zero if dates are identical

        // *** FIX: Calculation now correctly uses Doubles ***
        return weightChange / weeksDifference // Return change per week (Double)
    }
}
