import Foundation

// Defines a custom error enum to handle various API-related issues in the "CalorieBeta" app.
// Conforming to the Error protocol allows it to be used in Swift's error handling system.
enum APIError: Error {
    // Indicates that an invalid or malformed URL was encountered during an API request.
    case invalidURL

    // Indicates that no data was returned from the API, despite a successful network request.
    case noData

    // Indicates that an error occurred while decoding the API response data into a model.
    case decodingError
}
