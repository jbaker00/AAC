import Foundation

/// OpenAI TTS via the api-proxy Cloud Function (tts-1 pinned server-side).
/// The OpenAI key lives in Firebase Secret Manager; the app ships no credentials.
class OpenAITTSService {
    private let speechURL = URL(string: "https://us-central1-jbaker-api-proxy.cloudfunctions.net/api/v1/tts")!

    static let availableVoices: [(id: String, name: String)] = [
        ("alloy", "Alloy (Neutral)"),
        ("echo", "Echo (Male)"),
        ("fable", "Fable (British)"),
        ("onyx", "Onyx (Deep Male)"),
        ("nova", "Nova (Female)"),
        ("shimmer", "Shimmer (Soft Female)")
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

    func synthesizeSpeech(text: String, voice: String = "nova", speed: Double = 1.0) async throws -> Data {
        var request = URLRequest(url: speechURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.deviceId, forHTTPHeaderField: "x-device-id")
        request.timeoutInterval = 15

        let payload: [String: Any] = [
            "text": text,
            "voice": voice,
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
            return "Invalid response from TTS proxy"
        case .apiError(let statusCode, let message):
            return "TTS proxy error (\(statusCode)): \(message)"
        }
    }
}
