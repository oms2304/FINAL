import SwiftUI
import FirebaseAuth
import UserNotifications
import FirebaseFirestore

// This class manages the application's global state, including authentication status and dark mode preference,
// and notifies views of changes using the ObservableObject protocol.
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    /// Published property to track whether a user is logged in, triggering UI updates in SwiftUI.
    @Published var isUserLoggedIn: Bool = false
    
    /// Published property to track the user's dark mode preference, updating the UI when changed.
    @Published var isDarkModeEnabled: Bool = false
    
    // MARK: - Private Properties
    
    /// Firestore database instance for loading and saving preferences.
    private let db = Firestore.firestore()

    // MARK: - Initialization
    
    /// Initializes the AppState, sets up authentication state listening, requests notification permissions,
    /// and loads the dark mode preference for the logged-in user.
    init() {
        // Request notification permissions when the app initializes.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Error requesting notification permission: \(error.localizedDescription)")
            }
        }

        // Adds a listener to detect changes in the Firebase Authentication state.
        Auth.auth().addStateDidChangeListener { auth, user in
            // Ensures UI updates occur on the main thread.
            DispatchQueue.main.async {
                if let user = user { // Checks if a user is authenticated.
                    print("✅ Firebase Auth State Changed: User logged in: \(user.uid)") // Logs successful login.
                    self.isUserLoggedIn = true // Updates the state to reflect login.
                    self.loadDarkModePreference(userID: user.uid) // Load dark mode preference on login.
                } else { // Handles the case where no user is authenticated.
                    print("❌ Firebase Auth State Changed: No user logged in") // Logs logout.
                    self.isUserLoggedIn = false // Updates the state to reflect logout.
                    self.isDarkModeEnabled = false // Reset to light mode on logout.
                }
            }
        }
    }

    // MARK: - Public Methods
    
    /// Manually sets the login state, useful for testing or manual state changes.
    /// - Parameter loggedIn: The new login state (true for logged in, false for logged out).
    func setUserLoggedIn(_ loggedIn: Bool) {
        // Ensures the state update occurs on the main thread to avoid UI issues.
        DispatchQueue.main.async {
            self.isUserLoggedIn = loggedIn // Updates the published property.
            if !loggedIn {
                self.isDarkModeEnabled = false // Reset to light mode on logout.
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads the user's dark mode preference from Firestore.
    /// - Parameter userID: The ID of the authenticated user.
    private func loadDarkModePreference(userID: String) {
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("❌ Error loading dark mode preference: \(error.localizedDescription)")
                self.isDarkModeEnabled = false // Default to light mode on error.
            } else if let document = document, document.exists,
                      let data = document.data(),
                      let darkMode = data["darkMode"] as? Bool {
                self.isDarkModeEnabled = darkMode // Set the dark mode state.
                print("✅ Loaded dark mode preference: \(darkMode)")
            } else {
                self.isDarkModeEnabled = false // Default to light mode if not set.
                print("ℹ️ No dark mode preference found, defaulting to light mode")
            }
        }
    }
}
