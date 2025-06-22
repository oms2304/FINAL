    //
    //  WaterTrackingCardView.swift
    //  MyFitPlate
    //
    //  Created by Omar Sabeha on 4/21/25.
    //

    import SwiftUI
    import FirebaseAuth // could be used to access userID


    struct WaterTrackingCardView: View {
        @EnvironmentObject var dailyLogService : DailyLogService
        @EnvironmentObject var goalSettings: GoalSettings
        @Environment(\.dismiss) var dismiss
        
        @State private var showingGoalSheet = false
        @State private var newGoalInput: String = ""
        
        
        var date: Date
        
        
        private var waterIntake: Double {
            dailyLogService.currentDailyLog?.waterTracker?.totalOunces ?? 0.0 // gets the total ounces for the day
        }
        private var waterGoal: Double {
            max(1, dailyLogService.currentDailyLog?.waterTracker?.goalOunces ?? 64.0) // sets the minimum value of dailyLogService.currentDai... as 1. It would crash the progress calculation if it becomes 0 (can't do x/0)
        }
        
        
        
        var body: some View {
            let progress = max(0, min(1, waterIntake / goalSettings.waterGoal))
            let amounts : [Double] = [8, 12, 16]
            
            //        print("water progress: \(progress)")
            
            
            
            VStack(alignment: .center, spacing: 10) {
                Text("Water Intake")
                    .font(.headline)
                ZStack{
                    Text("\(Int(waterIntake)) / \(Int(goalSettings.waterGoal)) oz")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom ,5)
                    
                    HStack{
                        Spacer()
                            .frame(maxWidth: 170)
                        Button {
                            showingGoalSheet = true
                        } label : {
                            Text("Edit")
                            
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                
                //            Rectangle()
                //                .fill(Color.gray.opacity(0.1))
                //                .frame(width: 80, height: 150)
                //                .overlay(Text("Graphic\nPlaceHolder").font(.caption).multilineTextAlignment(.center).foregroundColor(.gray))
                //                .frame(maxWidth: .infinity, alignment: .center)
                //                .padding(.vertical)
                GeometryReader { geometry in
                    ZStack(alignment: .bottom){
                        //water level
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue.opacity(0.7)]),
                                startPoint: .bottom, endPoint: .top ))
                        
                            .frame(height: geometry.size.height * CGFloat(progress))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                        
                        
                        WaterBottleShape()
                            .stroke(Color.secondary, lineWidth: 2)
                    }
                    
                    
                    
                    .mask(WaterBottleShape()) //mask clips everything inside the ZStack to the shape of the waterBottleShape
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                .frame(width: 80, height: 150)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
                
                
                HStack(spacing: 15) {
                    ForEach(amounts, id: \.self) { amount in
                        Button {
                            guard let userID = Auth.auth().currentUser?.uid else {
                                print("WaterTrackingCardView Error: User not logged in.")
                                return
                            } 
                            print("BUTTON: Tapped \(amount)oz for date \(date)")
                            dailyLogService.addWaterToCurrentLog(for: userID, date: date, amount: amount, goalOunces: goalSettings.waterGoal)
                            
                        } label: {
                            Text("\(Int(amount)) oz")
                                .font(.system(size: 14, weight: .medium))
                                .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)
            }
            .sheet(isPresented: $showingGoalSheet){
                NavigationView {
                        Form {
                            Section(header: Text("Edit Goal")) {
                                TextField("Daily Goal (oz)", text: $newGoalInput
                                )
                            }
                            Button(action: {
                                saveWaterGoal()
                                showingGoalSheet = false
                            }) {
                                Text("Save")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding() // Default padding is often fine
                                    .background(Color.blue) // Form button style might handle this
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .environmentObject(goalSettings)
                        .navigationTitle("Set Water Goal")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction){
                                Button("Cancel"){
                                    showingGoalSheet = false
                                }
                            }
                            
                            ToolbarItem(placement: .confirmationAction){
                                Button("Save"){
                                    showingGoalSheet = false
                                }
                            }
                        }
                    }
                    
            }
            
            //     .padding()
            //        .background(Color(.secondarySystemBackground))
            //        .cornerRadius(15)
        }
        
        private func saveWaterGoal() {
            guard let goalValue = Double(newGoalInput), goalValue > 0 else {
                print("Invalid water goal input: \(newGoalInput)")
                return
            }
            print("Valud water goal input: \(newGoalInput)")
            goalSettings.waterGoal = goalValue
            if let userID = Auth.auth().currentUser?.uid {
                print("Saving target weight for user: \(userID)")
                goalSettings.saveUserGoals(userID: userID)
            } else {
                print("No authenticated user found when saving water goal")
            }
            
            dailyLogService.currentDailyLog?.waterTracker?.goalOunces = goalValue
            
        }

        
    }
#Preview {
    let today = Date()
    
    // Create a dummy DailyLogService and GoalSettings to inject
    let dailyLogService = DailyLogService()
    let goalSettings = GoalSettings()
    
    // Manually populate mock data if needed
    let waterTracker = WaterTracker(totalOunces: 32, goalOunces: 64, date: today)
    let dailyLog = DailyLog(date: today, meals: [], waterTracker: waterTracker)
//    dailyLogService.currentDailyLog = dailyLog
//    goalSettings.waterGoal = 64

    WaterTrackingCardView(date: today)
        .environmentObject(dailyLogService)
        .environmentObject(goalSettings)
}
