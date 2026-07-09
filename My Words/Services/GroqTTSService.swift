import Foundation
import AVFoundation

/// Groq Orpheus TTS via the api-proxy Cloud Function (model pinned server-side).
/// The Groq key lives in Firebase Secret Manager; the app ships no credentials.
class GroqTTSService {
    private let speechURL = URL(string: "https://us-central1-jbaker-api-proxy.cloudfunctions.net/api/v1/tts-groq")!

    static let availableVoices: [(id: String, name: String)] = [
        ("autumn", "Autumn (Female)"),
        ("diana", "Diana (Female)"),
        ("hannah", "Hannah (Female)"),
        ("austin", "Austin (Male)"),
        ("daniel", "Daniel (Male)"),
        ("troy", "Troy (Male)")
    ]

    private static var deviceId: String {
        let key = "proxyDeviceId"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }

    // apiKey retained for call-site compatibility; the proxy needs no key
    init(apiKey: String? = nil) {}

    /// Note: Groq Orpheus has a 200 character input limit (also enforced server-side)
    func synthesizeSpeech(text: String, voice: String = "diana") async throws -> Data {
        var request = URLRequest(url: speechURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        request.timeoutInterval = 15

        let payload: [String: Any] = [
            "text": String(text.prefix(200)),
            "voice": voice
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
