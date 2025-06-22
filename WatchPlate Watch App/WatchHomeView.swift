import SwiftUI

struct WatchHomeView: View {
    @ObservedObject var sessionManager = WatchSessionManager.shared

    var body: some View {
        VStack(spacing: 8) {
            if let date = sessionManager.receivedData["date"] as? String,
               let water = sessionManager.receivedData["water"] as? Int,
               let calories = sessionManager.receivedData["calories"] as? Int {
                
                Text("📅 \(date)")
                    .font(.headline)
                Text("💧 Water: \(water) ml")
                    .font(.body)
                Text("🔥 Calories: \(calories)")
                    .font(.body)
            } else {
                Text("Waiting for data…")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            // This ensures the session is activated when the view appears
            let _ = WatchSessionManager.shared
        }
    }
}
