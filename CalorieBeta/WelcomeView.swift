import SwiftUI

// G3: A new welcome view to serve as the entry point for unauthenticated users,
// providing options to log in or create an account.
struct WelcomeView: View {
    // State variables to control navigation to login or sign-up views.
    @State private var showLoginView = false // G3: Controls navigation to LoginView.
    @State private var showSignUpView = false // G3: Controls navigation to SignUpView.

    // The main body of the view, designed to be visually appealing and functional.
    var body: some View {
        VStack(spacing: 0) { // G3: Vertical stack with no spacing between header and content.
            // Header with Background Image
            ZStack {
                // Background Image with Blur and Dark Overlay
                Image("healthy") // G3: Reuses the "healthy" image from LoginView for consistency (ensure it’s in assets).
                    .resizable() // Allows the image to be resized.
                    .scaledToFill() // Fills the frame while maintaining aspect ratio.
                    .clipped() // Clips any overflow.
                    .overlay(Color.black.opacity(0.65)) // Adds a dark overlay for contrast.
                    .blur(radius: 6) // Applies a blur effect for a soft look.

                // Welcome Text
                VStack(spacing: 10) {
                    Text("Welcome to MyFitPlate!") // G3: Friendly welcome message with app branding.
                        .font(.largeTitle) // Large, prominent font.
                        .fontWeight(.bold) // Bold text for emphasis.
                        .foregroundColor(.white) // White text for contrast against the dark overlay.
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Centers the text.
            }
            .frame(height: 200) // Fixed height for the header section.

            // Buttons Section
            VStack(spacing: 20) { // G3: Vertical stack with spacing between buttons.
                // Login Button
                Button(action: {
                    showLoginView = true // G3: Triggers navigation to LoginView.
                }) {
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

                // Sign Up Button
                Button(action: {
                    showSignUpView = true // G3: Triggers navigation to SignUpView.
                }) {
                    Text("Create Account") // G3: Button label for account creation.
                        .font(.title2) // Slightly larger font for emphasis.
                        .fontWeight(.semibold) // Semibold text for readability.
                        .frame(maxWidth: .infinity) // Expands to full width.
                        .padding() // Adds internal padding.
                        .background(Color.blue) // G3: Blue background to differentiate from Login.
                        .foregroundColor(.white) // White text for contrast.
                        .cornerRadius(30) // Rounded corners for a modern look.
                }
                .padding(.horizontal) // Adds horizontal padding around the button.
            }
            .padding(.top, 20) // Adds space above the buttons section.
            .background( // Applies a styled background to the buttons section.
                Color.white
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 30)) // Rounds the top corners.
            )
        }
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensures a white background across the entire view.
        .sheet(isPresented: $showLoginView) { // G3: Presents LoginView as a sheet.
            LoginView()
        }
        .sheet(isPresented: $showSignUpView) { // G3: Presents SignUpView as a sheet.
            SignUpView()
        }
    }
}
