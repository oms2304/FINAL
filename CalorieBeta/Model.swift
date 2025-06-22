import Foundation
import FirebaseFirestore
import SwiftUI

// Represents a daily log of meals and food items, conforming to Codable for JSON/Firestore serialization
// and Identifiable for use in SwiftUI lists.
struct DailyLog: Codable, Identifiable, Equatable {
    var id: String? // Unique identifier, optional as it may be set by Firestore.
    var date: Date // The date associated with this log.
    var meals: [Meal] // Array of meals consumed on this date.
    var totalCaloriesOverride: Double? // Optional override for total calories, if manually adjusted.
    var waterTracker: WaterTracker? // Add the waterTracker property

    // Updated initializer to include waterTracker
    init(id: String? = nil, date: Date, meals: [Meal], totalCaloriesOverride: Double? = nil, waterTracker: WaterTracker? = nil) {
        self.id = id
        self.date = date
        self.meals = meals
        self.totalCaloriesOverride = totalCaloriesOverride
        self.waterTracker = waterTracker
    }

    // Calculates the total calories from all food items across all meals.
    func totalCalories() -> Double {
        meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.calories }
        // flatMap flattens the nested foodItems array, reduce sums the calories.
    }

    // Calculates the total macronutrients (protein, fats, carbs) from all food items.
    func totalMacros() -> (protein: Double, fats: Double, carbs: Double) {
        let protein = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.protein }
        let fats = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.fats }
        let carbs = meals.flatMap { $0.foodItems }.reduce(0) { $0 + $1.carbs }
        return (protein, fats, carbs) // Returns a tuple of totals.
    }

    // Equatable conformance: Compare all properties
    static func == (lhs: DailyLog, rhs: DailyLog) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.meals == rhs.meals &&
               lhs.totalCaloriesOverride == rhs.totalCaloriesOverride &&
               lhs.waterTracker == rhs.waterTracker
    }
}

// Represents a meal within a daily log, conforming to Codable for serialization
// and Identifiable for SwiftUI lists.
struct Meal: Codable, Identifiable, Equatable {
    var id: String // Unique identifier for the meal.
    var name: String // Name of the meal (e.g., "Breakfast").
    var foodItems: [FoodItem] // Array of food items in this meal.

    // Equatable conformance: Compare all properties
    static func == (lhs: Meal, rhs: Meal) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.foodItems == rhs.foodItems
    }
}

// Represents a community post with social features, conforming to Codable for Firestore
// and Identifiable for SwiftUI lists. Uses @DocumentID for Firestore document ID.
struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString // Firestore document ID or a default UUID.
    let author: String // The user who posted this.
    let content: String // The text content of the post.
    var likes: Int // Number of likes on the post.
    var isLikedByCurrentUser: Bool // Indicates if the current user has liked it.
    var reactions: [String: Int] // Dictionary of reaction types and their counts (e.g., "👍": 5).
    var comments: [Comment] // Array of comments on the post.
    var timestamp: Date = Date() // Date of the post, defaults to current time.
    var groupID: String // ID of the community group this post belongs to.

    // Nested struct for comments, conforming to Codable and Identifiable.
    struct Comment: Identifiable, Codable {
        let id: String = UUID().uuidString // Unique identifier for the comment.
        let author: String // The user who commented.
        let content: String // The text of the comment.
        var replies: [Reply] = [] // Array of replies to this comment.

        // Nested struct for replies, conforming to Codable and Identifiable.
        struct Reply: Identifiable, Codable {
            let id: String = UUID().uuidString // Unique identifier for the reply.
            let author: String // The user who replied.
            let content: String // The text of the reply.
        }
    }
}

// Represents a community group, conforming to Codable and Identifiable for SwiftUI lists.
struct CommunityGroup: Identifiable, Codable {
    var id: String // Unique identifier for the group.
    var name: String // Name of the group.
    var description: String // Description of the group.
    var creatorID: String // ID of the user who created the group.
    var isPreset: Bool // Indicates if the group is a preset (e.g., not user-created).
}

// Represents a user's membership in a community group, conforming to Codable for serialization.
struct GroupMembership: Codable {
    var groupID: String // ID of the group the user is a member of.
    var userID: String // ID of the user who is a member.
}

// Represents a calorie record, conforming to Codable and Identifiable for SwiftUI lists.
struct CalorieRecord: Identifiable, Codable {
    var id: String = UUID().uuidString // Unique identifier, defaults to a new UUID.
    var date: Date // Date of the calorie record.
    var calories: Double // Calorie value for this record.
    var description: String // Optional description of the record.
}

// Represents a simple post, conforming to Identifiable for SwiftUI lists.
// Note: This struct does not conform to Codable, suggesting it may be used locally.
struct Post: Identifiable {
    let id: String // Unique identifier for the post.
    let content: String // Text content of the post.
    let timestamp: Date // Date of the post.
}

// Represents an achievement, conforming to Identifiable for SwiftUI lists.
// Note: This struct does not conform to Codable, suggesting it may be used locally.
struct Achievement: Identifiable {
    let id: String // Unique identifier for the achievement.
    let title: String // Title or name of the achievement.
}

// Custom Shape for Rounded Corners
/// Defines a custom shape to create rounded corners for specific edges of a view.
/// Used to style the background of form sections with rounded top corners.
struct CustomCorners: Shape {
    var corners: UIRectCorner // Specifies which corners to round.
    var radius: CGFloat // Radius of the rounded corners.

    /// Creates a path with rounded corners for the specified rectangle.
    /// - Parameter rect: The rectangle to apply the rounded corners to.
    /// - Returns: A Path object representing the rounded shape.
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, // Defines the rectangle to round.
            byRoundingCorners: corners, // Applies rounding to specified corners.
            cornerRadii: CGSize(width: radius, height: radius) // Sets the radius size.
        )
        return Path(path.cgPath) // Converts to a SwiftUI Path.
    }
}

// Reusable Components
/// A custom text field with rounded corners and a border, adapting to light and dark modes.
/// Used for consistent styling of text input fields across the app.
struct RoundedTextField: View {
    /// Placeholder text to display in the text field.
    var placeholder: String
    
    /// Binding to the text value entered by the user.
    @Binding var text: String
    
    /// Flag to determine if the keyboard should be optimized for email input.
    var isEmail: Bool = false
    
    /// Environment property to detect the current color scheme (light or dark).
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TextField(placeholder, text: $text) // Standard text field.
            .keyboardType(isEmail ? .emailAddress : .default) // Sets keyboard type based on isEmail.
            .padding() // Adds internal padding for better spacing.
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.white)) // Dynamic background: gray in dark mode, white in light mode.
            .cornerRadius(30) // Rounds the corners for a modern look.
            .overlay( // Adds a border around the text field.
                RoundedRectangle(cornerRadius: 30)
                    .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.black, lineWidth: 1) // Dynamic border: lighter in dark mode, black in light mode.
            )
            .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color for readability.
    }
}

/// A custom secure text field (e.g., for passwords) with rounded corners and a border, adapting to light and dark modes.
/// Used for consistent styling of secure input fields across the app.
struct RoundedSecureField: View {
    /// Placeholder text to display in the secure field.
    var placeholder: String
    
    /// Binding to the text value entered by the user.
    @Binding var text: String
    
    /// Environment property to detect the current color scheme (light or dark).
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SecureField(placeholder, text: $text) // Secure text field for passwords.
            .padding() // Adds internal padding for better spacing.
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.white)) // Dynamic background: gray in dark mode, white in light mode.
            .cornerRadius(30) // Rounds the corners for a modern look.
            .overlay( // Adds a border around the secure field.
                RoundedRectangle(cornerRadius: 30)
                    .stroke(colorScheme == .dark ? Color(.systemGray4) : Color.black, lineWidth: 1) // Dynamic border: lighter in dark mode, black in light mode.
            )
            .foregroundColor(colorScheme == .dark ? .white : .black) // Dynamic text color for readability.
    }
}

struct WaterTracker: Codable, Equatable {
    var totalOunces: Double
    var goalOunces: Double
    var date: Date

    init(totalOunces: Double, goalOunces: Double, date: Date) {
        self.totalOunces = totalOunces
        self.goalOunces = goalOunces
        self.date = date
    }
}
