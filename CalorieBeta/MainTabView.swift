import SwiftUI
import FirebaseAuth

// MARK: - MainTabView
/// The main tabbed navigation interface for the MyFitPlate app, providing access to Home, AI Chatbot, and Weight Chart tabs.
/// This view manages tab selection, handles navigation to UserProfileView, and presents SettingsView as a sheet.
/// It serves as the root navigation container, integrating with environment objects for data management.
struct MainTabView: View {
    // MARK: - State Variables
    /// Tracks the currently selected tab index (0: Home, 1: AI Chatbot, 2: Weight Chart).
    @State private var selectedTab = 0
    
    // MARK: - State Objects
    /// Initializes GoalSettings to manage user-defined goals (e.g., calories, weight) and weight history.
    @StateObject private var goalSettings = GoalSettings()
    /// Initializes DailyLogService to manage interactions with Firebase Firestore for daily logs.
    @StateObject private var dailyLogService = DailyLogService()

    // MARK: - State for Navigation and Presentation
    /// Controls navigation to UserProfileView via a hidden NavigationLink, passed to HomeView.
    @State private var navigateToProfile = false
    /// Toggles the visibility of the SettingsView as a modal sheet.
    @State private var showSettings = false

    // MARK: - Environment
    /// Detects the current color scheme to adapt the UI for light or dark mode.
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body
    var body: some View {
        // TabView: The primary navigation structure, containing multiple tabs with distinct content.
        /// The accentColor is set to green (#43AD6F) to align with the app's branding and active tab indicators.
        /// Each tab's NavigationView is managed within the respective view (e.g., HomeView) to avoid conflicts.
        TabView(selection: $selectedTab) {
            // Home Tab: Displays the main dashboard for calorie tracking and food diary.
            HomeView(
                navigateToProfile: $navigateToProfile,
                showSettings: $showSettings
            )
            .tabItem {
                Image(systemName: "house")
                    .foregroundColor(selectedTab == 0 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
                Text("Home")
                    .foregroundColor(selectedTab == 0 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
            }
            .tag(0)
            
            // AI Chatbot Tab: Provides an interface for interacting with the AI chatbot.
            NavigationView {
                AIChatbotView(selectedTab: $selectedTab)
//                    .navigationTitle("AI Chatbot")
                    .navigationBarTitleDisplayMode(.inline) // Ensures consistent title display.
            }
            .tabItem {
                Image(systemName: "message")
                    .foregroundColor(selectedTab == 1 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
                Text("AI Chatbot")
                    .foregroundColor(selectedTab == 1 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
            }
            .tag(1)
            
            // Weight Chart Tab: Displays the user's weight history in a graphical format.
            NavigationView {
                WeightTrackingView()
                    .navigationTitle("Weight Chart")
                    .navigationBarTitleDisplayMode(.inline) // Ensures consistent title display.
            }
            .tabItem {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(selectedTab == 2 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
                Text("Weight Chart")
                    .foregroundColor(selectedTab == 2 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
            }
            .tag(2)
            
            NavigationView {
                WatchAppTestView()
                    .navigationTitle("message")
                    .navigationBarTitleDisplayMode(.inline) // Ensures consistent title display.
            }
            .tabItem {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(selectedTab == 3 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
                Text("Weight Chart")
                    .foregroundColor(selectedTab == 3 ? Color(red: 67/255, green: 173/255, blue: 111/255) : (colorScheme == .dark ? .white : .black))
            }
            .tag(3)
        }
        .accentColor(Color(red: 67/255, green: 173/255, blue: 111/255))
        // Apply a background color to the tab bar to ensure it adapts to dark mode.
        .onAppear {
//            PhoneSessionManager.shared.pingWatch()
            // Customize the tab bar appearance for dark mode.
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = colorScheme == .dark ? UIColor.systemBackground : UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        // SettingsView Sheet: Presented when showSettings is true, managed by the hamburger menu.
        /// The NavigationView ensures proper navigation within the settings interface, using StackNavigationViewStyle for iPad compatibility.
        /// The environment objects (dailyLogService, goalSettings) are passed, and appState is available via the environment injected by MainAppView.
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView(showSettings: $showSettings)
                    .environmentObject(dailyLogService)
                    .environmentObject(goalSettings)
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .onAppear {
            // Load the user's weight history and daily log when the view appears.
            goalSettings.loadWeightHistory()
            if let userID = Auth.auth().currentUser?.uid {
                // Fetch the current day's log to ensure it's available for all tabs.
                dailyLogService.fetchOrCreateTodayLog(for: userID) { result in
                    switch result {
                    case .success(let log):
                        dailyLogService.currentDailyLog = log
                        print("✅ Loaded today's log in MainTabView: \(log.id ?? "nil")")
                    case .failure(let error):
                        print("❌ Error loading today's log in MainTabView: \(error.localizedDescription)")
                    }
                }
                // Load user goals to ensure they are up-to-date.
                goalSettings.loadUserGoals(userID: userID)
            }
        }
        // Inject environment objects into the view hierarchy.
        .environmentObject(goalSettings)
        .environmentObject(dailyLogService)
    }
}
