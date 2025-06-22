import Foundation

// 🔹 Represents the top-level response from the FatSecret API, containing a list of foods.
struct FatSecretResponse: Decodable {
    let foods: FoodList? // Optional list of food items returned by the API.
}

// 🔹 Contains an array of food items from the FatSecret API response.
struct FoodList: Decodable {
    let food: [FatSecretFoodItem]? // Optional array of food search results.
}

// Represents a food item with nutritional details, conforming to Codable for serialization,
// Identifiable for SwiftUI lists, and Hashable for set operations.
struct FoodItem: Codable, Identifiable, Hashable {
    var id: String // Unique identifier for the food item.
    var name: String // Name of the food.
    var calories: Double // Calorie content per serving.
    var protein: Double // Protein content in grams.
    var carbs: Double // Carbohydrate content in grams.
    var fats: Double // Fat content in grams.
    var servingSize: String // Description of the serving size.
    var servingWeight: Double // Weight of the serving in grams.
    var timestamp: Date? // Optional timestamp for when the food was added.

    enum CodingKeys: String, CodingKey {
        case id = "food_id" // Maps API's "food_id" to id.
        case name = "food_name" // Maps API's "food_name" to name.
        case calories // Direct mapping for calories.
        case protein // Direct mapping for protein.
        case carbs = "carbohydrate" // Maps API's "carbohydrate" to carbs.
        case fats = "fat" // Maps API's "fat" to fats.
        case servingSize = "serving_description" // Maps API's "serving_description" to servingSize.
        case servingWeight = "metric_serving_amount" // Maps API's "metric_serving_amount" to servingWeight.
        case timestamp // Maps to timestamp for Firestore encoding.
    }

    // Hashable conformance to allow use in Set.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Uses id as the primary hash value.
    }

    // Equality check for Hashable conformance.
    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.calories == rhs.calories &&
               lhs.protein == rhs.protein &&
               lhs.carbs == rhs.carbs &&
               lhs.fats == rhs.fats &&
               lhs.servingSize == rhs.servingSize &&
               lhs.servingWeight == rhs.servingWeight &&
               lhs.timestamp == rhs.timestamp
    }
}

// ✅ Represents a food item from a FatSecret API search result.
struct FatSecretFoodItem: Decodable {
    let foodID: String // Unique identifier from the API.
    let foodName: String? // Optional name of the food.
    let brandName: String? // Optional brand name.
    let foodDescription: String? // Optional description with nutritional info.
    let servingSize: String? // Optional serving size description.
    let servingWeight: Double? // Optional serving weight in grams.

    enum CodingKeys: String, CodingKey {
        case foodID = "food_id" // Maps API's "food_id" to foodID.
        case foodName = "food_name" // Maps API's "food_name" to foodName.
        case brandName = "brand_name" // Maps API's "brand_name" to brandName.
        case foodDescription = "food_description" // Maps API's "food_description" to foodDescription.
        case servingSize // Direct mapping for servingSize.
        case servingWeight // Direct mapping for servingWeight.
    }
}

// ✅ Represents the detailed response from the FatSecret API for a specific food.
struct FatSecretFoodResponse: Decodable {
    let food: FatSecretFood? // Optional detailed food object.
}

// ✅ Represents a detailed food item with servings from the FatSecret API.
struct FatSecretFood: Decodable {
    let foodID: String // Unique identifier.
    let foodName: String // Name of the food.
    let brandName: String? // Optional brand name.
    let servings: FatSecretServings // Container for serving information.

    enum CodingKeys: String, CodingKey {
        case foodID = "food_id" // Maps API's "food_id" to foodID.
        case foodName = "food_name" // Maps API's "food_name" to foodName.
        case brandName = "brand_name" // Maps API's "brand_name" to brandName.
        case servings // Direct mapping for servings.
    }
}

// ✅ Handles cases where "serving" can be a single object or an array in the API response.
struct FatSecretServings: Decodable {
    let serving: [FatSecretServing] // Array of servings.

    enum CodingKeys: String, CodingKey {
        case serving // Key for the serving data.
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Attempts to decode as an array of servings.
        if let servingArray = try? container.decode([FatSecretServing].self, forKey: .serving) {
            self.serving = servingArray
        }
        // Falls back to decoding a single serving and wrapping it in an array.
        else if let singleServing = try? container.decode(FatSecretServing.self, forKey: .serving) {
            self.serving = [singleServing]
        } else {
            self.serving = [] // Defaults to empty array if no servings are found.
        }
    }
}

// ✅ Represents a serving with nutritional details, handling string-based decimal parsing.
struct FatSecretServing: Decodable {
    let calories: String? // Calorie value as a string from the API.
    let protein: String? // Protein value as a string.
    let carbohydrate: String? // Carbohydrate value as a string.
    let fat: String? // Fat value as a string.
    let servingDescription: String? // Description of the serving.
    let metricServingAmount: String? // Serving weight as a string.
    let metricServingUnit: String? // Unit of the serving weight (e.g., "g").

    enum CodingKeys: String, CodingKey {
        case calories, protein, carbohydrate, fat
        case servingDescription = "serving_description"
        case metricServingAmount = "metric_serving_amount"
        case metricServingUnit = "metric_serving_unit"
    }

    // ✅ Parses a string into a Double, handling various formats and edge cases.
    private func parseDouble(from string: String?) -> Double {
        guard let string = string, !string.isEmpty else { return 0.0 } // Returns 0 for nil or empty.
        let cleanedString = string
            .trimmingCharacters(in: .whitespaces) // Removes leading/trailing whitespace.
            .replacingOccurrences(of: ",", with: ".") // Converts commas to decimal points.
        if let value = Double(cleanedString) {
            print("🔍 Parsing \(string) → Cleaned: \(cleanedString), Result: \(value)") // Debug log.
            return value
        }
        print("⚠️ Failed to parse \(string) as Double, returning 0.0") // Debug log for failures.
        return 0.0
    }

    var parsedCalories: Double { return parseDouble(from: calories) } // Parsed calorie value.
    var parsedProtein: Double { return parseDouble(from: protein) } // Parsed protein value.
    var parsedCarbs: Double { return parseDouble(from: carbohydrate) } // Parsed carbohydrate value.
    var parsedFats: Double { return parseDouble(from: fat) } // Parsed fat value.

    var parsedServingWeight: Double {
        let value = parseDouble(from: metricServingAmount)
        // Normalizes large serving weights (e.g., assumes kg if > 1000g).
        if value > 1000.0 {
            print("🔍 Normalizing large serving weight \(value)g to \(value / 1000.0)g")
            return value / 1000.0
        }
        return value != 0.0 ? value : 100.0 // Defaults to 100g if no valid weight.
    }
}

// Manages interactions with the FatSecret API via a proxy, providing food data by barcode or query.
class FatSecretFoodAPIService {
    private let proxyURL = "http://34.75.143.244:8080" // Proxy server URL for API requests.
    private var barcodeCache = Set<String>() // Set to prevent duplicate barcode searches.

    // 🔹 Fetches food details by barcode, caching to avoid duplicates.
    func fetchFoodByBarcode(barcode: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        if barcodeCache.contains(barcode) {
            print("🔄 Skipping duplicate barcode search: \(barcode)") // Logs duplicate skip.
            return
        }
        barcodeCache.insert(barcode) // Adds barcode to cache.

        guard let url = URL(string: "\(proxyURL)/barcode?barcode=\(barcode)") else {
            completion(.failure(APIError.invalidURL)) // Fails if URL is invalid.
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { self.barcodeCache.remove(barcode) } // Clears cache after task.

            if let error = error {
                print("❌ Error fetching barcode '\(barcode)': \(error.localizedDescription)") // Logs network error.
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("⚠️ No data returned for barcode '\(barcode)'") // Logs missing data.
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode([String: [String: String]].self, from: data)
                if let foodId = decodedResponse["food_id"]?["value"] {
                    print("✅ Found Food ID: \(foodId). Fetching full food details...") // Logs successful lookup.

                    // Fetches detailed food data using the found ID.
                    self.fetchFoodDetails(foodId: foodId) { result in
                        switch result {
                        case .success(let foodItem):
                            completion(.success([foodItem])) // Returns as a single-item array.
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    print("⚠️ FatSecret Barcode Lookup Failed for '\(barcode)'") // Logs failed lookup.
                    completion(.failure(APIError.noData))
                }
            } catch {
                print("❌ Decoding Error for barcode '\(barcode)': \(error.localizedDescription)") // Logs decoding error.
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }

    // 🔹 Fetches detailed food information by food ID.
    public func fetchFoodDetails(foodId: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        guard let url = URL(string: "\(proxyURL)/food?food_id=\(foodId)") else {
            completion(.failure(APIError.invalidURL)) // Fails if URL is invalid.
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error fetching food details for ID '\(foodId)': \(error.localizedDescription)") // Logs network error.
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("⚠️ No data returned for food ID '\(foodId)'") // Logs missing data.
                completion(.failure(APIError.noData))
                return
            }

            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("📥 Raw FatSecret API Response (Food Details) for ID \(foodId):\n\(jsonString)") // Logs raw response.

            do {
                let decodedResponse = try JSONDecoder().decode(FatSecretFoodResponse.self, from: data)

                guard let food = decodedResponse.food else {
                    print("⚠️ No food object found in response for ID '\(foodId)'") // Logs missing food.
                    completion(.failure(APIError.noData))
                    return
                }
                print("✅ Successfully parsed food: \(food.foodName)") // Logs successful parse.

                if food.servings.serving.isEmpty {
                    print("⚠️ No serving data found in response for ID '\(foodId)'") // Logs missing servings.
                    completion(.failure(APIError.noData))
                    return
                }

                // Logs available servings for debugging.
                print("🔍 Available servings for ID \(foodId): \(food.servings.serving.map { $0.servingDescription ?? "No description" })")

                // Selects the default serving to use for the food item.
                let defaultServing = self.selectDefaultServing(from: food.servings.serving)

                // Creates a FoodItem from the API data.
                let foodItem = FoodItem(
                    id: food.foodID,
                    name: food.brandName.map { "\($0) \(food.foodName)" } ?? food.foodName,
                    calories: defaultServing.parsedCalories,
                    protein: defaultServing.parsedProtein,
                    carbs: defaultServing.parsedCarbs,
                    fats: defaultServing.parsedFats,
                    servingSize: defaultServing.servingDescription ?? "N/A",
                    servingWeight: defaultServing.parsedServingWeight,
                    timestamp: nil // Timestamp can be set later if needed.
                )

                print("✅ Successfully created FoodItem: \(foodItem.name) with \(foodItem.calories) kcal, Protein: \(foodItem.protein)g, Carbs: \(foodItem.carbs)g, Fats: \(foodItem.fats)g (Serving: \(foodItem.servingSize), Weight: \(foodItem.servingWeight)g)")
                completion(.success(foodItem))
            } catch {
                print("❌ Detailed Decoding Error for food ID '\(foodId)': \(error)") // Logs decoding error.
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }

    // Helper method to select the most appropriate serving from available options.
    private func selectDefaultServing(from servings: [FatSecretServing]) -> FatSecretServing {
        // Logs all available servings for debugging.
        print("🔍 Evaluating servings: \(servings.map { "Description: \($0.servingDescription ?? "N/A"), Weight: \($0.parsedServingWeight)g, Calories: \($0.parsedCalories), Protein: \($0.parsedProtein), Carbs: \($0.parsedCarbs), Fats: \($0.parsedFats)" })")

        // Prioritizes a 100g serving with "g" unit.
        if let hundredGramServing = servings.first(where: { $0.parsedServingWeight == 100.0 && $0.metricServingUnit == "g" }) {
            print("🔍 Selected 100g serving: \(hundredGramServing.servingDescription ?? "N/A") with \(hundredGramServing.parsedCalories) kcal")
            return hundredGramServing
        }

        // Falls back to any "g" unit serving with a reasonable weight (<= 1000g).
        if let gramServing = servings.first(where: { $0.metricServingUnit == "g" && $0.parsedServingWeight <= 1000.0 }) {
            print("🔍 Selected first 'g' unit serving (≤ 1000g): \(gramServing.servingDescription ?? "N/A") with \(gramServing.parsedCalories) kcal")
            return gramServing
        }

        // Falls back to the first serving with a reasonable weight (<= 1000g).
        if let reasonableServing = servings.first(where: { $0.parsedServingWeight <= 1000.0 }) {
            print("🔍 Falling back to first reasonable serving (≤ 1000g): \(reasonableServing.servingDescription ?? "N/A") with \(reasonableServing.parsedCalories) kcal")
            return reasonableServing
        }

        print("🔍 Falling back to first available serving: \(servings.first?.servingDescription ?? "N/A") with \(servings.first?.parsedCalories ?? 0.0) kcal")
        return servings.first! // Returns the first serving if all else fails.
    }

    // 🔹 Fetches food items by search query.
    func fetchFoodByQuery(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(proxyURL)/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            print("⚠️ Invalid URL for query '\(query)'") // Logs invalid URL.
            completion(.success([])) // Returns empty list instead of error.
            return
        }

        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network Error fetching search results for query '\(query)': \(error.localizedDescription)") // Logs network error.
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("⚠️ Non-200 HTTP status for query '\(query)': \(String(describing: (response as? HTTPURLResponse)?.statusCode))") // Logs non-200 status.
                completion(.success([])) // Returns empty list for non-200 responses.
                return
            }

            guard let data = data else {
                print("⚠️ No data returned for query '\(query)'") // Logs missing data.
                completion(.failure(APIError.noData))
                return
            }

            let jsonString = String(data: data, encoding: .utf8) ?? ""
            print("📥 Raw FatSecret API Response (Query):\n\(jsonString)") // Logs raw response.

            do {
                let decodedResponse = try JSONDecoder().decode(FatSecretResponse.self, from: data)
                if let foods = decodedResponse.foods?.food {
                    let foodItems = foods.map { self.parseFoodSearchItem(from: $0) } // Maps search results to FoodItem.
                    print("✅ Found \(foodItems.count) search results for query '\(query)': \(foodItems.map { $0.name })") // Logs results.
                    completion(.success(foodItems))
                } else {
                    print("⚠️ FatSecret returned no search results for query '\(query)'") // Logs no results.
                    completion(.success([])) // Returns empty list.
                }
            } catch {
                print("❌ Decoding Error for query '\(query)': \(error.localizedDescription)") // Logs decoding error.
                completion(.failure(APIError.decodingError))
            }
        }.resume()
    }

    // ✅ Parses a detailed food item from a FatSecretFood response.
    private func parseFoodItem(from fatSecretFood: FatSecretFood) -> FoodItem {
        let fullName = fatSecretFood.brandName.map { "\($0) \(fatSecretFood.foodName)" } ?? fatSecretFood.foodName
        let serving = fatSecretFood.servings.serving.first! // Uses the first serving.

        return FoodItem(
            id: fatSecretFood.foodID,
            name: fullName,
            calories: serving.parsedCalories,
            protein: serving.parsedProtein,
            carbs: serving.parsedCarbs,
            fats: serving.parsedFats,
            servingSize: serving.servingDescription ?? "N/A",
            servingWeight: serving.parsedServingWeight,
            timestamp: nil
        )
    }

    // ✅ Parses a food item from a FatSecretFoodItem search result.
    private func parseFoodSearchItem(from fatSecretFoodItem: FatSecretFoodItem) -> FoodItem {
        let fullName = fatSecretFoodItem.brandName.map { "\($0) \(fatSecretFoodItem.foodName ?? "")" } ?? (fatSecretFoodItem.foodName ?? "Unknown")
        let nutrients = parseNutrients(from: fatSecretFoodItem.foodDescription)

        return FoodItem(
            id: fatSecretFoodItem.foodID,
            name: fullName,
            calories: nutrients.calories,
            protein: nutrients.protein,
            carbs: nutrients.carbs,
            fats: nutrients.fats,
            servingSize: fatSecretFoodItem.servingSize ?? "N/A",
            servingWeight: fatSecretFoodItem.servingWeight ?? 100.0,
            timestamp: nil
        )
    }

    // Parses nutritional information from a food description string.
    private func parseNutrients(from description: String?) -> (calories: Double, protein: Double, carbs: Double, fats: Double) {
        guard let description = description else { return (0.0, 0.0, 0.0, 0.0) } // Returns zeros for nil description.

        var calories = 0.0, protein = 0.0, carbs = 0.0, fats = 0.0

        let components = description.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        for component in components {
            print("🔍 Parsing component: \(component)") // Logs each component for debugging.
            if component.contains("Calories:") {
                let caloriesPart = component.split(separator: "-").last?.trimmingCharacters(in: .whitespaces) ?? component
                let cleaned = caloriesPart.replacingOccurrences(of: "Calories:", with: "")
                    .replacingOccurrences(of: "kcal", with: "")
                    .trimmingCharacters(in: .whitespaces)
                print("🔍 Calories cleaned: \(cleaned)") // Logs cleaned string.
                if let value = Double(cleaned) { calories = value; print("🔍 Calories set to: \(value)") }
                else { print("🔍 Failed to parse calories from: \(cleaned)") }
            } else if component.contains("Fat:") {
                let cleaned = component.replacingOccurrences(of: "Fat:", with: "")
                    .replacingOccurrences(of: "g", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) { fats = value }
            } else if component.contains("Carbs:") {
                let cleaned = component.replacingOccurrences(of: "Carbs:", with: "")
                    .replacingOccurrences(of: "g", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) { carbs = value }
            } else if component.contains("Protein:") {
                let cleaned = component.replacingOccurrences(of: "Protein:", with: "")
                    .replacingOccurrences(of: "g", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let value = Double(cleaned) { protein = value }
            }
        }

        print("🔍 Final nutrients: calories=\(calories), protein=\(protein), carbs=\(carbs), fats=\(fats)") // Logs final values.
        return (calories, protein, carbs, fats)
    }
}
