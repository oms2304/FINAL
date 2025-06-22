import SwiftUI
import FirebaseAuth

// This view displays detailed information about a food item and allows the user to adjust
// its quantity or serving size before adding or updating it in their daily log.
struct FoodDetailView: View {
    // The food item being edited or added, passed as a constant.
    var foodItem: FoodItem
    // A binding to the daily log, allowing updates to be reflected in the parent view.
    @Binding var dailyLog: DailyLog?
    // The date for which the log is being updated, defaults to today if not specified.
    var date: Date
    // A closure to notify the parent view when the log is updated.
    var onLogUpdated: (DailyLog) -> Void

    // State variables to manage user input and preferences:
    @State private var quantity: String = "1" // Default quantity set to 1 serving.
    @State private var customServingSize: String // Custom serving size entered by the user.
    @State private var selectedServingUnit: String // The unit of measurement (e.g., "g" or "oz").
    @State private var useCustomServing: Bool // Toggle to enable custom serving size.

    // Environment variables for view dismissal and service access:
    @Environment(\.dismiss) var dismiss // Allows dismissing the view programmatically.
    @EnvironmentObject var dailyLogService: DailyLogService // Provides access to log management.
    @Environment(\.presentationMode) var presentationMode // Used to dismiss the view via navigation.

    // Initializer to set up the view with the food item and initialize state variables.
    init(foodItem: FoodItem, dailyLog: Binding<DailyLog?>, date: Date = Date(), onLogUpdated: @escaping (DailyLog) -> Void) {
        self.foodItem = foodItem
        self._dailyLog = dailyLog
        self.date = date
        self.onLogUpdated = onLogUpdated

        // Initializes state with the food item's serving weight and unit.
        self._customServingSize = State(initialValue: String(Int(foodItem.servingWeight)))
        self._selectedServingUnit = State(initialValue: foodItem.servingSize.contains("oz") ? "oz" : "g")
        self._useCustomServing = State(initialValue: foodItem.servingWeight != 100.0) // Defaults to custom if not 100g.

        // Logs the food item details for debugging purposes.
        print("✅ Received FoodItem in Detail View: \(foodItem.name)")
        print("🔹 Base Calories (per serving): \(foodItem.calories)") // Original calories per serving.
        print("🔹 Protein: \(foodItem.protein)")
        print("🔹 Carbs: \(foodItem.carbs)")
        print("🔹 Fats: \(foodItem.fats)")
        print("🔹 Serving Weight: \(foodItem.servingWeight)g")
    }

    // Computed property to determine the base serving weight, defaulting to 100g if invalid.
    var baseServingWeight: Double {
        return foodItem.servingWeight > 0 ? foodItem.servingWeight : 100.0
    }

    // Computed property to convert between units (oz to g or vice versa).
    var conversionFactor: Double {
        return selectedServingUnit == "oz" ? 1 / 28.3495 : 1.0 // 1 oz = 28.3495g.
    }

    // Computed property to calculate adjusted nutrient values based on quantity and serving size.
    var adjustedNutrients: FoodItem {
        let enteredQuantity = Double(quantity) ?? 1.0 // Converts quantity to a double, defaults to 1.
        let customWeight = Double(customServingSize) ?? baseServingWeight // Custom weight or default.
        let convertedWeight = useCustomServing ? (customWeight * conversionFactor) : baseServingWeight // Applies unit conversion.
        let factor = enteredQuantity // Scales nutrients by the number of servings.

        return FoodItem(
            id: foodItem.id,
            name: foodItem.name,
            calories: foodItem.calories * factor, // Scales original calories by quantity.
            protein: foodItem.protein * factor,
            carbs: foodItem.carbs * factor,
            fats: foodItem.fats * factor,
            servingSize: "\(Int(convertedWeight))\(selectedServingUnit)", // Updated serving size.
            servingWeight: convertedWeight,
            timestamp: foodItem.timestamp // Preserves the original timestamp.
        )
    }

    // The main body of the view, wrapped in a ScrollView for content overflow.
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section for nutritional information.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutritional Information") // Section title.
                        .font(.headline) // Bold, larger font.

                    HStack {
                        Text("Item:") // Label for the food name.
                            .fontWeight(.bold)
                        Text(foodItem.name) // Displays the food name.
                    }

                    HStack {
                        Text("Calories:") // Label for calories.
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.calories, specifier: "%.0f") kcal") // Adjusted calorie count.
                    }

                    HStack {
                        Text("Carbs:") // Label for carbohydrates.
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.carbs, specifier: "%.1f")g") // Adjusted carbs.
                    }

                    HStack {
                        Text("Proteins:") // Label for protein.
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.protein, specifier: "%.1f")g") // Adjusted protein.
                    }

                    HStack {
                        Text("Fats:") // Label for fats.
                            .fontWeight(.bold)
                        Text("\(adjustedNutrients.fats, specifier: "%.1f")g") // Adjusted fats.
                    }
                }
                .padding() // Adds internal padding.
                .background(Color(.systemGray6)) // Light gray background.
                .cornerRadius(12) // Rounded corners.
                .padding(.horizontal) // Horizontal padding from edges.

                // Section for adjusting quantity and serving size.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adjust Quantity") // Section title.
                        .font(.headline) // Bold, larger font.

                    HStack {
                        Text("Servings:") // Label for servings.
                        TextField("1", text: $quantity) // Input for number of servings.
                            .keyboardType(.decimalPad) // Shows a numeric keypad.
                            .textFieldStyle(RoundedBorderTextFieldStyle()) // Styled text field.
                            .frame(width: 60) // Fixed width for the field.
                    }

                    Toggle("Use Custom Serving Size", isOn: $useCustomServing) // Toggle to enable custom size.
                        .padding(.top, 5) // Adds top padding.

                    if useCustomServing {
                        // Displays custom serving size options when toggled on.
                        HStack {
                            Text("Custom Size:") // Label for custom size.
                            TextField("\(Int(baseServingWeight))", text: $customServingSize) // Input for custom weight.
                                .keyboardType(.decimalPad) // Numeric keypad.
                                .textFieldStyle(RoundedBorderTextFieldStyle()) // Styled text field.
                                .frame(width: 80) // Fixed width.

                            Picker("Unit", selection: $selectedServingUnit) { // Unit selection.
                                Text("g").tag("g") // Gram option.
                                Text("oz").tag("oz") // Ounce option.
                            }
                            .pickerStyle(SegmentedPickerStyle()) // Segmented style for picker.
                            .frame(width: 100) // Fixed width.
                        }
                    } else {
                        // Displays recommended serving size when custom is off.
                        HStack {
                            Text("Recommended Size:") // Label for recommended size.
                                .fontWeight(.bold)
                            Text("\(Int(baseServingWeight))g") // Default serving weight.
                                .foregroundColor(.gray) // Gray color for secondary text.
                        }
                    }
                }
                .padding() // Adds internal padding.
                .background(Color(.systemGray6)) // Light gray background.
                .cornerRadius(12) // Rounded corners.
                .padding(.horizontal) // Horizontal padding from edges.

                // Button to add or update the food item in the log.
                Button(action: {
                    if var log = dailyLog {
                        // Check if the food item is already in the log to determine action.
                        let isUpdating = log.meals.contains { meal in
                            meal.foodItems.contains { $0.id == foodItem.id }
                        }

                        if isUpdating {
                            // Remove the old version of the food item if updating.
                            for i in log.meals.indices {
                                log.meals[i].foodItems.removeAll { $0.id == foodItem.id }
                            }
                            // Delete the old food item from the log for the specified date.
                            if let userID = Auth.auth().currentUser?.uid {
                                dailyLogService.deleteFoodFromCurrentLog(for: userID, foodItemID: foodItem.id, date: date)
                            }
                        }

                        // Add the adjusted food item to the log for the specified date.
                        if let userID = Auth.auth().currentUser?.uid {
                            dailyLogService.addFoodToCurrentLog(for: userID, foodItem: adjustedNutrients, date: date)
                            onLogUpdated(log) // Notify the parent of the update.
                        }
                    }
                    // Dismiss the view, handling nested navigation if present.
                    presentationMode.wrappedValue.dismiss() // Dismisses via navigation.
                    dismiss() // Dismisses the sheet if opened from FoodSearchView.
                }) {
                    // Dynamically set button text based on whether it’s an update or addition.
                    Text(dailyLog?.meals.contains { $0.foodItems.contains { $0.id == foodItem.id } } == true ? "Update Log" : "Add to Log")
                        .font(.headline) // Bold, larger font.
                        .foregroundColor(.white) // White text.
                        .padding() // Add internal padding.
                        .frame(maxWidth: .infinity) // Expand to full width.
                        .background(Color.blue) // Blue background.
                        .cornerRadius(12) // Rounded corners.
                }
                .padding(.horizontal) // Horizontal padding from edges.
            }
            .padding(.bottom, 20) // Add bottom padding for the scroll view.
        }
        .navigationTitle("Edit Food") // Set the navigation title.
        .navigationBarTitleDisplayMode(.inline) // Center the title.
    }
}
