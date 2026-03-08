import Foundation
import AVFoundation

class GroqTTSService {
    private let apiKey: String
    private let speechURL = URL(string: "https://api.groq.com/openai/v1/audio/speech")!

    static let availableVoices: [(id: String, name: String)] = [
        ("Arista-PlayAI", "Arista (Female)"),
        ("Atlas-PlayAI", "Atlas (Male)"),
        ("Basil-PlayAI", "Basil (Male)"),
        ("Briggs-PlayAI", "Briggs (Male)"),
        ("Calista-PlayAI", "Calista (Female)"),
        ("Celeste-PlayAI", "Celeste (Female)"),
        ("Cheyenne-PlayAI", "Cheyenne (Female)"),
        ("Chip-PlayAI", "Chip (Male)"),
        ("Cillian-PlayAI", "Cillian (Male)"),
        ("Deedee-PlayAI", "Deedee (Female)"),
        ("Fritz-PlayAI", "Fritz (Male)"),
        ("Gail-PlayAI", "Gail (Female)"),
        ("Indigo-PlayAI", "Indigo (Non-Binary)"),
        ("Mamaw-PlayAI", "Mamaw (Female)"),
        ("Mason-PlayAI", "Mason (Male)"),
        ("Mikail-PlayAI", "Mikail (Male)"),
        ("Mitch-PlayAI", "Mitch (Male)"),
        ("Quinn-PlayAI", "Quinn (Non-Binary)"),
        ("Thunder-PlayAI", "Thunder (Male)"),
        ("Wagner-PlayAI", "Wagner (Male)")
    ]

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func synthesizeSpeech(text: String, voice: String = "Arista-PlayAI") async throws -> Data {
        var request = URLRequest(url: speechURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let payload: [String: Any] = [
            "model": "playai-tts",
            "input": text,
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
