import SwiftUI

// This view allows users to input their height in feet and inches, which is used for calorie calculations.
// It integrates with GoalSettings to save and retrieve height data.
struct SetHeightView: View {
    // Environment object to access and modify the user's goal settings, including height.
    @EnvironmentObject var goalSettings: GoalSettings // Use EnvironmentObject to access GoalSettings
    // State variables to manage user input for height.
    @State private var feet: String = "" // Stores the feet portion of the height.
    @State private var inches: String = "" // Stores the inches portion of the height.

    // The main body of the view, organized in a vertical stack.
    var body: some View {
        VStack(spacing: 16) {
            // Title for the height input screen.
            Text("Enter Your Height")
                .font(.title) // Large, bold font for emphasis.
                .padding(.bottom) // Adds space below the title.

            // Horizontal stack for the feet and inches input fields.
            HStack {
                // Vertical stack for the feet input.
                VStack {
                    TextField("Feet", text: $feet) // Input field for feet.
                        .keyboardType(.numberPad) // Shows a numeric keypad.
                        .padding() // Adds internal padding.
                        .background(Color(.systemGray6)) // Light gray background.
                        .cornerRadius(8) // Rounded corners.
                        .frame(width: 100) // Fixed width for the field.
                }
                Text("'") // Displays a single quote to indicate feet.
                // Vertical stack for the inches input.
                VStack {
                    TextField("Inches", text: $inches) // Input field for inches.
                        .keyboardType(.numberPad) // Numeric keypad.
                        .padding() // Adds internal padding.
                        .background(Color(.systemGray6)) // Light gray background.
                        .cornerRadius(8) // Rounded corners.
                        .frame(width: 100) // Fixed width.
                }
                Text("\"") // Displays a double quote to indicate inches.
            }

            // Button to save the entered height.
            Button(action: saveHeight) {
                Text("Save") // Button label.
                    .frame(maxWidth: .infinity) // Expands to full width.
                    .padding() // Adds internal padding.
                    .background(Color.green) // Green background for visibility.
                    .foregroundColor(.white) // White text for contrast.
                    .cornerRadius(8) // Rounded corners.
            }
            .padding(.top, 16) // Adds space above the button.

            Spacer() // Pushes content to the top, leaving space at the bottom.
        }
        .padding() // Adds padding around the entire view.
        .onAppear {
            // Loads the user's saved height when the view appears.
            let height = goalSettings.getHeightInFeetAndInches() // Retrieves height in feet and inches.
            feet = "\(height.feet)" // Sets the feet field.
            inches = "\(height.inches)" // Sets the inches field.
        }
    }

    // Saves the entered height to GoalSettings if the input is valid.
    private func saveHeight() {
        // Converts input strings to integers and validates them.
        if let feetValue = Int(feet), let inchesValue = Int(inches), feetValue >= 0, inchesValue >= 0, inchesValue < 12 {
            // Saves the height to GoalSettings if the values are valid (feet >= 0, inches >= 0 and < 12).
            goalSettings.setHeight(feet: feetValue, inches: inchesValue)
        }
    }
}
