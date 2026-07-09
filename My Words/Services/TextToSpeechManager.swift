import Foundation
import AVFoundation
import Combine
import FirebaseAnalytics

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

    // Valid Groq Orpheus voices
    private static let validGroqVoices = Set(["autumn", "diana", "hannah", "austin", "daniel", "troy"])

    init() {
        let defaults = UserDefaults.standard
        self.provider = TTSProvider(rawValue: defaults.string(forKey: "tts_provider") ?? "") ?? .system
        self.openAIVoice = defaults.string(forKey: "tts_openai_voice") ?? "nova"
        self.systemVoice = defaults.string(forKey: "tts_system_voice") ?? (AVSpeechSynthesisVoice(language: "en-US")?.identifier ?? "")

        // Migrate stale Groq voice from decommissioned PlayAI model
        let savedGroqVoice = defaults.string(forKey: "tts_groq_voice") ?? ""
        if Self.validGroqVoices.contains(savedGroqVoice) {
            self.groqVoice = savedGroqVoice
        } else {
            self.groqVoice = "diana"
            defaults.set("diana", forKey: "tts_groq_voice")
        }

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

    let settings: TTSSettings

    // Forward settings changes to our own objectWillChange
    private var settingsCancellable: AnyCancellable?

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var groqService: GroqTTSService?
    private var openAIService: OpenAITTSService?

    private var audioCache: [String: Data] = [:]

    override init() {
        self.settings = TTSSettings()
        super.init()

        // Forward any change in settings to trigger our own UI update
        settingsCancellable = settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        synthesizer.delegate = self
        configureAudioSession()
        configureServices()
    }

    private func configureServices() {
        groqService = GroqTTSService()
        openAIService = OpenAITTSService()
        print("[TTS] ✅ Groq + OpenAI TTS via proxy configured")
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

        let provider = settings.provider
        let voiceId = settings.currentVoiceId
        let cacheKey = "\(provider.rawValue)_\(voiceId)_\(text.lowercased())"

        print("[TTS] 🎯 Provider: \(provider.rawValue), Voice: \(voiceId), Text: \(text)")

        Analytics.logEvent("item_spoken", parameters: [
            "provider": provider.rawValue,
            "voice": voiceId,
            "text_length": text.count,
            "cached": audioCache[cacheKey] != nil ? 1 : 0
        ])

        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentlySpeakingId = itemId
        }

        // Check cache first
        if let cachedAudio = audioCache[cacheKey] {
            print("[TTS] 📦 Using cached audio")
            playAudioData(cachedAudio)
            return
        }

        switch provider {
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
        guard let service = groqService else { return }
        let voice = settings.groqVoice
        Task {
            do {
                print("[TTS] 🔊 Calling Groq API — voice: \(voice)")
                let audioData = try await service.synthesizeSpeech(text: text, voice: voice)
                print("[TTS] ✅ Groq returned \(audioData.count) bytes")
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] ❌ Groq TTS failed: \(error)")
                let msg = error.localizedDescription
                Analytics.logEvent("tts_fallback_to_computer", parameters: [
                    "provider": "groq", "reason": String(msg.prefix(100))
                ])
                await MainActor.run {
                    self.lastError = "Groq: \(msg)"
                    self.speakNatively(text: text)
                }
            }
        }
    }

    private func speakWithOpenAI(text: String, cacheKey: String) {
        guard let service = openAIService else { return }
        let voice = settings.openAIVoice
        Task {
            do {
                print("[TTS] 🔊 Calling OpenAI API — voice: \(voice)")
                let audioData = try await service.synthesizeSpeech(text: text, voice: voice, speed: 1.0)
                print("[TTS] ✅ OpenAI returned \(audioData.count) bytes")
                self.audioCache[cacheKey] = audioData
                await MainActor.run { self.playAudioData(audioData) }
            } catch {
                print("[TTS] ❌ OpenAI TTS failed: \(error)")
                let msg = error.localizedDescription
                if msg.localizedCaseInsensitiveContains("quota") ||
                   msg.contains("429") {
                    Analytics.logEvent("openai_tts_quota_exceeded", parameters: [
                        "voice": voice, "text_length": text.count
                    ])
                }
                Analytics.logEvent("tts_fallback_to_computer", parameters: [
                    "provider": "openai", "reason": String(msg.prefix(100))
                ])
                await MainActor.run {
                    self.lastError = "OpenAI: \(msg)"
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
            print("[TTS] ▶️ Playing audio (\(data.count) bytes)")
        } catch {
            print("[TTS] ❌ Audio playback failed: \(error)")
            DispatchQueue.main.async {
                self.lastError = "Playback error: \(error.localizedDescription)"
                self.isSpeaking = false
                self.currentlySpeakingId = nil
            }
        }
    }

    private func speakNatively(text: String) {
        print("[TTS] 🔊 Using system voice")
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
