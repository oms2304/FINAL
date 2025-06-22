import SwiftUI
import FirebaseAuth

// This view displays a user's profile, including their stats, achievements, posts, and daily history,
// integrating with Firebase for data retrieval and presenting data in a scrollable format.
struct UserProfileView: View {
    // Environment objects to access shared state and services.
    @EnvironmentObject var dailyLogService: DailyLogService // Manages daily logs, posts, and achievements.
    @EnvironmentObject var goalSettings: GoalSettings // Manages user goals and profile data.
    @Environment(\.presentationMode) var presentationMode // Used to dismiss the view.
    // State variables to manage data and UI state.
    @State private var posts: [Post] = [] // Stores the user's posts.
    @State private var achievements: [Achievement] = [] // Stores the user's achievements.
    @State private var dailyHistory: [DailyLog] = [] // Stores the user's daily log history.
    @State private var errorMessage: ErrorMessage? // Manages error messages for alerts.

    // The main body of the view, using a ScrollView for content.
    var body: some View {
        ScrollView { // Enables scrolling for long content.
            VStack(spacing: 20) { // Vertical stack with spacing between sections.
                profileHeader() // Displays the user's profile header.
                dailyStats() // Shows daily stats like calorie goal and BMI.
                achievementsSection() // Displays user achievements.
                postsSection() // Displays user posts.
                dailyHistorySection() // Displays daily log history.
            }
            .padding() // Adds padding around the entire content.
        }
        .onAppear {
            loadUserData() // Loads user data when the view appears.
        }
        .alert(item: $errorMessage) { message in // Shows an alert if an error occurs.
            Alert(title: Text("Error"), message: Text(message.text), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Profile") // Sets the navigation bar title.
        .navigationBarBackButtonHidden(true) // Hides the default back button.
        .navigationBarItems(leading: // Adds a custom back button.
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Dismisses the view to return to HomeView.
            }) {
                Image(systemName: "chevron.left") // Left arrow icon.
                Text("Home") // Label for the back button.
            }
            .foregroundColor(.blue) // Blue color for visibility.
        )
    }

    // MARK: - Profile Header
    // Builds the profile header with a placeholder image and user info.
    func profileHeader() -> some View {
        VStack(spacing: 8) { // Vertical stack with spacing between elements.
            Image(systemName: "person.crop.circle") // Placeholder for profile image.
                .resizable() // Allows resizing.
                .frame(width: 80, height: 80) // Fixed size for the image.
                .foregroundColor(.gray) // Gray color for the placeholder.
            Text("Fitness Journey") // Placeholder title (could be dynamic).
                .font(.title2) // Slightly larger font.
                .fontWeight(.bold) // Bold text for emphasis.
            Text("@MFP") // Placeholder username (replace with dynamic data).
                .foregroundColor(.gray) // Gray color for secondary text.
        }
    }

    // MARK: - Daily Stats
    // Displays daily stats like calorie goal and BMI in a horizontal layout.
    func dailyStats() -> some View {
        HStack(spacing: 16) { // Horizontal stack with spacing between elements.
            statBox(title: calorieGoalText(), subtitle: "Calorie Goal") // Calorie goal stat.
            Divider() // Separator between stats.
            statBox(title: calculateBMI(), subtitle: "BMI") // BMI stat.
        }
    }

    // Returns the user's calorie goal as a string, or "Loading..." if not available.
    func calorieGoalText() -> String {
        if let calories = goalSettings.calories { // Checks if calorie goal is available.
            return "\(Int(calories))" // Formats as an integer string.
        } else {
            return "Loading..." // Fallback if data isn't loaded yet.
        }
    }

    // Calculates the user's BMI based on weight and height from goalSettings.
    func calculateBMI() -> String {
        let weightInKg = goalSettings.weight * 0.453592 // Converts weight from lbs to kg.
        let heightInMeters = goalSettings.height / 100 // Converts height from cm to meters.
        guard heightInMeters > 0 else { return "N/A" } // Avoids division by zero.
        let bmi = weightInKg / (heightInMeters * heightInMeters) // BMI formula: weight / (height^2).
        return String(format: "%.1f", bmi) // Formats BMI to one decimal place.
    }

    // Builds a stat box with a title and subtitle for daily stats.
    func statBox(title: String, subtitle: String) -> some View {
        VStack { // Vertical stack for stat display.
            Text(title) // Main stat value.
                .font(.title) // Large font for prominence.
                .fontWeight(.bold) // Bold text for emphasis.
            Text(subtitle) // Stat label.
                .foregroundColor(.gray) // Gray color for secondary text.
        }
    }

    // MARK: - Achievements Section
    // Displays the user's achievements in a list format.
    func achievementsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) { // Vertical stack aligned to the leading edge.
            Text("Achievements") // Section title.
                .font(.headline) // Slightly larger font for section titles.
            if achievements.isEmpty { // Handles empty state.
                Text("No achievements yet.") // Placeholder text.
                    .foregroundColor(.gray) // Gray color for secondary text.
                    .font(.subheadline) // Smaller font for placeholder.
            } else { // Displays achievements if available.
                ForEach(achievements) { achievement in // Loops through achievements.
                    HStack { // Horizontal stack for each achievement.
                        Image(systemName: "star.fill") // Star icon for achievements.
                            .foregroundColor(.yellow) // Yellow color for the star.
                        Text(achievement.title) // Achievement title.
                    }
                }
            }
        }
    }

    // MARK: - Posts Section
    // Displays the user's posts in a list format.
    func postsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) { // Vertical stack aligned to the leading edge.
            Text("Your Posts") // Section title.
                .font(.headline) // Slightly larger font for section titles.
            if posts.isEmpty { // Handles empty state.
                Text("You haven’t posted anything yet.") // Placeholder text.
                    .foregroundColor(.gray) // Gray color for secondary text.
                    .font(.subheadline) // Smaller font for placeholder.
            } else { // Displays posts if available.
                ForEach(posts) { post in // Loops through posts.
                    postView(post) // Displays each post.
                }
            }
        }
    }

    // Builds a view for a single post with content and timestamp.
    func postView(_ post: Post) -> some View {
        VStack(alignment: .leading) { // Vertical stack aligned to the leading edge.
            Text(post.content) // Post content.
                .font(.body) // Standard font size for readability.
            Text(post.timestamp, style: .date) // Post timestamp.
                .font(.caption) // Smaller font for secondary text.
                .foregroundColor(.gray) // Gray color for secondary text.
        }
        .padding() // Adds padding around the post.
        .background(Color(.systemGray6)) // Light gray background for contrast.
        .cornerRadius(8) // Rounded corners for a modern look.
    }

    // MARK: - Daily History Section
    // Displays the user's daily log history, grouped by date.
    func dailyHistorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) { // Vertical stack aligned to the leading edge.
            Text("Daily History") // Section title.
                .font(.headline) // Slightly larger font for section titles.

            if dailyHistory.isEmpty { // Handles empty state.
                Text("No daily logs available.") // Placeholder text.
                    .foregroundColor(.gray) // Gray color for secondary text.
                    .font(.subheadline) // Smaller font for placeholder.
            } else { // Displays daily history if available.
                ForEach(groupedDailyHistory(), id: \.date) { groupedLog in // Loops through grouped logs.
                    VStack(alignment: .leading) { // Vertical stack for each group.
                        Text(groupedLog.date, style: .date) // Date header for the group.
                            .font(.headline) // Slightly larger font for emphasis.
                        ForEach(groupedLog.logs) { log in // Loops through logs for the date.
                            ForEach(log.meals) { meal in // Loops through meals in the log.
                                mealView(meal) // Displays each meal.
                            }
                        }
                    }
                    .padding() // Adds padding around the group.
                    .background(Color(.systemGray6)) // Light gray background for contrast.
                    .cornerRadius(8) // Rounded corners for a modern look.
                }
            }
        }
    }

    // Builds a view for a single meal with its food items.
    func mealView(_ meal: Meal) -> some View {
        VStack(alignment: .leading) { // Vertical stack aligned to the leading edge.
            Text(meal.name) // Meal name.
                .font(.subheadline) // Smaller font for meal names.
                .fontWeight(.bold) // Bold text for emphasis.
            ForEach(meal.foodItems) { item in // Loops through food items in the meal.
                HStack { // Horizontal stack for each food item.
                    Text(item.name) // Food item name.
                    Spacer() // Pushes the calorie info to the right.
                    Text("\(Int(item.calories)) kcal") // Calorie count.
                        .foregroundColor(.gray) // Gray color for secondary text.
                }
                .font(.footnote) // Very small font for food items.
            }
        }
        .padding(.top, 4) // Adds top padding for spacing.
    }

    // Groups daily logs by the start of the day for better organization.
    func groupedDailyHistory() -> [GroupedDailyLog] {
        Dictionary(grouping: dailyHistory, by: { Calendar.current.startOfDay(for: $0.date) }) // Groups logs by date.
            .map { GroupedDailyLog(date: $0.key, logs: $0.value) } // Maps to GroupedDailyLog structs.
            .sorted(by: { $0.date > $1.date }) // Sorts in descending order (newest first).
    }

    // MARK: - Load User Data
    // Loads user data (posts, achievements, daily history) from Firebase via the dailyLogService.
    func loadUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { // Ensures a user is authenticated.
            errorMessage = ErrorMessage("User not authenticated.") // Sets error if no user.
            return
        }

        // Fetch posts using the dailyLogService.
        dailyLogService.fetchPosts(for: userID) { result in
            handleFetchResult(result: result, setState: { self.posts = $0 })
        }

        // Fetch achievements using the dailyLogService.
        dailyLogService.fetchAchievements(for: userID) { result in
            handleFetchResult(result: result, setState: { self.achievements = $0 })
        }

        // Fetch daily history using the dailyLogService.
        dailyLogService.fetchDailyHistory(for: userID) { result in
            handleFetchResult(result: result, setState: { self.dailyHistory = $0 })
        }
    }

    // Handles the result of a fetch operation, updating state or showing an error.
    func handleFetchResult<T>(result: Result<[T], Error>, setState: @escaping ([T]) -> Void) {
        DispatchQueue.main.async { // Ensures UI updates on the main thread.
            switch result {
            case .success(let data): // Updates the state with fetched data.
                setState(data)
            case .failure(let error): // Sets an error message on failure.
                self.errorMessage = ErrorMessage("Error loading data: \(error.localizedDescription)")
            }
        }
    }
}

// ErrorMessage Wrapper for Identifiable Compliance
// A struct to wrap error messages, making them identifiable for SwiftUI alerts.
struct ErrorMessage: Identifiable {
    let id = UUID() // Unique identifier for the error.
    let text: String // Error message text.

    init(_ text: String) {
        self.text = text // Initializes with the provided text.
    }
}

// GroupedDailyLog for grouping logs by date
// A struct to group daily logs by date, making them identifiable for SwiftUI lists.
struct GroupedDailyLog: Identifiable {
    let id = UUID() // Unique identifier for the group.
    let date: Date // Date of the group.
    let logs: [DailyLog] // Array of daily logs for that date.
}
