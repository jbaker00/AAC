import Foundation

/// OpenAI TTS service using the tts-1 model
class OpenAITTSService {
    private let apiKey: String
    private let speechURL = URL(string: "https://api.openai.com/v1/audio/speech")!

    static let availableVoices: [(id: String, name: String)] = [
        ("alloy", "Alloy (Neutral)"),
        ("echo", "Echo (Male)"),
        ("fable", "Fable (British)"),
        ("onyx", "Onyx (Deep Male)"),
        ("nova", "Nova (Female)"),
        ("shimmer", "Shimmer (Soft Female)")
    ]

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func synthesizeSpeech(text: String, voice: String = "nova", speed: Double = 1.0) async throws -> Data {
        var request = URLRequest(url: speechURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let payload: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice,
            "response_format": "mp3",
            "speed": speed
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAITTSError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return data
    }
}

enum OpenAITTSError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenAI TTS API"
        case .apiError(let statusCode, let message):
            return "OpenAI TTS API error (\(statusCode)): \(message)"
        }
    }
}
