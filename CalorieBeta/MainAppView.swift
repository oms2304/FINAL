import SwiftUI
import Firebase
import FirebaseAuth

// The main application entry point, defining the app structure and initializing services.
@main
struct CalorieBetaApp: App {
    // MARK: - State Objects
    
    /// Manages user nutritional goals.
    @StateObject var goalSettings = GoalSettings()
    
    /// Handles daily food log operations.
    @StateObject var dailyLogService = DailyLogService()
    
    /// Tracks user authentication state and dark mode preference.
    @StateObject var appState = AppState()
    
    /// Manages community group data.
    @StateObject var groupService = GroupService()

    // MARK: - Initialization
    
    /// Initializes Firebase services when the app starts.
    init() {
        FirebaseApp.configure() // Sets up Firebase with the default configuration.
        let _ = PhoneSessionManager.shared
    }

    // MARK: - Body
    
    /// Defines the app's window scene with the root content view.
    var body: some Scene {
        WindowGroup {
            ContentView() // The main content view of the app.
                .environmentObject(goalSettings) // Injects goal settings into the view hierarchy.
                .environmentObject(dailyLogService) // Injects daily log service.
                .environmentObject(appState) // Injects app state for authentication and dark mode.
                .environmentObject(groupService) // Injects group service for community features.
                .preferredColorScheme(appState.isDarkModeEnabled ? .dark : .light) // Applies the user's dark mode preference.
        }
    }
}

// The root view of the app, controlling navigation based on authentication and loading state.
// Also handles presenting the onboarding survey for first-time users.
struct ContentView: View {
    // MARK: - Environment Properties
    
    /// Environment object to access the app's authentication state and dark mode preference.
    @EnvironmentObject var appState: AppState
    
    /// Environment object to access and modify user goals.
    @EnvironmentObject var goalSettings: GoalSettings
    
    /// Environment object to access daily log data.
    @EnvironmentObject var dailyLogService: DailyLogService

    // MARK: - State Properties
    
    /// Tracks if initial data is being loaded.
    @State private var isLoading = true
    
    /// Stores the food item detected by the barcode scanner.
    @State private var scannedFoodItem: FoodItem?
    
    /// Controls visibility of the barcode scanner.
    @State private var showScanner = false
    
    /// Controls visibility of the food detail view.
    @State private var showFoodDetail = false
    
    /// Controls visibility of the onboarding survey for first-time users.
    @State private var showSurvey = false

    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                // Show a landing page while initial data is being loaded.
                LandingPageView()
                    .onAppear {
                        loadInitialData()
                    }
            } else if appState.isUserLoggedIn {
                if showSurvey {
                    // Show the onboarding survey if this is the user's first login.
                    OnboardingSurveyView()
                        .environmentObject(goalSettings)
                } else {
                    // Show the main app interface for logged-in users.
                    MainTabView()
                        .onAppear(perform: loadUserData)
                }
            } else {
                // Show the welcome screen for unauthenticated users.
                WelcomeView()
                    .onAppear(perform: checkLoginStatus)
            }
        }
        .sheet(isPresented: $showScanner) {
            // Present the barcode scanner as a sheet.
            BarcodeScannerView { foodItem in
                DispatchQueue.main.async {
                    scannedFoodItem = foodItem
                    showScanner = false
                    showFoodDetail = true
                }
            }
        }
        .background(
            // Hidden NavigationLink for programmatic navigation to FoodDetailView.
            NavigationLink(
                destination: scannedFoodItem.map { FoodDetailView(foodItem: $0, dailyLog: .constant(nil), onLogUpdated: { _ in }) },
                isActive: $showFoodDetail
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    // MARK: - Helper Methods
    
    /// Checks the current authentication status when the view appears.
    private func checkLoginStatus() {
        if let currentUser = Auth.auth().currentUser {
            print("✅ User is already logged in: \(currentUser.uid)")
            appState.isUserLoggedIn = true
            checkFirstLogin(userID: currentUser.uid)
            isLoading = false
        } else {
            print("❌ No user logged in")
            appState.isUserLoggedIn = false
            isLoading = false
        }
    }

    /// Checks if this is the user's first login by looking for the isFirstLogin flag in Firestore.
    /// If true, the onboarding survey is presented.
    /// - Parameter userID: The ID of the authenticated user.
    private func checkFirstLogin(userID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let isFirstLogin = data["isFirstLogin"] as? Bool, isFirstLogin {
                    DispatchQueue.main.async {
                        self.showSurvey = true
                    }
                }
            } else {
                print("❌ Error checking first login: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    /// Loads initial data when the app starts, running on a background thread if needed.
    private func loadInitialData() {
        if appState.isUserLoggedIn {
            DispatchQueue.global(qos: .background).async {
                loadUserData()
            }
        } else {
            isLoading = false
        }
    }

    /// Loads user data (goals and daily log) from Firestore.
    private func loadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user ID found, user not logged in")
            isLoading = false
            return
        }
        print("📥 Fetching data for User ID: \(userID) at \(Date())")

        // Load user goals and check for first login after loading.
        goalSettings.loadUserGoals(userID: userID) {
            self.checkFirstLogin(userID: userID)
        }
        
        // Load or create today's log.
        dailyLogService.fetchOrCreateTodayLog(for: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let log):
                    print("✅ Loaded today's log: \(log) at \(Date())")
                    dailyLogService.currentDailyLog = log
                    isLoading = false
                    let dataToSend: [String: Any] = [
                        "date": log.date,
                        "water": log.totalCalories(),
                        "calories": log.totalMacros().carbs
                    ]
                    PhoneSessionManager.shared.sendDataToWatch(dataToSend)

                case .failure(let error):
                    print("❌ Error loading user logs: \(error.localizedDescription) at \(Date())")
                    isLoading = false
                }
            }
        }
    }
}
