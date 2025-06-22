    import Foundation
    import FirebaseAuth
    import FirebaseFirestore

    // If Models.swift is in a different module, import it here
    // import YourModuleName
    import SwiftUI


    class DailyLogService: ObservableObject {
        
        @EnvironmentObject var goalSettings: GoalSettings
        @Published var currentDailyLog: DailyLog?
        private let db = Firestore.firestore()
        private var logListener: ListenerRegistration?
        private let recentFoodsCollection = "recentFoods"
        
        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
        
        init() {}
        
        func fetchLog(for userID: String, date: Date, completion: @escaping (Result<DailyLog, Error>) -> Void) {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let dateString = dateFormatter.string(from: startOfDay)
            let logRef = db.collection("users").document(userID).collection("dailyLogs").document(dateString)
            
            logRef.getDocument(completion: { document, error in
                if let error = error {
                    print("❌ Firestore fetch error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                if let document = document, document.exists, let data = document.data() {
                    print("🔍 Firestore fetched data for \(dateString): \(data)")
                    let log = self.decodeDailyLog(from: data, documentID: dateString)
                    completion(.success(log))
                } else {
                    print("🔍 No log found for \(dateString), creating a new one.")
                    let newLog = DailyLog(id: dateString, date: startOfDay, meals: [], waterTracker: nil)
                    do {
                        try logRef.setData(from: newLog) { error in
                            if let error = error {
                                print("❌ Firestore save error: \(error.localizedDescription)")
                                completion(.failure(error))
                            } else {
                                completion(.success(newLog))
                            }
                        }
                    } catch {
                        print("❌ Firestore encoding error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            })
        }
        
        func fetchOrCreateTodayLog(for userID: String, completion: @escaping (Result<DailyLog, Error>) -> Void) {
            fetchLog(for: userID, date: Date(), completion: completion)
        }
        
        func addFoodToCurrentLog(for userID: String, foodItem: FoodItem, date: Date) {
            fetchLog(for: userID, date: date) { result in
                switch result {
                case .success(var log):
                    let timestampedFoodItem = FoodItem(
                        id: foodItem.id,
                        name: foodItem.name,
                        calories: foodItem.calories,
                        protein: foodItem.protein,
                        carbs: foodItem.carbs,
                        fats: foodItem.fats,
                        servingSize: foodItem.servingSize,
                        servingWeight: foodItem.servingWeight,
                        timestamp: Date()
                    )
                    
                    if log.meals.isEmpty {
                        log.meals.append(Meal(id: UUID().uuidString, name: "All Meals", foodItems: [timestampedFoodItem]))
                    } else {
                        log.meals[0].foodItems.append(timestampedFoodItem)
                    }
                    
                    self.updateDailyLog(for: userID, updatedLog: log)
                    self.addRecentFood(for: userID, foodId: foodItem.id)
                case .failure(let error):
                    print("❌ Error fetching log to add food: \(error.localizedDescription)")
                }
            }
        }
        
        func addMealToCurrentLog(for userID: String, mealName: String, foodItems: [FoodItem], date: Date) {
            fetchLog(for: userID, date: date) { result in
                switch result {
                case .success(var log):
                    let newMeal = Meal(
                        id: UUID().uuidString,
                        name: mealName,
                        foodItems: foodItems.map { foodItem in
                            FoodItem(
                                id: foodItem.id,
                                name: foodItem.name,
                                calories: foodItem.calories,
                                protein: foodItem.protein,
                                carbs: foodItem.carbs,
                                fats: foodItem.fats,
                                servingSize: foodItem.servingSize,
                                servingWeight: foodItem.servingWeight,
                                timestamp: Date()
                            )
                        }
                    )
                    
                    log.meals.append(newMeal)
                    self.updateDailyLog(for: userID, updatedLog: log)
                    print("✅ Added meal '\(mealName)' with \(foodItems.count) items to log for \(self.dateFormatter.string(from: date))")
                case .failure(let error):
                    print("❌ Error fetching log to add meal: \(error.localizedDescription)")
                }
            }
        }
        
        func deleteFoodFromCurrentLog(for userID: String, foodItemID: String, date: Date) {
            fetchLog(for: userID, date: date) { result in
                switch result {
                case .success(var log):
                    for i in log.meals.indices {
                        log.meals[i].foodItems.removeAll { $0.id == foodItemID }
                    }
                    self.updateDailyLog(for: userID, updatedLog: log)
                case .failure(let error):
                    print("❌ Error fetching log to delete food: \(error.localizedDescription)")
                }
            }
        }
        
        func addWaterToCurrentLog(for userID: String, date: Date, amount: Double, goalOunces: Double) {
            fetchLog(for: userID, date: date) { result in
                switch result {
                case .success(var log):
                    let glassSize: Double = 8.0
                    let currentDate = Calendar.current.startOfDay(for: date)

                
                    if var waterTracker = log.waterTracker {
                        if Calendar.current.isDate(waterTracker.date, inSameDayAs: currentDate) {
    //                        waterTracker.totalOunces += amount
                            let originalAmount = waterTracker.totalOunces
                            let addedAmount = amount // this is the function parameter you meant to use
                            waterTracker.totalOunces += addedAmount
                            let newAmount = waterTracker.totalOunces
                            let remaining = waterTracker.goalOunces - newAmount

                            print("original amount: \(originalAmount)")
                            print("added amount: \(addedAmount)")
                            print("new total: \(newAmount)")
                            print("remaining to goal: \(remaining)")

                            
                            
                            
                            
                            
                            
                            

                        } else {
                            waterTracker = WaterTracker(totalOunces: amount, goalOunces: self.goalSettings.waterGoal, date: currentDate)
                            print("SERVICE: Adding \(amount)oz to log for \(date)")
                        }
                        log.waterTracker = waterTracker
                    } else {
                        log.waterTracker = WaterTracker(totalOunces: amount, goalOunces: goalOunces ,date: currentDate)
                        print("SERVICE: Adding \(amount)oz to log for \(date)")
                    }

                    self.updateDailyLog(for: userID, updatedLog: log)
                    print("✅ Added 8 oz of water to log for \(self.dateFormatter.string(from: date)). Total: \(log.waterTracker?.totalOunces ?? 0) oz")
                case .failure(let error):
                    print("❌ Error fetching log to add water: \(error.localizedDescription)")
                }
            }
        }
        
        private func addRecentFood(for userID: String, foodId: String) {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let recentRef = self.db.collection("users").document(userID).collection(recentFoodsCollection)
            
            recentRef.order(by: "timestamp", descending: true).limit(to: 10).getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching recent foods for deduplication: \(error.localizedDescription)")
                    return
                }
                
                let batch = self.db.batch()
                let existingFoodIds = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []
                
                if existingFoodIds.contains(foodId) {
                    if existingFoodIds.count >= 10 {
                        if let oldestDoc = snapshot?.documents.last {
                            batch.deleteDocument(oldestDoc.reference)
                        }
                    }
                } else if existingFoodIds.count >= 10 {
                    if let oldestDoc = snapshot?.documents.last {
                        batch.deleteDocument(oldestDoc.reference)
                    }
                }
                
                let thirtyDaysAgo = Timestamp(date: Date().addingTimeInterval(-30 * 24 * 3600))
                recentRef.whereField("timestamp", isLessThan: thirtyDaysAgo).getDocuments { oldSnapshot, oldError in
                    if let oldError = oldError {
                        print("❌ Error cleaning old recent foods: \(oldError.localizedDescription)")
                        return
                    }
                    if let oldDocuments = oldSnapshot?.documents {
                        for document in oldDocuments {
                            batch.deleteDocument(document.reference)
                        }
                    }
                    
                    let newDocRef = recentRef.document()
                    batch.setData([
                        "foodId": foodId,
                        "timestamp": Timestamp(date: Date())
                    ], forDocument: newDocRef)
                    
                    batch.commit { error in
                        if let error = error {
                            print("❌ Error adding recent food: \(error.localizedDescription)")
                        } else {
                            print("✅ Added recent food ID: \(foodId) for user: \(userID)")
                        }
                    }
                }
            }
        }
        
        func fetchRecentFoods(for userID: String, completion: @escaping (Result<[String], Error>) -> Void) {
            guard let userID = Auth.auth().currentUser?.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])))
                return
            }
            
            let recentRef = db.collection("users").document(userID).collection(recentFoodsCollection)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)
            
            recentRef.getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    print("❌ Error fetching recent foods: \(error.localizedDescription)")
                    return
                }
                
                let foodIds: [String] = snapshot?.documents.compactMap { $0.data()["foodId"] as? String } ?? []
                print("✅ Fetched recent food IDs: \(foodIds)")
                completion(.success(foodIds))
            }
        }
        
        private func addNewDailyLog(for userID: String, newLog: DailyLog, completion: @escaping (Result<Void, Error>) -> Void) {
            let logRef = db.collection("users").document(userID).collection("dailyLogs").document(newLog.id ?? UUID().uuidString)
            logRef.setData(encodeDailyLog(newLog)) { error in
                if let error = error { completion(.failure(error)) }
                else { completion(.success(())) }
            }
        }
        
        private func updateDailyLog(for userID: String, updatedLog: DailyLog) {
            let dateString = dateFormatter.string(from: updatedLog.date)
            let logRef = db.collection("users").document(userID).collection("dailyLogs").document(dateString)
            logRef.setData(encodeDailyLog(updatedLog), merge: true)
            DispatchQueue.main.async {
                self.currentDailyLog = updatedLog
            }
        }
        
        func fetchPosts(for userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
            db.collection("posts").whereField("author", isEqualTo: userID).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let posts: [Post] = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Post(
                        id: document.documentID,
                        content: data["content"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                completion(.success(posts))
            }
        }
        
        func fetchAchievements(for userID: String, completion: @escaping (Result<[Achievement], Error>) -> Void) {
            db.collection("users").document(userID).collection("achievements").getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let achievements: [Achievement] = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Achievement(
                        id: document.documentID,
                        title: data["title"] as? String ?? ""
                    )
                } ?? []
                
                completion(.success(achievements))
            }
        }
        
        func fetchDailyHistory(for userID: String, completion: @escaping (Result<[DailyLog], Error>) -> Void) {
            db.collection("users").document(userID).collection("dailyLogs")
                .order(by: "date", descending: true).getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    let logs: [DailyLog] = snapshot?.documents.compactMap { document in
                        self.decodeDailyLog(from: document.data(), documentID: document.documentID)
                    } ?? []
                    
                    print("🔍 Fetched daily history: \(logs.map { "\($0.id ?? "nil") - Meals: \($0.meals.count)" })")
                    completion(.success(logs))
                }
        }
        
        private func encodeDailyLog(_ log: DailyLog) -> [String: Any] {
            var data: [String: Any] = [
                "id": log.id ?? UUID().uuidString,
                "date": Timestamp(date: log.date),
                "meals": log.meals.map { meal in
                    [
                        "id": meal.id,
                        "name": meal.name,
                        "foodItems": meal.foodItems.map { foodItem in
                            [
                                "id": foodItem.id,
                                "name": foodItem.name,
                                "calories": foodItem.calories,
                                "protein": foodItem.protein,
                                "carbs": foodItem.carbs,
                                "fats": foodItem.fats,
                                "servingSize": foodItem.servingSize,
                                "servingWeight": foodItem.servingWeight,
                                "timestamp": foodItem.timestamp.map { Timestamp(date: $0) } ?? NSNull()
                            ]
                        }
                    ]
                }
            ]
            
            if let waterTracker = log.waterTracker {
                data["waterTracker"] = [
                    "totalOunces": waterTracker.totalOunces,
                    "goalOunces": waterTracker.goalOunces,
                    "date": Timestamp(date: waterTracker.date)
                ]
            }
            
            return data
        }
        
        private func decodeDailyLog(from data: [String: Any], documentID: String) -> DailyLog {
            let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let mealsData = data["meals"] as? [[String: Any]] ?? []
            let meals = mealsData.map { mealData in
                Meal(
                    id: mealData["id"] as? String ?? UUID().uuidString,
                    name: mealData["name"] as? String ?? "Meal",
                    foodItems: (mealData["foodItems"] as? [[String: Any]])?.compactMap { foodItemData in
                        FoodItem(
                            id: foodItemData["id"] as? String ?? UUID().uuidString,
                            name: foodItemData["name"] as? String ?? "",
                            calories: foodItemData["calories"] as? Double ?? 0.0,
                            protein: foodItemData["protein"] as? Double ?? 0.0,
                            carbs: foodItemData["carbs"] as? Double ?? 0.0,
                            fats: foodItemData["fats"] as? Double ?? 0.0,
                            servingSize: foodItemData["servingSize"] as? String ?? "N/A",
                            servingWeight: foodItemData["servingWeight"] as? Double ?? 0.0,
                            timestamp: (foodItemData["timestamp"] as? Timestamp)?.dateValue()
                        )
                    } ?? []
                )
            }
            
            var waterTracker: WaterTracker?
            if let waterData = data["waterTracker"] as? [String: Any] {
                waterTracker = WaterTracker(
                    totalOunces: waterData["totalOunces"] as? Double ?? 0.0,
                    goalOunces: waterData["goalOunces"] as? Double ?? 64.0,
                    date: (waterData["date"] as? Timestamp)?.dateValue() ?? date
                )
            }
            
            return DailyLog(id: documentID, date: date, meals: meals, waterTracker: waterTracker)
        }
    }
