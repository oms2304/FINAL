import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// This is the main view for searching and adding food items to the user's daily log.
// It integrates with Firebase for user data and an external API (FatSecret) for food details.
struct FoodSearchView: View {
    // A binding to the daily log data, allowing this view to update the log in the parent view.
    @Binding var dailyLog: DailyLog?
    // A closure to notify the parent view when the daily log is updated with a new food item.
    var onLogUpdated: (DailyLog) -> Void
    // An optional initial search query passed to pre-fill the search field (e.g., from AI camera).
    var initialSearchQuery: String?

    // Environment variable to dismiss this view when the user is done (e.g., after adding food).
    @Environment(\.dismiss) var dismiss
    // Environment object providing access to the daily log service for Firebase operations.
    @EnvironmentObject var dailyLogService: DailyLogService

    // State variables to manage the UI and data flow:
    // The current text in the search bar.
    @State private var searchQuery = ""
    // The list of food items returned from the search API.
    @State private var searchResults: [FoodItem] = []
    // Tracks whether a search or data fetch is in progress to show a loading indicator.
    @State private var isLoading = false
    // A timer to debounce search queries (prevents rapid API calls while typing).
    @State private var debounceTimer: Timer?
    // Stores the IDs of recently added foods for quick access.
    @State private var recentFoodIds: [String] = []
    // Holds any error message to display in an alert.
    @State private var error: ErrorAlert? = nil
    // A dictionary to cache recently fetched food items by their IDs.
    @State private var recentFoodItems: [String: FoodItem] = [:]

    // An instance of the service to fetch food data from the FatSecret API.
    private let foodAPIService = FatSecretFoodAPIService()

    // The main body of the view, wrapped in a NavigationView for title and navigation.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // A custom view for the search bar, defined below.
                    VStack(alignment: .leading, spacing: 8) {
                        searchBar
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)

                    // A custom view for the content (results and recent foods), defined below.
                    VStack(alignment: .leading, spacing: 8) {
                        contentView
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)
                }
                .padding(.vertical)
            }
            .navigationTitle("Search Food") // Sets the title displayed at the top of the view.
            .toolbar {
                // Adds "MyFitPlate" branding in the top-left corner, replacing .withMyFitPlateBranding().
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("MyFitPlate")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.5))
                        .padding(.leading, 5)
                }
            }
            .onAppear {
                // Pre-fill the search query if an initial query is provided.
                searchQuery = initialSearchQuery ?? ""
                // If there's an initial query and it's not empty, perform the search after a short delay.
                if let query = initialSearchQuery, !query.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                        performSearch()
                    }
                } else {
                    // Reset results and loading state if no initial query.
                    searchResults = []
                    isLoading = false
                }
                // Load the user's recently added food IDs from Firebase.
                loadRecentFoods()
            }
            .onDisappear {
                // Invalidate the debounce timer to clean up when the view is dismissed.
                debounceTimer?.invalidate()
            }
            .alert(item: $error) { error in // Displays an alert if an error occurs.
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // A custom view representing the search bar with a text field and search button.
    private var searchBar: some View {
        HStack {
            // Text field where users type their search query.
            TextField("Search food items...", text: $searchQuery)
                .padding(10) // Adds internal padding for better appearance.
                .background(Color(.systemGray6)) // Light gray background for the field.
                .cornerRadius(8) // Rounds the edges of the text field.
                .padding(.horizontal) // Adds horizontal padding from screen edges.
                .onChange(of: searchQuery) { newValue in
                    // Calls a function to handle changes in the search query (e.g., debouncing).
                    handleSearchQueryChange(newValue)
                }

            // Button to manually trigger the search.
            Button(action: performSearch) {
                Image(systemName: "magnifyingglass") // Magnifying glass icon.
                    .foregroundColor(.white) // White icon color.
                    .padding(10) // Padding around the icon.
                    .background(Color.green) // Green background for the button.
                    .cornerRadius(8) // Rounded edges.
            }
            .padding(.trailing, 8) // Extra padding on the right side.
        }
        .padding(.vertical) // Vertical padding to space it from other content.
    }

    // A custom view for the main content, including search results and recent foods.
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Show a progress view if data is loading.
                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                }
                // Show search results if available and not loading.
                else if !searchResults.isEmpty {
                    searchResultsSection
                }
                // Show a prompt if the search query is empty.
                else if searchQuery.isEmpty {
                    Text("Enter a search query to find food items.")
                        .foregroundColor(.gray)
                        .padding()
                }
                // Show a message if no results are found.
                else {
                    Text("No results found. Try a different search.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Display recently added foods section.
                recentFoodsSection
            }
        }
    }

    // A custom view for displaying the search results.
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results") // Section header.
                .font(.headline) // Bold, larger font for the header.
                .padding(.horizontal) // Horizontal padding.
                .padding(.top, 8) // Top padding to separate from other content.

            // Loop through each food item in the search results.
            ForEach(searchResults, id: \.id) { foodItem in
                NavigationLink(destination: FoodDetailView(
                    foodItem: foodItem,
                    dailyLog: $dailyLog,
                    onLogUpdated: { updatedLog in
                        // Callback to update the daily log and dismiss the view.
                        onLogUpdated(updatedLog)
                        dismiss()
                    }
                )) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(foodItem.name) // Food item name.
                                .font(.headline) // Bold font.
                            Text("\(foodItem.calories, specifier: "%.0f") kcal (per serving)") // Calories display.
                                .font(.subheadline) // Smaller font.
                                .foregroundColor(.gray) // Gray color for secondary text.
                        }
                        Spacer() // Pushes content to the left.
                    }
                    .padding() // Internal padding.
                    .background(Color(.systemGray6)) // Light gray background.
                    .cornerRadius(10) // Rounded corners.
                    .shadow(radius: 3) // Subtle shadow for depth.
                    .padding(.horizontal) // Horizontal padding from edges.
                }
            }
        }
    }

    // A custom view for displaying recently added foods.
    private var recentFoodsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Added Foods") // Section header.
                .font(.headline) // Bold, larger font.
                .padding(.horizontal) // Horizontal padding.
                .padding(.top, 8) // Top padding.

            // Show a message if no recent foods exist.
            if recentFoodIds.isEmpty {
                Text("No recent foods added yet.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            // Show recent foods if available.
            else {
                ForEach(Array(recentFoodIds.unique()), id: \.self) { foodId in
                    NavigationLink(destination: RecentFoodDetailView(foodId: foodId, dailyLog: $dailyLog, onLogUpdated: { updatedLog in
                        // Callback to update the daily log and dismiss.
                        onLogUpdated(updatedLog)
                        dismiss()
                    })) {
                        HStack {
                            // Display food details if loaded, or a loading state if not.
                            if let foodItem = recentFoodItems[foodId] {
                                VStack(alignment: .leading) {
                                    Text(foodItem.name) // Food name.
                                        .font(.subheadline) // Smaller font.
                                        .fontWeight(.medium) // Medium weight for emphasis.
                                    Text("\(foodItem.calories, specifier: "%.0f") kcal (per serving)") // Calories.
                                        .font(.caption) // Even smaller font.
                                        .foregroundColor(.gray) // Gray color.
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text("Loading...") // Placeholder text.
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("... kcal (per serving)") // Placeholder calories.
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer() // Pushes content to the left.
                        }
                        .padding(10) // Internal padding.
                        .background(Color(.systemGray5)) // Slightly darker gray background.
                        .cornerRadius(8) // Rounded edges.
                        .padding(.horizontal) // Horizontal padding.
                    }
                }
            }
        }
    }

    // Handles changes to the search query with debouncing to avoid excessive API calls.
    private func handleSearchQueryChange(_ newValue: String) {
        debounceTimer?.invalidate() // Stops any existing timer.

        guard !newValue.isEmpty else {
            // Reset results and loading state if the query is empty.
            searchResults = []
            isLoading = false
            return
        }

        // Sets a new timer to delay the search by 0.5 seconds.
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [self] _ in
            performSearch()
        }
    }

    // Performs the actual search based on the current search query.
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            // Reset if the query is empty.
            searchResults = []
            isLoading = false
            print("⚠️ Search query is empty, resetting results and loading state")
            return
        }
        isLoading = true // Start loading state.
        print("🔎 Starting search with query: \(searchQuery)")

        // Check if the query is numeric (e.g., a barcode).
        if searchQuery.allSatisfy(\.isNumber) {
            print("🔎 Searching by Barcode: \(searchQuery)")
            foodAPIService.fetchFoodByBarcode(barcode: searchQuery) { [self] result in
                DispatchQueue.main.async {
                    isLoading = false // Stop loading once data is fetched.
                    handleSearchResults(result)
                }
            }
        } else {
            print("🔎 Searching by Query: \(searchQuery)")
            foodAPIService.fetchFoodByQuery(query: searchQuery) { [self] result in
                DispatchQueue.main.async {
                    isLoading = false // Stop loading.
                    handleSearchResults(result)
                }
            }
        }
    }

    // Processes the search results from the API, handling success or failure.
    private func handleSearchResults(_ result: Result<[FoodItem], Error>) {
        print("🔍 Handling search results for query '\(searchQuery)'")
        switch result {
        case .success(let foodItems):
            print("✅ HandleSearchResults - Found \(foodItems.count) results for query '\(searchQuery)': \(foodItems.map { $0.name })")
            searchResults = foodItems // Update the results list.
        case .failure(let error):
            print("❌ API Fetch Error for query '\(searchQuery)': \(error.localizedDescription)")
            searchResults = [] // Clear results on error.
            self.error = ErrorAlert(message: error.localizedDescription) // Show error alert.
        }
        print("🔍 Current searchResults count after handling: \(searchResults.count)")
    }

    // Loads the user's recently added food IDs from Firebase.
    private func loadRecentFoods() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID found, cannot load recent foods")
            return
        }

        dailyLogService.fetchRecentFoods(for: userID) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foodIds):
                    recentFoodIds = Array(foodIds.unique()) // Remove duplicates.
                    print("✅ Loaded recent food IDs: \(recentFoodIds)")
                    // Asynchronously fetch details for each recent food.
                    Task {
                        await fetchRecentFoodItems(foodIds: recentFoodIds)
                    }
                case .failure(let error):
                    recentFoodIds = [] // Clear on error.
                    print("❌ Error fetching recent foods for user '\(userID)': \(error.localizedDescription)")
                    self.error = ErrorAlert(message: error.localizedDescription) // Show error alert.
                }
            }
        }
    }

    // Asynchronously fetches detailed food items for the recent food IDs.
    private func fetchRecentFoodItems(foodIds: [String]) async {
        for foodId in foodIds {
            do {
                let foodItem = try await withCheckedThrowingContinuation { continuation in
                    foodAPIService.fetchFoodDetails(foodId: foodId) { result in
                        switch result {
                        case .success(let item):
                            continuation.resume(returning: item) // Successfully return the food item.
                        case .failure(let apiError):
                            let error = ErrorAlert(message: "Failed to load food details for ID \(foodId): \(apiError.localizedDescription)")
                            DispatchQueue.main.async {
                                self.error = error // Show error if fetch fails.
                            }
                            continuation.resume(throwing: apiError) // Propagate the error.
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.recentFoodItems[foodId] = foodItem // Store the fetched item.
                }
            } catch {
                DispatchQueue.main.async {
                    // Fallback to a default item if fetch fails.
                    self.recentFoodItems[foodId] = FoodItem(
                        id: foodId,
                        name: "Unknown",
                        calories: 0.0,
                        protein: 0.0,
                        carbs: 0.0,
                        fats: 0.0,
                        servingSize: "N/A",
                        servingWeight: 100.0,
                        timestamp: nil
                    )
                    let error = ErrorAlert(message: "Failed to load food details for ID \(foodId): \(error.localizedDescription)")
                    self.error = error // Show error alert.
                }
            }
        }
    }

    // A placeholder function to navigate to food details (not fully implemented here).
    private func fetchAndNavigateToFoodDetail(foodId: String) -> some View {
        RecentFoodDetailView(foodId: foodId, dailyLog: $dailyLog, onLogUpdated: { updatedLog in
            onLogUpdated(updatedLog)
            dismiss()
        })
    }
}

// A sub-view to display details for a recently selected food item.
struct RecentFoodDetailView: View {
    let foodId: String // The ID of the food item to fetch details for.
    @Binding var dailyLog: DailyLog? // Binding to the daily log for updates.
    var onLogUpdated: (DailyLog) -> Void // Callback for log updates.

    @State private var foodItem: FoodItem? // Stores the fetched food item.
    @State private var isLoading = true // Tracks the loading state.
    @State private var showErrorAlert = false // Controls error alert visibility.
    @State private var errorMessage: String = "" // Holds the error message text.
    @Environment(\.dismiss) var dismiss // Environment variable to dismiss the view.

    private let foodAPIService = FatSecretFoodAPIService() // Service to fetch food data.

    var body: some View {
        Group {
            // Display a progress view while loading.
            if isLoading {
                ProgressView("Loading...")
            }
            // Show the food details view if data is loaded successfully.
            else if let foodItem = foodItem {
                FoodDetailView(
                    foodItem: foodItem,
                    dailyLog: $dailyLog,
                    onLogUpdated: { updatedLog in
                        onLogUpdated(updatedLog)
                        dismiss()
                    }
                )
            }
            // Show an error message if loading fails.
            else {
                Text("Failed to load food details")
                    .foregroundColor(.red)
                    .onTapGesture {
                        dismiss() // Dismiss on tap if there's an error.
                    }
            }
        }
        .onAppear {
            // Fetch food details when the view appears.
            fetchFoodDetails()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    dismiss() // Dismiss the alert and view.
                }
            )
        }
    }

    // Fetches the food details from the API based on the food ID.
    private func fetchFoodDetails() {
        foodAPIService.fetchFoodDetails(foodId: foodId) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self.foodItem = item // Store the fetched item.
                    self.isLoading = false // Stop loading.
                    print("✅ Received FoodItem in Detail View: \(item.name)")
                    print("🔹 Base Calories (per serving): \(item.calories)")
                    print("🔹 Protein: \(item.protein)")
                    print("🔹 Carbs: \(item.carbs)")
                    print("🔹 Fats: \(item.fats)")
                    print("🔹 Serving Weight: \(item.servingWeight)g")
                case .failure(let error):
                    self.foodItem = FoodItem(
                        id: foodId,
                        name: "Unknown",
                        calories: 0.0,
                        protein: 0.0,
                        carbs: 0.0,
                        fats: 0.0,
                        servingSize: "N/A",
                        servingWeight: 100.0,
                        timestamp: nil
                    ) // Fallback to a default item.
                    self.isLoading = false // Stop loading.
                    self.errorMessage = "Failed to load food details: \(error.localizedDescription)" // Set error message.
                    self.showErrorAlert = true // Show the alert.
                }
            }
        }
    }
}

// A simple struct to represent an error alert with a unique ID and message.
struct ErrorAlert: Identifiable {
    let id = UUID() // Unique identifier for the alert.
    let message: String // The error message to display.
}

// An extension to remove duplicates from an array of hashable elements.
extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = [] // A set to track seen elements.
        return filter { seen.insert($0).inserted } // Keep only the first occurrence of each element.
    }
}
