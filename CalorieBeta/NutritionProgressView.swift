import SwiftUI
import Charts
import FirebaseAuth

struct NutritionProgressView: View {
    var dailyLog: DailyLog
    
    @ObservedObject var goal: GoalSettings
    @EnvironmentObject var goalSettings: GoalSettings
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dailyLogService: DailyLogService

    @GestureState private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 50

    var body: some View {
        let totalCalories = max(0, dailyLog.totalCalories())
        let totalMacros = dailyLog.totalMacros()
        let protein = max(0, totalMacros.protein)
        let fats = max(0, totalMacros.fats)
        let carbs = max(0, totalMacros.carbs)

        // Use max(goal, 1) to prevent division by zero if a goal is accidentally 0
        let caloriesGoal = max(goal.calories ?? 1, 1)
        let proteinGoal = max(goal.protein, 1)
        let fatsGoal = max(goal.fats, 1)
        let carbsGoal = max(goal.carbs, 1)

        let caloriesPercentage = min(totalCalories / caloriesGoal, 1.0)
        let proteinPercentage = min(protein / proteinGoal, 1.0)
        let fatsPercentage = min(fats / fatsGoal, 1.0)
        let carbsPercentage = min(carbs / carbsGoal, 1.0)

        let waterIntake = dailyLog.waterTracker?.totalOunces ?? 0.0
        let waterGoal = max(dailyLog.waterTracker?.goalOunces ?? 64.0, 1.0) // Avoid division by zero
        let waterPercentage = min(waterIntake / waterGoal, 1.0)

        // Main VStack for the whole component
        VStack(spacing: 16) {
            // ZStack containing either bubbles or bar chart
            ZStack {
                if goal.showingBubbles {
                    bubblesView(
                        calories: totalCalories, caloriesGoal: caloriesGoal, caloriesPercentage: caloriesPercentage,
                        protein: protein, proteinGoal: proteinGoal, proteinPercentage: proteinPercentage,
                        fats: fats, fatsGoal: fatsGoal, fatsPercentage: fatsPercentage,
                        carbs: carbs, carbsGoal: carbsGoal, carbsPercentage: carbsPercentage
                    )
                } else {
                    HorizontalBarChartView(dailyLog: dailyLog, goal: goal)
                }
            }
            // *** Removed .frame(maxHeight: 180) to allow dynamic height ***
            .padding(.horizontal, 8) // Keep horizontal padding if desired
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > swipeThreshold {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                goal.showingBubbles.toggle()
                            }
                        }
                    }
            )
            Divider()
            
            WaterTrackingCardView(date: dailyLog.date)
                .environmentObject(goalSettings)
                .environmentObject(dailyLogService)

            // VStack for Water Intake UI
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("Water Intake")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundColor(colorScheme == .dark ? .white : .black)
//                    Spacer()
//                    // Ensure waterGoal is displayed correctly even if default is used
//                    Text("\(String(format: "%.0f", waterIntake))/\(String(format: "%.0f", dailyLog.waterTracker?.goalOunces ?? 64.0)) oz")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//
//                // Calculate the width for the water progress bar dynamically
//                GeometryReader { geometry in
//                    ZStack(alignment: .leading) {
//                        RoundedRectangle(cornerRadius: 5)
//                            .frame(height: 10)
//                            .foregroundColor(.gray.opacity(0.2))
//
//                        RoundedRectangle(cornerRadius: 5)
//                             // Use geometry.size.width for dynamic width calculation
//                            .frame(width: CGFloat(waterPercentage) * geometry.size.width, height: 10)
//                            .foregroundColor(Color.blue)
//                            .animation(.easeInOut, value: waterPercentage) // Animate progress change
//                    }
//                }
//                .frame(height: 10) // Set height for GeometryReader container
//
//                // Button to add water
//                Button(action: {
//                    if let userID = Auth.auth().currentUser?.uid {
//                        // Ensure we use the date from the current log being displayed
//                        dailyLogService.addWaterToCurrentLog(for: userID, date: dailyLog.date)
//                    }
//                }) {
//                    HStack {
//                        Image(systemName: "drop.fill")
//                            .foregroundColor(.white)
//                        Text("Add 8 oz Glass")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                    }
//                    .padding(.vertical, 6)
//                    .padding(.horizontal, 12)
//                    .background(Color.blue)
//                    .cornerRadius(8)
//                }
//                // Center the button if desired
//                // .frame(maxWidth: .infinity, alignment: .center)
//            }
            .padding(.horizontal) // Apply horizontal padding to the water section
        }
        // Apply padding to the entire NutritionProgressView if needed
        // .padding()
    }

    // Bubbles View Builder (remains the same)
    @ViewBuilder
    private func bubblesView(
        calories: Double, caloriesGoal: Double, caloriesPercentage: Double,
        protein: Double, proteinGoal: Double, proteinPercentage: Double,
        fats: Double, fatsGoal: Double, fatsPercentage: Double,
        carbs: Double, carbsGoal: Double, carbsPercentage: Double
    ) -> some View {
         HStack(spacing: 15) {
             ProgressBubble(
                 value: calories,
                 goal: caloriesGoal,
                 percentage: caloriesPercentage,
                 label: "Calories",
                 unit: "cal",
                 color: .red
             )

             ProgressBubble(
                 value: protein,
                 goal: proteinGoal,
                 percentage: proteinPercentage,
                 label: "Protein",
                 unit: "g",
                 color: .blue
             )

             ProgressBubble(
                 value: fats,
                 goal: fatsGoal,
                 percentage: fatsPercentage,
                 label: "Fats",
                 unit: "g",
                 color: .green
             )

             ProgressBubble(
                 value: carbs,
                 goal: carbsGoal,
                 percentage: carbsPercentage,
                 label: "Carbs",
                 unit: "g",
                 color: .orange
             )
         }
         .padding(.horizontal, 8) // Keep padding within the bubbles view if needed
         // Add a flexible frame if you want the bubbles to take up a certain space
         // .frame(height: 150) // Example fixed height for bubbles view
    }
}

// ProgressBubble struct (remains the same)
struct ProgressBubble: View {
    let value: Double
    let goal: Double
    let percentage: Double
    let label: String
    let unit: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.2)
                    .foregroundColor(color)

                Circle()
                    .trim(from: 0, to: CGFloat(percentage))
                    .stroke(lineWidth: 6)
                    .foregroundColor(color)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: percentage) // Animate trim change

                VStack {
                    Text("\(String(format: "%.0f", value))")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text("/ \(String(format: "%.0f", goal)) \(unit)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 70, height: 70) // Keep fixed size for bubbles

            Text(label)
                .font(.caption2)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
    }
}

//WaterTrackingCardView(date: dailyLog.date)
