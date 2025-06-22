import Foundation

// Represents the top-level response from the OpenFoodFacts API, conforming to Codable for JSON decoding.
struct OpenFoodFactsResponse: Codable {
    let product: OpenFoodFactsProduct? // Optional product data returned by the API.
}

// Represents a product with its name and nutritional details from the OpenFoodFacts API, conforming to Codable.
struct OpenFoodFactsProduct: Codable {
    let productName: String? // Optional name of the product.
    let nutriments: OpenFoodFactsNutriments? // Optional nutritional information.

    enum CodingKeys: String, CodingKey {
        case productName = "product_name" // Maps API's "product_name" to productName.
        case nutriments // Direct mapping for nutriments.
    }
}

// Represents nutritional data for a product, with values per 100g, conforming to Codable.
struct OpenFoodFactsNutriments: Codable {
    let energyKcal: Double? // Energy in kilocalories per 100g.
    let protein: Double? // Protein content per 100g.
    let carbs: Double? // Carbohydrate content per 100g.
    let fats: Double? // Fat content per 100g.
    let servingWeight: Double? // Optional serving weight, if specified.

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g" // Maps API's "energy-kcal_100g" to energyKcal.
        case protein = "proteins_100g" // Maps API's "proteins_100g" to protein.
        case carbs = "carbohydrates_100g" // Maps API's "carbohydrates_100g" to carbs.
        case fats = "fat_100g" // Maps API's "fat_100g" to fats.
        case servingWeight = "serving_size" // Maps API's "serving_size" to servingWeight.
    }
}

// Manages interactions with the OpenFoodFacts API to fetch food data by barcode.
class OpenFoodFactsAPIService {
    // Fetches food details from OpenFoodFacts using a barcode.
    func fetchFoodByBarcode(barcode: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        // Constructs the API URL with the barcode.
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            completion(.failure(APIError.invalidURL)) // Fails with an invalid URL error.
            return
        }

        // Performs an asynchronous data task to fetch the API response.
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { // Checks for network or request errors.
                completion(.failure(error)) // Passes the error to the completion handler.
                return
            }

            guard let data = data else { // Ensures data is received.
                completion(.failure(APIError.noData)) // Fails with a no data error.
                return
            }

            do {
                // Decodes the JSON response into the OpenFoodFactsResponse struct.
                let decodedResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                if let product = decodedResponse.product { // Checks if a product is present.
                    // Creates a FoodItem from the decoded product data, using defaults if values are nil.
                    let foodItem = FoodItem(
                        id: barcode, // Uses the barcode as the unique ID.
                        name: product.productName ?? "Unknown", // Falls back to "Unknown" if no name.
                        calories: product.nutriments?.energyKcal ?? 0, // Defaults to 0 if no calories.
                        protein: product.nutriments?.protein ?? 0, // Defaults to 0 if no protein.
                        carbs: product.nutriments?.carbs ?? 0, // Defaults to 0 if no carbs.
                        fats: product.nutriments?.fats ?? 0, // Defaults to 0 if no fats.
                        servingSize: "100g", // Assumes a standard 100g serving size.
                        servingWeight: product.nutriments?.servingWeight ?? 100.0 // Defaults to 100g if no serving weight.
                    )
                    completion(.success(foodItem)) // Passes the created food item to the completion handler.
                } else {
                    completion(.failure(APIError.noData)) // Fails if no product data is found.
                }
            } catch { // Handles decoding errors.
                completion(.failure(APIError.decodingError)) // Passes the decoding error.
            }
        }.resume() // Starts the data task.
    }
}
