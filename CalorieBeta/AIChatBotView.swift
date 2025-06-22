import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AIChatbotView: View {
    @State private var userMessage = ""
//    @State private var chatMessages: [ChatMessage] = loadChatHistory()
    @State private var chatMessages: [ChatMessage] = loadChatHistory()
    @State private var isLoading = false
    @State private var showHistorySheet = false
    @Binding var selectedTab: Int
    @EnvironmentObject var goalSettings: GoalSettings
    @EnvironmentObject var dailyLogService: DailyLogService
    @Environment(\.colorScheme) var colorScheme
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(selectedTab: Binding<Int>, chatMessages: [ChatMessage] = []) {
        self._selectedTab = selectedTab
        self._chatMessages = State(initialValue: chatMessages)
    }

    private var remainingCalories: Double {
        let totalCalories = dailyLogService.currentDailyLog?.totalCalories() ?? 0
        let calorieGoal = goalSettings.calories ?? 2000
        return max(0, calorieGoal - totalCalories)
    }

    private var remainingProtein: Double {
        let totalProtein = dailyLogService.currentDailyLog?.totalMacros().protein ?? 0
        return max(0, goalSettings.protein - totalProtein)
    }

    private var remainingFats: Double {
        let totalFats = dailyLogService.currentDailyLog?.totalMacros().fats ?? 0
        return max(0, goalSettings.fats - totalFats)
    }

    private var remainingCarbs: Double {
        let totalCarbs = dailyLogService.currentDailyLog?.totalMacros().carbs ?? 0
        return max(0, goalSettings.carbs - totalCarbs)
    }

    private var remainingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remaining Goals for Today")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Text("Calories: \(String(format: "%.0f", remainingCalories)) kcal")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Protein: \(String(format: "%.0f", remainingProtein)) g")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Fats: \(String(format: "%.0f", remainingFats)) g")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Carbs: \(String(format: "%.0f", remainingCarbs)) g")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        
    }

//    private var chatHistorySection: some View {
//        
//    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
       
                TextField("Ask for a healthy recipe...", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .submitLabel(.done)
                    .onSubmit {
                        sendMessage()
                        hideKeyboard()
                        saveChatHistory()
                    }

                Button(action: {
                    sendMessage()
                    saveChatHistory()
                    hideKeyboard()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.white)
                }
                .disabled(isLoading || userMessage.isEmpty)
                .background(Color(red: 67/255, green: 173/255, blue: 111/255))
                .clipShape(Circle())
            }
            .padding()
            .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)

            
            // Moved "Done" button functionality to paperplane
//            Button(action: {
//                selectedTab = 0
//                hideKeyboard()
//                saveChatHistory()
//            }) {
//                Text("Done")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color(red: 67/255, green: 173/255, blue: 111/255))
//                    .cornerRadius(25)
//            }
//            .padding(.horizontal)
//            .padding(.bottom, 12)
        }
    }

    var body: some View {
        var showingHistorySheet = false
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        remainingGoalsSection
                        //                    chatHistorySection
                        ForEach(chatMessages) { message in
                            ChatBubble(
                                message: message,
                                onLogRecipe: logRecipe,
                                showAlert: $showAlert,
                                alertMessage: $alertMessage
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.vertical)
                    
                }
                .onChange(of: chatMessages) { _ in
                    if let last = chatMessages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                    }
                    
                }
            
                inputSection
            }
    
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)
//        .navigationTitle("AI Recipe Bot")
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) { Text("AI Recipe Bot").font(.headline).foregroundColor(.primary.opacity(0.5)).padding(.leading, 5) }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button( action : {
                    showHistorySheet = true
                }){ Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90").font(.title2).foregroundColor(.gray)
                    
                }
                    
                }
            }
              
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            if let userID = Auth.auth().currentUser?.uid {
                dailyLogService.fetchOrCreateTodayLog(for: userID) { result in
                    switch result {
                    case .success(let log):
                        dailyLogService.currentDailyLog = log
                    case .failure(let error):
                        print("❌ Error fetching daily log on appear: \(error.localizedDescription)")
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        
        .sheet(isPresented: $showHistorySheet) {
            ShowHistory()
                .environmentObject(dailyLogService)
        }
    }

    func sendMessage() {
        guard !userMessage.isEmpty else { return }

        let userChatMessage = ChatMessage(id: UUID(), text: userMessage, isUser: true)
        chatMessages.append(userChatMessage)

        userMessage = ""
        isLoading = true

        fetchGPT3Response(for: userChatMessage.text) { aiResponseText in
            let aiChatMessage = ChatMessage(id: UUID(), text: aiResponseText, isUser: false)
            chatMessages.append(aiChatMessage)
            isLoading = false
        }
    }

    func fetchGPT3Response(for message: String, completion: @escaping (String) -> Void) {
        let apiKey = "add_api_key"
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are a helpful AI recipe bot for a fitness app called MyFitPlate. Provide healthy, easy-to-make recipes based on the user's request. Always use the word "recipe" in your response when providing a recipe (e.g., "Here's a healthy recipe for dinner"). Include ingredients and instructions, and keep the tone friendly and encouraging. If the user asks for something unhealthy, suggest a healthier alternative.

        The user has the following remaining nutritional goals for the day:
        - Calories: \(String(format: "%.0f", remainingCalories)) kcal
        - Protein: \(String(format: "%.0f", remainingProtein)) g
        - Fats: \(String(format: "%.0f", remainingFats)) g
        - Carbs: \(String(format: "%.0f", remainingCarbs)) g

        If the user specifies a calorie target in their request, prioritize meeting that calorie target as closely as possible. Recognize calorie targets in formats like "1k calorie recipe" (which means 1000 calories), "500 calorie meal", "a recipe for 1200 calories", or similar phrases. To meet the calorie target, scale the recipe by adjusting serving sizes, increasing ingredient quantities, or adding calorie-dense ingredients like nuts, oils, or spreads (e.g., peanut butter, avocado). For example, if the user requests a 1000-calorie pancake recipe, you might increase the batter quantity, add toppings like peanut butter or maple syrup, or adjust the serving size to meet the target.
        
        If the calorie target is significantly higher than the base recipe, calculate the total calories of the base recipe, determine a scaling factor (target calories / base calories), and multiply all ingredient quantities by this factor to meet the target. For example, if the base recipe is 1500 calories and the target is 2400 calories, scale all ingredients by a factor of 2400 / 1500 = 1.6.

        If the requested calorie target exceeds the user's remaining calories, include a note in your response indicating that the recipe exceeds their remaining daily goals, but still provide the recipe as requested. If no calorie target is specified, suggest a recipe that fits within the user's remaining goals as closely as possible.
        

        For debugging purposes, include a note in your response explaining how you interpreted the user's calorie target (e.g., "Interpreted calorie target: 1000 calories from '1k calorie recipe'").

        If the user doesn't specify a meal type, suggest something appropriate for the next meal of the day based on the current time (e.g., breakfast if morning, lunch if midday, dinner if evening). At the end of the recipe, include a nutritional breakdown in the exact format below, with each value on a new line:
        Nutritional Breakdown:
        Calories: X kcal
        Protein: Y g
        Fats: Z g
        Carbs: W g
        Replace X, Y, Z, and W with the numerical values (e.g., Calories: 350 kcal). Do not include any additional text or units after the numbers.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": message]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion("Error: Failed to serialize request body.")
            return
        }
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    completion("Error: No data received from the API.")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let messageDict = firstChoice["message"] as? [String: Any],
                       let content = messageDict["content"] as? String {
                        completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        completion("Error: Invalid response format from the API.")
                    }
                } catch {
                    completion("Error: Failed to parse API response - \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    func logRecipe(recipeText: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No user ID found for logging recipe.")
            alertMessage = "Unable to log recipe: No user is logged in."
            showAlert = true
            return
        }

        print("📝 Recipe Text:\n\(recipeText)")

        let nutritionalBreakdown = parseNutritionalBreakdown(from: recipeText)
        guard let calories = nutritionalBreakdown["calories"],
              let protein = nutritionalBreakdown["protein"],
              let fats = nutritionalBreakdown["fats"],
              let carbs = nutritionalBreakdown["carbs"] else {
            print("❌ Failed to parse nutritional breakdown from recipe.")
            alertMessage = "Unable to log recipe: Missing nutritional information."
            showAlert = true
            return
        }

        let recipeName = recipeText.components(separatedBy: "\n").first ?? "Custom Recipe"

        let recipeFoodItem = FoodItem(
            id: UUID().uuidString,
            name: recipeName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            servingSize: "1 serving",
            servingWeight: 0.0,
            timestamp: Date()
        )

        let mealType = determineMealType()
        dailyLogService.addMealToCurrentLog(for: userID, mealName: mealType, foodItems: [recipeFoodItem], date: Date())
    }

    private func parseNutritionalBreakdown(from recipeText: String) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        let lines = recipeText.components(separatedBy: "\n")

        var breakdownStarted = false
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == "Nutritional Breakdown:" {
                breakdownStarted = true
                continue
            }
            
            if breakdownStarted {
                let components = trimmedLine.components(separatedBy: ": ")
                if components.count == 2 {
                    let valueString = components[1]
                        .components(separatedBy: " ")
                        .first ?? "0"
                    if let value = Double(valueString) {
                        if trimmedLine.lowercased().contains("calories") {
                            breakdown["calories"] = value
                        } else if trimmedLine.lowercased().contains("protein") {
                            breakdown["protein"] = value
                        } else if trimmedLine.lowercased().contains("fats") {
                            breakdown["fats"] = value
                        } else if trimmedLine.lowercased().contains("carbs") {
                            breakdown["carbs"] = value
                        }
                    }
                }
            }
        }
        
        print("🔍 Parsed Nutritional Breakdown: \(breakdown)")
        return breakdown
    }

    private func determineMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<11:
            return "Breakfast"
        case 11..<16:
            return "Lunch"
        case 16..<21:
            return "Dinner"
        default:
            return "Snack"
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func saveChatHistory() {
        let maxMessages = 8
        if chatMessages.count > maxMessages {
            let trimmedMessages = Array(chatMessages.suffix(maxMessages))
            UserDefaults.standard.set(try? JSONEncoder().encode(trimmedMessages), forKey: "chatHistory")
        } else {
            UserDefaults.standard.set(try? JSONEncoder().encode(chatMessages), forKey: "chatHistory")
        }
    }
}

func loadChatHistory() -> [ChatMessage] {
    if let data = UserDefaults.standard.data(forKey: "chatHistory"),
       let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
        return messages
    }
    return []
}

struct ShowHistory: View {
    @State private var chatMessages: [ChatMessage] = loadChatHistory()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var dailyLogService: DailyLogService
    @Environment(\.colorScheme) var colorScheme
    
    func logRecipe(recipeText: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No user ID found for logging recipe.")
            alertMessage = "Unable to log recipe: No user is logged in."
            showAlert = true
            return
        }
        
        print("📝 Recipe Text:\n\(recipeText)")
        
        let nutritionalBreakdown = parseNutritionalBreakdown(from: recipeText)
        guard let calories = nutritionalBreakdown["calories"],
              let protein = nutritionalBreakdown["protein"],
              let fats = nutritionalBreakdown["fats"],
              let carbs = nutritionalBreakdown["carbs"] else {
            print("❌ Failed to parse nutritional breakdown from recipe.")
            alertMessage = "Unable to log recipe: Missing nutritional information."
            showAlert = true
            return
        }
        
        let recipeName = recipeText.components(separatedBy: "\n").first ?? "Custom Recipe"
        
        let recipeFoodItem = FoodItem(
            id: UUID().uuidString,
            name: recipeName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            servingSize: "1 serving",
            servingWeight: 0.0,
            timestamp: Date()
        )
        
        let mealType = determineMealType()
        dailyLogService.addMealToCurrentLog(for: userID, mealName: mealType, foodItems: [recipeFoodItem], date: Date())
    }
    
    private func determineMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<11:
            return "Breakfast"
        case 11..<16:
            return "Lunch"
        case 16..<21:
            return "Dinner"
        default:
            return "Snack"
        }
    }
    
    private func parseNutritionalBreakdown(from recipeText: String) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        let lines = recipeText.components(separatedBy: "\n")
        
        var breakdownStarted = false
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == "Nutritional Breakdown:" {
                breakdownStarted = true
                continue
            }
            
            if breakdownStarted {
                let components = trimmedLine.components(separatedBy: ": ")
                if components.count == 2 {
                    let valueString = components[1]
                        .components(separatedBy: " ")
                        .first ?? "0"
                    if let value = Double(valueString) {
                        if trimmedLine.lowercased().contains("calories") {
                            breakdown["calories"] = value
                        } else if trimmedLine.lowercased().contains("protein") {
                            breakdown["protein"] = value
                        } else if trimmedLine.lowercased().contains("fats") {
                            breakdown["fats"] = value
                        } else if trimmedLine.lowercased().contains("carbs") {
                            breakdown["carbs"] = value
                        }
                    }
                }
            }
        }
        
        print("🔍 Parsed Nutritional Breakdown: \(breakdown)")
        return breakdown
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chat History")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .white)
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chatMessages) { message in
                            ChatBubble(
                                message: message,
                                onLogRecipe: { recipeText in
                                    logRecipe(recipeText: recipeText)
                                },
                                showAlert: $showAlert,
                                alertMessage: $alertMessage
                            )
                            .id(message.id)
                        }
                    }
                    .onChange(of: chatMessages) { _ in
                        if let lastMessageId = chatMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastMessageId, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessageId = chatMessages.last?.id {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        
    }
        
        
}


struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isUser == rhs.isUser
    }
}



struct ChatBubble: View {
    let message: ChatMessage
    let onLogRecipe: (String) -> Void
    @Environment(\.colorScheme) var colorScheme
    @Binding var showAlert: Bool
    @Binding var alertMessage: String

    private let containsRecipeKeyword: Bool
    private let containsNutritionalBreakdown: Bool
    private let shouldShowLogButton: Bool

    init(message: ChatMessage, onLogRecipe: @escaping (String) -> Void, showAlert: Binding<Bool>, alertMessage: Binding<String>) {
        self.message = message
        self.onLogRecipe = onLogRecipe
        self._showAlert = showAlert
        self._alertMessage = alertMessage
        self.containsRecipeKeyword = message.text.lowercased().contains("recipe")
        self.containsNutritionalBreakdown = message.text.contains("Nutritional Breakdown:")
        self.shouldShowLogButton = !message.isUser && (containsRecipeKeyword || containsNutritionalBreakdown)
    }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.isUser {
                    
                    Spacer()
                }
                Text(message.text)
                    .padding()
                    .background(message.isUser ? Color(red: 67/255, green: 173/255, blue: 111/255) : Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(message.isUser ? .white : .white)
                    .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)

                if !message.isUser {
                    Spacer()
                }
            }
            .padding(message.isUser ? .leading : .trailing, 40)

            if shouldShowLogButton {
                Button(action: {
                    onLogRecipe(message.text)
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                    alertMessage = "Recipe successfully logged!"
                    showAlert = true
                }) {
                    Text("Log Recipe")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(red: 67/255, green: 173/255, blue: 111/255))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            logDebugInfo(containsRecipeKeyword: containsRecipeKeyword, containsNutritionalBreakdown: containsNutritionalBreakdown, shouldShowLogButton: shouldShowLogButton)
        }
    }

    private func logDebugInfo(containsRecipeKeyword: Bool, containsNutritionalBreakdown: Bool, shouldShowLogButton: Bool) {
        if !message.isUser {
            print("🔍 ChatBubble - Message: \(message.text.prefix(50))... | Contains 'recipe': \(containsRecipeKeyword) | Contains 'Nutritional Breakdown:': \(containsNutritionalBreakdown) | Should show Log Recipe button: \(shouldShowLogButton)")
        }
    }
}



//#Preview {
//    // Mock environment objects
//    let goalSettings = GoalSettings()
//    let dailyLogService = DailyLogService()
//    
//    goalSettings.calories = 2000
//    goalSettings.protein = 150
//    goalSettings.carbs = 250
//    goalSettings.fats = 70
//    
//    dailyLogService.currentDailyLog = DailyLog(date: Date(), meals: [], waterTracker: WaterTracker(totalOunces: 0, goalOunces: 64, date: Date()))
//    
//    return NavigationView {
//        AIChatbotView(selectedTab: .constant(1))
//            .environmentObject(goalSettings)
//            .environmentObject(dailyLogService)
//    }
//}
