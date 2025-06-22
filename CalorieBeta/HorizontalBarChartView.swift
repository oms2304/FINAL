import SwiftUI
import Charts

// This view displays a horizontal bar chart to visualize the user's nutritional progress
// (calories and macros) compared to their goals, using the Charts framework.
struct HorizontalBarChartView: View {
    // The daily log containing the user's food intake data.
    var dailyLog: DailyLog
    // Observed object to access and react to changes in the user's goal settings.
    @ObservedObject var goal: GoalSettings

    // The main body of the view, rendering a chart or a loading state.
    var body: some View {
        // Checks if the calorie goal is available before rendering the chart.
        if let caloriesGoal = goal.calories {
            // Calculates total consumed values and percentages relative to goals.
            let totalCalories = max(0, dailyLog.totalCalories()) // Ensures non-negative calorie total.
            let totalMacros = dailyLog.totalMacros() // Retrieves total macros from the log.
            let protein = max(0, totalMacros.protein) // Ensures non-negative protein.
            let fats = max(0, totalMacros.fats) // Ensures non-negative fats.
            let carbs = max(0, totalMacros.carbs) // Ensures non-negative carbs.

            // Use max(goal, 1) to prevent division by zero if a goal is accidentally 0
            let proteinGoal = max(goal.protein, 1)
            let fatsGoal = max(goal.fats, 1)
            let carbsGoal = max(goal.carbs, 1)
            let effectiveCaloriesGoal = max(caloriesGoal, 1) // Use for calculation

            // Calculates the progress percentage for each nutrient as a percentage (0 to 100).
            let caloriesPercentage = min((totalCalories / effectiveCaloriesGoal) * 100, 100)
            let proteinPercentage = min((protein / proteinGoal) * 100, 100)
            let fatsPercentage = min((fats / fatsGoal) * 100, 100)
            let carbsPercentage = min((carbs / carbsGoal) * 100, 100)

            // Creates the chart using the Charts framework.
            Chart {
                // Bar for calories progress.
                BarMark(
                    x: .value("Calories", caloriesPercentage),
                    y: .value("Type", "Calories")
                )
                .foregroundStyle(.red)
                .annotation(position: .trailing, alignment: .leading) {
                    // *** Changed "kcal" to "cal" ***
                    Text("\(Int(totalCalories)) / \(Int(caloriesGoal)) cal")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                // Bar for protein progress.
                BarMark(
                    x: .value("Protein", proteinPercentage),
                    y: .value("Type", "Protein")
                )
                .foregroundStyle(.blue)
                .annotation(position: .trailing, alignment: .leading) {
                    // *** Changed format to Int ***
                    Text("\(Int(protein)) / \(Int(goal.protein))g")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                // Bar for fats progress.
                BarMark(
                    x: .value("Fats", fatsPercentage),
                    y: .value("Type", "Fats")
                )
                .foregroundStyle(.green)
                .annotation(position: .trailing, alignment: .leading) {
                     // *** Changed format to Int ***
                    Text("\(Int(fats)) / \(Int(goal.fats))g")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                // Bar for carbs progress.
                BarMark(
                    x: .value("Carbs", carbsPercentage),
                    y: .value("Type", "Carbs")
                )
                .foregroundStyle(.orange)
                .annotation(position: .trailing, alignment: .leading) {
                     // *** Changed format to Int ***
                    Text("\(Int(carbs)) / \(Int(goal.carbs))g")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
             // *** Updated AxisMarks to remove GridLines ***
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    // Explicitly omit AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    // Explicitly omit AxisGridLine()
                    AxisTick() // Keep ticks if desired
                    AxisValueLabel(horizontalSpacing: 5) // Add spacing
                }
            }
            .chartXScale(domain: 0...100)
            .fixedSize(horizontal: false, vertical: true) // Keep dynamic height
            .padding()

        } else {
            // Loading state remains the same
            Text("Loading data...")
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
        }
    }
}
