import SwiftUI
import AVFoundation

struct WatchAppTestView: View {
    @State private var userInput = ""
    @State private var aiResponse = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Recipe Bot")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    TextField("Ask something...", text: $userInput)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: {
                        sendMessage()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                            Text("Send")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Button(action: {
                        TTSManager.shared.stopSpeaking()
                    }) {
                        HStack {
                            Image(systemName: "speaker.slash.fill")
                            Text("Stop Speaking")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if isLoading {
                        ProgressView("Thinking...")
                            .padding()
                    }

                    if !userInput.isEmpty {
                        Text("You said: \(userInput)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }

                    if !aiResponse.isEmpty {
                        Text(aiResponse)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Recipe Bot")
        }
    }

    func sendMessage() {
        guard let apiKey = getAPIKey(),
              let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            aiResponse = "❌ Missing API Key or invalid URL"
            return
        }

        isLoading = true
        aiResponse = ""

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": """
                         You are a helpful AI recipe bot for a fitness app called MyFitPlate. Provide healthy, easy-to-make recipes based on the user's request. Always use the word "recipe" in your response when providing a recipe (e.g., "Here's a healthy recipe for dinner"). Include ingredients and instructions, and keep the tone friendly and encouraging.

                         Nutritional Breakdown:
                         Calories: X kcal
                         Protein: Y g
                         Fats: Z g
                         Carbs: W g
                         """],
                        ["text": userInput]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isLoading = false }

            guard let data = data else {
                DispatchQueue.main.async {
                    aiResponse = "⚠️ No data received"
                }
                return
            }

            print("🔻 Raw JSON:")
            print(String(data: data, encoding: .utf8) ?? "Unreadable response")

            do {
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                if let text = decoded.candidates.first?.content.parts.first?.text {
                    DispatchQueue.main.async {
                        aiResponse = text
                        TTSManager.shared.speak(text)
                    }
                } else {
                    DispatchQueue.main.async {
                        aiResponse = "⚠️ No response content."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    aiResponse = "⚠️ Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func getAPIKey() -> String? {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["GEMINI_API_KEY"] as? String {
            return key
        }
        return nil
    }
}

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}
