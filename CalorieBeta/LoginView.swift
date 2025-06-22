import SwiftUI
import FirebaseAuth
import Firebase

/// This view provides a login interface for users to sign in using their email and password,
/// integrating with Firebase Authentication and Firestore for user data retrieval.
struct LoginView: View {
    // MARK: - State Properties
    
    /// State variables to manage user input and UI state.
    @State private var email = "" // Stores the email input.
    @State private var password = "" // Stores the password input.
    @State private var loginError = "" // Stores any error message to display.
    
    // MARK: - Environment Properties
    
    /// Environment variable to control dismissal of the view.
    @Environment(\.presentationMode) var presentationMode

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) { // Vertical stack with no spacing between sections.
            // MARK: - Header Section
            ZStack { // Layers the background image and text content.
                // Background Image with Blur and Dark Overlay
                Image("healthy") // Placeholder for a background image (must be added to assets).
                    .resizable() // Allows the image to be resized.
                    .scaledToFill() // Fills the frame while maintaining aspect ratio.
                    .clipped() // Clips any overflow.
                    .overlay(Color.black.opacity(0.65)) // Adds a dark overlay for contrast.
                    .blur(radius: 6) // Applies a blur effect for a soft look.

                // Text Content Centered Vertically
                VStack(spacing: 10) {
                    Text("Welcome Back!") // Welcome message.
                        .font(.largeTitle) // Large, prominent font.
                        .fontWeight(.bold) // Bold text for emphasis.
                        .foregroundColor(.white) // White text for contrast against the dark overlay.
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Centers the text.
            }
            .frame(height: 200) // Fixed height for the header section.

            // MARK: - Login Form Section
            VStack(spacing: 16) { // Vertical stack with spacing between elements.
                VStack(spacing: 16) {
                    // Email input field using the shared RoundedTextField from Model.
                    RoundedTextField(placeholder: "Enter your email", text: $email, isEmail: true)
                    // Password input field using the shared RoundedSecureField from Model.
                    RoundedSecureField(placeholder: "Enter your password", text: $password)
                }
                .padding(.horizontal) // Adds horizontal padding to the input fields.

                // Error Message
                if !loginError.isEmpty { // Shows error message if present.
                    Text(loginError) // Displays the error text.
                        .foregroundColor(.red) // Red color for error visibility.
                        .font(.caption) // Smaller font for the error message.
                        .padding(.top, 10) // Adds space above the error message.
                }
                Spacer() // Pushes the buttons to the bottom of the form section.

                // MARK: - Buttons Section
                VStack(spacing: 10) { // Vertical stack for the buttons.
                    Button(action: loginUser) { // Login button.
                        Text("Login") // Button label.
                            .font(.title2) // Slightly larger font for emphasis.
                            .fontWeight(.semibold) // Semibold text for readability.
                            .frame(maxWidth: .infinity) // Expands to full width.
                            .padding() // Adds internal padding.
                            .background(Color.green) // Green background for visibility.
                            .foregroundColor(.black) // Black text for contrast.
                            .cornerRadius(30) // Rounded corners for a modern look.
                    }
                    .padding(.horizontal) // Adds horizontal padding around the button.

                    Button(action: clearFields) { // Clear button.
                        Text("Clear") // Button label.
                            .font(.body) // Standard font size.
                            .fontWeight(.medium) // Medium weight for readability.
                            .frame(maxWidth: .infinity) // Expands to full width.
                            .padding() // Adds internal padding.
                            .background(Color.gray.opacity(0.3)) // Light gray background.
                            .foregroundColor(.black) // Black text for contrast.
                            .cornerRadius(30) // Rounded corners.
                    }
                    .padding(.horizontal) // Adds horizontal padding.
                }
            }
            .padding(.top, 20) // Adds space above the form section.
            .background( // Applies a styled background to the form section.
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30)) // Rounds the top corners using CustomCorners from Model.
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensures a white background across the entire view.
    }

    // MARK: - Helper Methods
    
    /// Handles user login using Firebase Authentication.
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error { // Checks for authentication errors.
                loginError = error.localizedDescription // Sets the error message to display.
                return
            }

            if let user = authResult?.user { // Ensures a user was authenticated.
                fetchUserData(user: user) // Fetches additional user data from Firestore.
            }
        }
    }

    /// Retrieves user data from Firestore after successful login.
    /// - Parameter user: The authenticated Firebase user.
    private func fetchUserData(user: FirebaseAuth.User) {
        let db = Firestore.firestore() // Initializes the Firestore database instance.
        // Fetches the user document from Firestore using the user's UID.
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists { // Checks if the document exists.
                if let data = document.data() { // Retrieves the document data.
                    print("User data: \(data)") // Logs the user data for debugging.
                    presentationMode.wrappedValue.dismiss() // Dismisses the view on successful login.
                }
            } else { // Handles missing user data.
                loginError = "User data not found." // Sets an error message.
            }
        }
    }

    /// Clears all input fields and error messages.
    private func clearFields() {
        email = "" // Resets email field.
        password = "" // Resets password field.
        loginError = "" // Clears any error message.
    }
}
