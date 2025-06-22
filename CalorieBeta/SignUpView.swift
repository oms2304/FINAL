import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// A view that provides a sign-up interface for users to create a new account.
/// After successful sign-up, it presents an onboarding survey for new users to set their goals.
struct SignUpView: View {
    // MARK: - State Properties
    
    /// State variables to manage user input for the sign-up form.
    @State private var email = "" // User's email address.
    @State private var password = "" // User's password.
    @State private var confirmPassword = "" // Confirmation of the password.
    @State private var username = "" // User's chosen username.
    @State private var signUpError = "" // Error message to display if sign-up fails.
    @State private var showSurvey = false // Controls the presentation of the onboarding survey.
    
    // MARK: - Environment Properties
    
    /// Environment variable to control dismissal of the view.
    @Environment(\.presentationMode) var presentationMode
    
    /// Environment object to access and modify user goals, used by the survey.
    @EnvironmentObject var goalSettings: GoalSettings

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) { // Vertical stack with no spacing between sections.
            // MARK: - Header Section
            ZStack { // Layers the background image, text, and close button.
                // Background Image with Dark Overlay
                Image("salad") // Placeholder for a background image (must be added to assets).
                    .resizable() // Allows the image to be resized.
                    .scaledToFill() // Fills the frame while maintaining aspect ratio.
                    .clipped() // Clips any overflow.
                    .overlay(Color.black.opacity(0.65)) // Adds a dark overlay for contrast.

                // Text Content Centered Vertically
                VStack(spacing: 10) {
                    Text("Create Your Account!") // Welcome message for sign-up.
                        .font(.largeTitle) // Large, prominent font.
                        .fontWeight(.bold) // Bold text for emphasis.
                        .foregroundColor(.white) // White text for contrast against the dark overlay.
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Centers the text.

                // Close Button in Top-Right Corner
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Dismisses the view when tapped.
                }) {
                    Image(systemName: "xmark.circle.fill") // Close icon.
                        .font(.title) // Larger font size for visibility.
                        .foregroundColor(.white) // White icon for contrast.
                }
                .position(x: UIScreen.main.bounds.width - 25, y: 60) // Hardcoded position in top-right corner.
            }
            .frame(height: 200) // Fixed height for the header section.

            // MARK: - Join Now and Form Section
            VStack(spacing: 16) { // Vertical stack with spacing between elements.
                VStack(spacing: 16) {
                    // Username input field using the shared RoundedTextField from Model.
                    RoundedTextField(placeholder: "Username", text: $username)
                    // Email input field using the shared RoundedTextField from Model.
                    RoundedTextField(placeholder: "Email", text: $email, isEmail: true)
                    // Password input field using the shared RoundedSecureField from Model.
                    RoundedSecureField(placeholder: "Password", text: $password)
                    // Confirm password input field using the shared RoundedSecureField from Model.
                    RoundedSecureField(placeholder: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal) // Adds horizontal padding to the input fields.

                // Error Message
                if !signUpError.isEmpty { // Shows error message if present.
                    Text(signUpError) // Displays the error text.
                        .foregroundColor(.red) // Red color for error visibility.
                        .font(.caption) // Smaller font for the error message.
                        .padding(.top, 10) // Adds space above the error message.
                }
                Spacer() // Pushes the button to the bottom of the form section.

                // Submit Button
                Button(action: signUpUser) { // Sign-up button.
                    Text("Join Now") // Button label.
                        .font(.title2) // Slightly larger font for emphasis.
                        .fontWeight(.semibold) // Semibold text for readability.
                        .frame(maxWidth: .infinity) // Expands to full width.
                        .padding() // Adds internal padding.
                        .background(Color.green) // Green background for visibility.
                        .foregroundColor(.black) // Black text for contrast.
                        .cornerRadius(30) // Rounded corners for a modern look.
                }
                .padding(.horizontal) // Adds horizontal padding around the button.
            }
            .padding(.top, 20) // Adds space above the form section.
            .background( // Applies a styled background to the form section.
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30)) // Rounds the top corners using CustomCorners from Model.
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensures a white background across the entire view.
        .sheet(isPresented: $showSurvey) {
            // Present the onboarding survey as a sheet after successful sign-up.
            OnboardingSurveyView()
                .environmentObject(goalSettings)
        }
    }

    // MARK: - Helper Methods
    
    /// Handles user sign-up using Firebase Authentication and saves user data to Firestore.
    private func signUpUser() {
        // Validate username.
        guard !username.isEmpty else {
            signUpError = "Username is required"
            return
        }

        // Validate password match.
        guard password == confirmPassword else {
            signUpError = "Passwords do not match"
            return
        }

        // Create a new user with Firebase Authentication.
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                signUpError = error.localizedDescription
                return
            }

            if let user = authResult?.user {
                saveUserData(user: user)
            }
        }
    }

    /// Saves user data to Firestore, including initial goals and calorie history.
    /// Sets the isFirstLogin flag to true to trigger the onboarding survey.
    /// - Parameter user: The authenticated Firebase user.
    private func saveUserData(user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "userID": user.uid,
            "username": username,
            "goals": [
                "calories": 2000, // Default value, will be overwritten by survey.
                "protein": 150,
                "fats": 70,
                "carbs": 250
            ],
            "weight": 150.0,
            "isFirstLogin": true // Flag to indicate this is the user's first login.
        ]

        // Save user data to Firestore.
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                // Initialize calorie history for the user.
                db.collection("users").document(user.uid).collection("calorieHistory").addDocument(data: [
                    "date": Timestamp(date: Date()),
                    "calories": 0.0
                ]) { historyError in
                    if let historyError = historyError {
                        print("Error initializing calorie history: \(historyError.localizedDescription)")
                    } else {
                        print("Calorie history initialized for user \(user.uid).")
                        // Show the survey after successful sign-up and data initialization.
                        self.showSurvey = true
                    }
                }
            }
        }
    }
}
