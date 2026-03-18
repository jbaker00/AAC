import SwiftUI

struct SettingsView: View {
    @ObservedObject var ttsManager: TextToSpeechManager
    @ObservedObject var settings: TTSSettings
    @Environment(\.dismiss) private var dismiss

    init(ttsManager: TextToSpeechManager) {
        self.ttsManager = ttsManager
        self.settings = ttsManager.settings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    // MARK: - Current Voice Summary
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Currently Using")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(settings.provider.displayName)
                                    .font(.title2.bold())
                                Text(settings.currentVoiceDisplayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: providerIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 8)
                    }

                    // MARK: - Voice Provider
                    Section("Voice Provider") {
                        ForEach(TTSProvider.allCases, id: \.self) { provider in
                            Button {
                                settings.provider = provider
                                ttsManager.clearCache()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(provider.displayName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(providerDescription(provider))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if settings.provider == provider {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.title2)
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // MARK: - Voice Selection
                    Section("Choose Voice for \(settings.provider.displayName)") {
                        let voices = settings.provider.voices
                        let selectedId = settings.currentVoiceId

                        ForEach(voices, id: \.id) { voice in
                            Button {
                                setVoice(voice.id)
                                ttsManager.clearCache()
                            } label: {
                                HStack {
                                    Text(voice.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if voice.id == selectedId {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // MARK: - Speech Rate
                    if settings.provider == .system {
                        Section("Speech Rate") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tortoise")
                                    Slider(value: $settings.speechRate, in: 0.1...0.7, step: 0.05)
                                    Image(systemName: "hare")
                                }
                                Text(rateLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }

                    // MARK: - Preview
                    Section("Test Voice") {
                        Button {
                            ttsManager.speak(text: "Hello, I would like some milk please.")
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "play.circle.fill")
                                    .font(.title)
                                Text(ttsManager.isSpeaking ? "Speaking..." : "Preview Voice")
                                    .font(.title3.bold())
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .foregroundColor(ttsManager.isSpeaking ? .secondary : .accentColor)
                        }
                        .disabled(ttsManager.isSpeaking)

                        if ttsManager.isSpeaking {
                            Button {
                                ttsManager.stop()
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title)
                                    Text("Stop")
                                        .font(.title3.bold())
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .foregroundColor(.red)
                            }
                        }

                        if let error = ttsManager.lastError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                // Banner ad at the bottom
                AdBannerContainer()
                    .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Helpers

    private var providerIcon: String {
        switch settings.provider {
        case .groq: return "waveform.circle.fill"
        case .openai: return "brain.head.profile"
        case .system: return "ipad.and.arrow.forward"
        }
    }

    private func providerDescription(_ provider: TTSProvider) -> String {
        switch provider {
        case .groq: return "High-quality AI voices by Orpheus (6 voices)"
        case .openai: return "Natural-sounding OpenAI voices (6 voices)"
        case .system: return "Built-in iOS voices (works offline)"
        }
    }

    private func setVoice(_ id: String) {
        switch settings.provider {
        case .groq: settings.groqVoice = id
        case .openai: settings.openAIVoice = id
        case .system: settings.systemVoice = id
        }
    }

    private var rateLabel: String {
        let rate = settings.speechRate
        if rate < 0.25 { return "Slow" }
        if rate < 0.45 { return "Normal" }
        return "Fast"
    }
}

#Preview {
    SettingsView(ttsManager: TextToSpeechManager())
}
