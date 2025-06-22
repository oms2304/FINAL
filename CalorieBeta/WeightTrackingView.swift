import SwiftUI

// This view displays a weight tracking interface, allowing users to view their weight history
// over different timeframes and enter new weight data, integrated with the GoalSettings model.
struct WeightTrackingView: View {
    @EnvironmentObject var goalSettings: GoalSettings
    @State private var showingWeightEntry = false
    @State private var selectedTimeframe: Timeframe = .year

    // State for chart tap deletion alert
    @State private var showingChartDeleteAlert = false
    @State private var chartEntryToDeleteID: String? = nil
    @State private var chartEntryToDeleteDetails: String = "" // For display in alert

    // Computed property to filter weight history for the chart.
    var filteredWeightDataForChart: [(id: String, date: Date, weight: Double)] {
        let now = Date()
        let history = goalSettings.weightHistory

        switch selectedTimeframe {
         case .day:
             let startOfToday = Calendar.current.startOfDay(for: now)
             return history.filter { $0.date >= startOfToday }.sorted { $0.date < $1.date }
         case .week:
             let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
             return history.filter { $0.date >= startOfWeek }.sorted { $0.date < $1.date }
         case .month:
             let startOfMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!
             return history.filter { $0.date >= startOfMonth }.sorted { $0.date < $1.date }
         case .sixMonths:
             let startOfSixMonths = Calendar.current.date(byAdding: .month, value: -6, to: now)!
             return history.filter { $0.date >= startOfSixMonths }.sorted { $0.date < $1.date }
         case .year:
             let startOfYear = Calendar.current.date(byAdding: .year, value: -1, to: now)!
             return history.filter { $0.date >= startOfYear }.sorted { $0.date < $1.date }
         }
    }

     // Date formatter for the alert message
     private let alertItemFormatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateStyle = .short // e.g., 4/17/25
         formatter.timeStyle = .short // e.g., 1:06 PM
         return formatter
     }()


    var body: some View {
        VStack(spacing: 0) {
            Text("Weight Tracking")
                .font(.largeTitle)
                .padding(.bottom, 5)

            Picker("Select Timeframe", selection: $selectedTimeframe) {
                Text("D").tag(Timeframe.day)
                Text("W").tag(Timeframe.week)
                Text("M").tag(Timeframe.month)
                Text("6M").tag(Timeframe.sixMonths)
                Text("Y").tag(Timeframe.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)

            // Chart View
            WeightChartView(
                weightHistory: filteredWeightDataForChart,
                currentWeight: goalSettings.weight,
                onEntrySelected: { entryId in
                     // Find the details for the alert message
                     if let entry = goalSettings.weightHistory.first(where: { $0.id == entryId }) {
                         self.chartEntryToDeleteID = entryId
                         // *** FIX: Use String(format:) for weight ***
                         let weightString = String(format: "%.1f", entry.weight)
                         let dateString = alertItemFormatter.string(from: entry.date)
                         self.chartEntryToDeleteDetails = "\(weightString) lbs on \(dateString)" // Combine formatted strings
                         self.showingChartDeleteAlert = true
                     }
                 }
            )
            .frame(height: 250)
            .padding(.bottom)

            // WeightChartViewController (Target Weight/Progress Bar)
            WeightChartViewController()
                .environmentObject(goalSettings)
                .frame(height: 100)
                .padding(.bottom)

            Spacer() // Pushes button to bottom

            Button(action: { showingWeightEntry = true }) {
                Text("Enter Current Weight")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 67/255, green: 173/255, blue: 111/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding([.horizontal, .bottom])
            .padding(.top, 5)

        }
        .sheet(isPresented: $showingWeightEntry) {
            CurrentWeightView()
                .environmentObject(goalSettings)
        }
         .onAppear {
             goalSettings.loadWeightHistory()
         }
         // Alert modifier for chart tap deletion
         .alert("Delete Weight Entry?", isPresented: $showingChartDeleteAlert) {
             Button("Delete", role: .destructive) {
                 if let idToDelete = chartEntryToDeleteID {
                     confirmDeleteChartEntry(entryID: idToDelete)
                 }
             }
             Button("Cancel", role: .cancel) {
                 chartEntryToDeleteID = nil // Clear selection on cancel
             }
         } message: {
             // Display the pre-formatted details string
             Text("Are you sure you want to delete the entry: \(chartEntryToDeleteDetails)?")
         }
    }

    // Function to perform deletion after alert confirmation
    private func confirmDeleteChartEntry(entryID: String) {
        print("Attempting deletion for entry ID: \(entryID)")
        goalSettings.deleteWeightEntry(entryID: entryID) { error in
            if let error = error {
                print("❌ Failed to delete weight entry from chart tap: \(error.localizedDescription)")
                // Optionally show another alert for the error
            } else {
                print("✅ Chart tap delete successful for entry \(entryID)")
                // View should update automatically via @EnvironmentObject
            }
        }
        chartEntryToDeleteID = nil // Clear selection after attempting delete
    }
}

// Timeframe Enum remains the same
enum Timeframe: String, CaseIterable, Identifiable {
    case day = "Day"; case week = "Week"; case month = "Month"; case sixMonths = "6 Months"; case year = "Year"
    var id: String { self.rawValue }; var displayString: String { self.rawValue }
}
