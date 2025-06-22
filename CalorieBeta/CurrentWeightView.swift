import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// This view allows users to enter their current weight, updating it in the GoalSettings model
// and saving it to Firestore, typically presented as a sheet from the WeightTrackingView.
struct CurrentWeightView: View {
    // Environment object to access and modify user goals and weight data.
    @EnvironmentObject var goalSettings: GoalSettings
    // State variable to manage the weight input as a string.
    @State private var weight = ""
    // Environment variable to dismiss the view.
    @Environment(\.dismiss) var dismiss

    // The main body of the view, using a Form for structured input.
    var body: some View {
        Form { // Creates a form-style layout for input.
            Section(header: Text("Current Weight")) { // Section with a header for clarity.
                TextField("Enter your weight (lbs)", text: $weight) // Input field for weight.
                    .keyboardType(.decimalPad) // Shows a decimal keyboard for numeric input.
            }

            Button(action: { // Button to save the weight and dismiss the view.
                saveWeight() // Saves the entered weight.
                dismiss() // Closes the sheet.
            }) {
                Text("Save Weight") // Button label.
                    .font(.title2) // Slightly larger font for emphasis.
                    .frame(maxWidth: .infinity) // Expands to full width.
                    .padding() // Adds internal padding.
                    .background(Color.blue) // Blue background for visibility.
                    .foregroundColor(.white) // White text for contrast.
                    .cornerRadius(10) // Rounded corners for a modern look.
            }
            .padding(.top) // Adds space above the button.
        }
        .navigationTitle("Current Weight") // Sets the navigation bar title.
        .onAppear { // Sets the initial weight value when the view appears.
            weight = String(format: "%.1f", goalSettings.weight) // Formats the current weight to one decimal place.
        }
    }

    // Saves the entered weight to the GoalSettings model, ensuring it's a valid positive number.
    private func saveWeight() {
        guard let weightValue = Double(weight), weightValue > 0 else { return } // Validates input.
        goalSettings.updateUserWeight(weightValue) // Updates the weight in GoalSettings.
    }
}
