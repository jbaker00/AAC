import Foundation
import AVFoundation

// MARK: - TTS Provider Enum
enum TTSProvider: String, CaseIterable, Codable {
    case groq = "Groq"
    case openai = "OpenAI"
    case system = "System"

    var displayName: String { rawValue }

    var voices: [(id: String, name: String)] {
        switch self {
        case .groq: return GroqTTSService.availableVoices
        case .openai: return OpenAITTSService.availableVoices
        case .system: return AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language.hasPrefix("en") }
                .map { (id: $0.identifier, name: "\($0.name) (\($0.language))") }
        }
    }
}

// MARK: - TTS Settings
class TTSSettings: ObservableObject, Codable {
    @Published var provider: TTSProvider
    @Published var groqVoice: String
    @Published var openAIVoice: String
    @Published var systemVoice: String
    @Published var speechRate: Double

    enum CodingKeys: String, CodingKey {
        case provider, groqVoice, openAIVoice, systemVoice, speechRate
    }

    init() {
        self.provider = .groq
        self.groqVoice = "Arista-PlayAI"
        self.openAIVoice = "nova"
        self.systemVoice = AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? ""
        self.speechRate = 0.5
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decode(TTSProvider.self, forKey: .provider)
        groqVoice = try container.decode(String.self, forKey: .groqVoice)
        openAIVoice = try container.decode(String.self, forKey: .openAIVoice)
        systemVoice = try container.decode(String.self, forKey: .systemVoice)
        speechRate = try container.decode(Double.self, forKey: .speechRate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(groqVoice, forKey: .groqVoice)
        try container.encode(openAIVoice, forKey: .openAIVoice)
        try container.encode(systemVoice, forKey: .systemVoice)
        try container.encode(speechRate, forKey: .speechRate)
    }

    var currentVoiceId: String {
        switch provider {
        case .groq: return groqVoice
        case .openai: return openAIVoice
        case .system: return systemVoice
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "tts_settings")
        }
    }

    static func load() -> TTSSettings {
        guard let data = UserDefaults.standard.data(forKey: "tts_settings"),
              let settings = try? JSONDecoder().decode(TTSSettings.self, from: data)
        else {
            return TTSSettings()
        }
        return settings
    }
}

// MARK: - TTS Manager
class TextToSpeechManager: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var currentlySpeakingId: String?
    @Published var settings: TTSSettings

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private lazy var groqService = GroqTTSService(apiKey: Secrets.groqApiKey)
    private lazy var openAIService = OpenAITTSService(apiKey: Secrets.openAIApiKey)

    private var audioCache: [String: Data] = [:]

    override init() {
        self.settings = TTSSettings.load()
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[TTS] Audio session setup failed: \(error)")
        }
    }

    func speak(text: String, itemId: String? = nil) {
        stop()

        let cacheKey = "\(settings.provider.rawValue)_\(settings.currentVoiceId)_\(text.lowercased())"

        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentlySpeakingId = itemId
        }

        // Check cache first
        if let cachedAudio = audioCache[cacheKey] {
            playAudioData(cachedAudio)
            return
        }

        switch settings.provider {
        case .groq:
            speakWithGroq(text: text, cacheKey: cacheKey)
        case .openai:
            speakWithOpenAI(text: text, cacheKey: cacheKey)
        case .system:
            speakNatively(text: text)
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlySpeakingId = nil
        }
    }

    func clearCache() {
        audioCache.removeAll()
    }

    // MARK: - Private TTS Methods

    private func speakWithGroq(text: String, cacheKey: String) {
        Task {
            do {
                let audioData = try await groqService.synthesizeSpeech(
                    text: text, voice: settings.groqVoice
                )
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] Groq TTS failed, falling back to system: \(error)")
                await MainActor.run { self.speakNatively(text: text) }
            }
        }
    }

    private func speakWithOpenAI(text: String, cacheKey: String) {
        Task {
            do {
                let audioData = try await openAIService.synthesizeSpeech(
                    text: text, voice: settings.openAIVoice, speed: settings.speechRate * 2.0
                )
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] OpenAI TTS failed, falling back to system: \(error)")
                await MainActor.run { self.speakNatively(text: text) }
            }
        }
    }

    private func playAudioData(_ data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("[TTS] Audio playback failed: \(error)")
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.currentlySpeakingId = nil
            }
        }
    }

    private func speakNatively(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        if !settings.systemVoice.isEmpty {
            utterance.voice = AVSpeechSynthesisVoice(identifier: settings.systemVoice)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = Float(settings.speechRate)
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }
}

// MARK: - AVAudioPlayerDelegate
extension TextToSpeechManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlySpeakingId = nil
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TextToSpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlySpeakingId = nil
        }
    }
}
