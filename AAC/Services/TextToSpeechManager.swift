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
                .sorted { $0.name < $1.name }
                .map { (id: $0.identifier, name: "\($0.name) (\($0.language))") }
        }
    }
}

// MARK: - TTS Settings
class TTSSettings: ObservableObject {
    @Published var provider: TTSProvider {
        didSet { save() }
    }
    @Published var groqVoice: String {
        didSet { save() }
    }
    @Published var openAIVoice: String {
        didSet { save() }
    }
    @Published var systemVoice: String {
        didSet { save() }
    }
    @Published var speechRate: Double {
        didSet { save() }
    }

    var currentVoiceId: String {
        switch provider {
        case .groq: return groqVoice
        case .openai: return openAIVoice
        case .system: return systemVoice
        }
    }

    var currentVoiceDisplayName: String {
        let voices = provider.voices
        return voices.first(where: { $0.id == currentVoiceId })?.name ?? currentVoiceId
    }

    init() {
        let defaults = UserDefaults.standard
        self.provider = TTSProvider(rawValue: defaults.string(forKey: "tts_provider") ?? "") ?? .groq
        self.groqVoice = defaults.string(forKey: "tts_groq_voice") ?? "Arista-PlayAI"
        self.openAIVoice = defaults.string(forKey: "tts_openai_voice") ?? "nova"
        self.systemVoice = defaults.string(forKey: "tts_system_voice") ?? (AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? "")
        self.speechRate = defaults.double(forKey: "tts_speech_rate")
        if self.speechRate == 0 { self.speechRate = 0.5 }
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(provider.rawValue, forKey: "tts_provider")
        defaults.set(groqVoice, forKey: "tts_groq_voice")
        defaults.set(openAIVoice, forKey: "tts_openai_voice")
        defaults.set(systemVoice, forKey: "tts_system_voice")
        defaults.set(speechRate, forKey: "tts_speech_rate")
    }
}

// MARK: - TTS Manager
class TextToSpeechManager: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var currentlySpeakingId: String?
    @Published var lastError: String?

    @Published var settings: TTSSettings

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var groqService: GroqTTSService?
    private var openAIService: OpenAITTSService?

    private var audioCache: [String: Data] = [:]

    override init() {
        self.settings = TTSSettings()
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        configureServices()
    }

    private func configureServices() {
        if let groqKey = Secrets.groqApiKey {
            groqService = GroqTTSService(apiKey: groqKey)
            print("[TTS] ✅ Groq service configured")
        } else {
            print("[TTS] ⚠️ No Groq API key — Groq TTS unavailable")
        }

        if let openAIKey = Secrets.openAIApiKey {
            openAIService = OpenAITTSService(apiKey: openAIKey)
            print("[TTS] ✅ OpenAI service configured")
        } else {
            print("[TTS] ⚠️ No OpenAI API key — OpenAI TTS unavailable")
        }
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
        lastError = nil

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
            if groqService != nil {
                speakWithGroq(text: text, cacheKey: cacheKey)
            } else {
                DispatchQueue.main.async {
                    self.lastError = "Groq API key not configured. Check Secrets.plist."
                }
                speakNatively(text: text)
            }
        case .openai:
            if openAIService != nil {
                speakWithOpenAI(text: text, cacheKey: cacheKey)
            } else {
                DispatchQueue.main.async {
                    self.lastError = "OpenAI API key not configured. Check Secrets.plist."
                }
                speakNatively(text: text)
            }
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
        guard let service = groqService else { return }
        Task {
            do {
                print("[TTS] 🔊 Speaking with Groq voice: \(settings.groqVoice)")
                let audioData = try await service.synthesizeSpeech(
                    text: text, voice: settings.groqVoice
                )
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] ❌ Groq TTS failed: \(error)")
                await MainActor.run {
                    self.lastError = "Groq TTS failed: \(error.localizedDescription). Using system voice."
                    self.speakNatively(text: text)
                }
            }
        }
    }

    private func speakWithOpenAI(text: String, cacheKey: String) {
        guard let service = openAIService else { return }
        Task {
            do {
                print("[TTS] 🔊 Speaking with OpenAI voice: \(settings.openAIVoice)")
                let audioData = try await service.synthesizeSpeech(
                    text: text, voice: settings.openAIVoice, speed: settings.speechRate * 2.0
                )
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] ❌ OpenAI TTS failed: \(error)")
                await MainActor.run {
                    self.lastError = "OpenAI TTS failed: \(error.localizedDescription). Using system voice."
                    self.speakNatively(text: text)
                }
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
