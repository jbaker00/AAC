import Foundation
import AVFoundation

class GroqTTSService {
    private let apiKey: String
    private let speechURL = URL(string: "https://api.groq.com/openai/v1/audio/speech")!

    static let availableVoices: [(id: String, name: String)] = [
        ("autumn", "Autumn (Female)"),
        ("diana", "Diana (Female)"),
        ("hannah", "Hannah (Female)"),
        ("austin", "Austin (Male)"),
        ("daniel", "Daniel (Male)"),
        ("troy", "Troy (Male)")
    ]

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Note: Groq Orpheus has a 200 character input limit
    func synthesizeSpeech(text: String, voice: String = "diana") async throws -> Data {
        var request = URLRequest(url: speechURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        // Truncate to 200 chars (Groq Orpheus limit)
        let truncatedText = String(text.prefix(200))

        let payload: [String: Any] = [
            "model": "canopylabs/orpheus-v1-english",
            "input": truncatedText,
            "voice": voice,
            "response_format": "wav"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqTTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GroqTTSError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return data
    }
}

enum GroqTTSError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Groq TTS API"
        case .apiError(let statusCode, let message):
            return "Groq TTS API error (\(statusCode)): \(message)"
        }
    }
}
