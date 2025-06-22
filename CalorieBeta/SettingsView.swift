import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// This view provides a settings interface for users to manage their profile data, appearance settings, and log out,
// presented as a sheet with navigation links to related views, integrated with Firebase.
struct SettingsView: View {
    // MARK: - Environment and State Properties
    
    /// Environment object to access and modify user goals.
    @EnvironmentObject var goalSettings: GoalSettings
    
    /// Environment object to manage the app's authentication state and dark mode preference.
    @EnvironmentObject var appState: AppState
    
    /// Binding to control the visibility of the settings sheet.
    @Binding var showSettings: Bool
    
    /// State to track if the dark mode preference is being loaded.
    @State private var isLoadingPreference: Bool = true
    
    /// Firestore database instance for saving and loading preferences.
    private let db = Firestore.firestore()

    // MARK: - Body
    
    var body: some View {
        List { // Creates a list-style layout for settings options.
            // Section for profile settings.
            Section(header: Text("Profile")) {
                // Navigation link to calculate caloric intake.
                NavigationLink(destination: CaloricCalculatorView()) {
                    Text("Calculate Caloric Intake") // Label for the navigation link.
                }

                // Navigation link to set current weight.
                NavigationLink(destination: CurrentWeightView().environmentObject(goalSettings)) {
                    Text("Set Current Weight (lbs)") // Label for the navigation link.
                }

                // Navigation link to set height.
                NavigationLink(destination: SetHeightView().environmentObject(goalSettings)) {
                    Text("Set Height (cm)") // Label for the navigation link.
                }
            }
            
            // Section for appearance settings, including dark mode toggle.
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $appState.isDarkModeEnabled) // Toggle bound to AppState's dark mode property.
                    .disabled(isLoadingPreference) // Disable toggle while loading the preference.
                    .onChange(of: appState.isDarkModeEnabled) { newValue in
                        saveDarkModePreference(newValue) // Save the new preference to Firestore.
                    }
            }

            // Section for account actions, such as logging out.
            Section(header: Text("Account")) {
                Button("Log Out") { // Button to initiate logout.
                    logOutUser() // Calls the logout function.
                }
                .foregroundColor(.red) // Red color to indicate a critical action.
            }
        }
        .navigationTitle("Settings") // Sets the navigation bar title.
        .navigationBarBackButtonHidden(true) // Hides the default back button.
        .navigationBarItems(leading: // Adds a custom "Home" button.
            Button(action: {
                showSettings = false // Dismisses the settings sheet.
            }) {
                Image(systemName: "chevron.left") // Left arrow icon.
                Text("Home") // Label for the button.
            }
            .foregroundColor(.blue) // Blue color for visibility.
        )
        .onAppear {
            loadDarkModePreference() // Load the dark mode preference when the view appears.
        }
    }

    // MARK: - Helper Methods
    
    /// Loads the user's dark mode preference from Firestore.
    private func loadDarkModePreference() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in, cannot load dark mode preference")
            appState.isDarkModeEnabled = false // Default to light mode if no user is logged in.
            isLoadingPreference = false
            return
        }
        
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("❌ Error loading dark mode preference: \(error.localizedDescription)")
                self.appState.isDarkModeEnabled = false // Default to light mode on error.
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let darkMode = data["darkMode"] as? Bool {
                self.appState.isDarkModeEnabled = darkMode // Set the dark mode state.
                print("✅ Loaded dark mode preference: \(darkMode)")
            } else {
                self.appState.isDarkModeEnabled = false // Default to light mode if not set.
                print("ℹ️ No dark mode preference found, defaulting to light mode")
            }
            self.isLoadingPreference = false // Mark loading as complete.
        }
    }
    
    /// Saves the user's dark mode preference to Firestore.
    /// - Parameter enabled: The new dark mode state (true for dark, false for light).
    private func saveDarkModePreference(_ enabled: Bool) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in, cannot save dark mode preference")
            return
        }
        
        db.collection("users").document(userID).setData(["darkMode": enabled], merge: true) { error in
            if let error = error {
                print("❌ Error saving dark mode preference: \(error.localizedDescription)")
            } else {
                print("✅ Saved dark mode preference: \(enabled)")
            }
        }
    }
    
    /// Logs out the user from Firebase and updates the app state.
    private func logOutUser() {
        do {
            try Auth.auth().signOut() // Attempts to sign out the user from Firebase.
            appState.setUserLoggedIn(false) // Updates the app state to reflect logout.
        } catch { // Handles any errors during sign-out.
            print("❌ Error signing out: \(error.localizedDescription)") // Logs the error for debugging.
        }
    }
}
