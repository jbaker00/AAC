import SwiftUI

struct SettingsView: View {
    @ObservedObject var ttsManager: TextToSpeechManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Voice Provider
                Section {
                    Picker("Voice Provider", selection: $ttsManager.settings.provider) {
                        ForEach(TTSProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: ttsManager.settings.provider) { _ in
                        ttsManager.clearCache()
                        ttsManager.settings.save()
                    }
                } header: {
                    Label("Voice Provider", systemImage: "waveform")
                        .font(.headline)
                } footer: {
                    switch ttsManager.settings.provider {
                    case .groq:
                        Text("Groq provides high-quality AI voices powered by PlayAI.")
                    case .openai:
                        Text("OpenAI provides natural-sounding AI voices.")
                    case .system:
                        Text("Uses the built-in iOS speech synthesizer. Works offline.")
                    }
                }

                // MARK: - Voice Selection
                Section {
                    voicePickerForCurrentProvider
                } header: {
                    Label("Voice", systemImage: "person.wave.2")
                        .font(.headline)
                }

                // MARK: - Speech Rate (System voice only)
                if ttsManager.settings.provider == .system {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Rate")
                                Spacer()
                                Text(rateLabel)
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $ttsManager.settings.speechRate, in: 0.1...0.7, step: 0.05)
                                .onChange(of: ttsManager.settings.speechRate) { _ in
                                    ttsManager.settings.save()
                                }
                        }
                    } header: {
                        Label("Speed", systemImage: "gauge.with.needle")
                            .font(.headline)
                    }
                }

                // MARK: - Preview
                Section {
                    Button {
                        ttsManager.speak(text: "Hello, I would like some milk please.")
                    } label: {
                        HStack {
                            Image(systemName: ttsManager.isSpeaking ? "speaker.wave.3.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text(ttsManager.isSpeaking ? "Speaking..." : "Preview Voice")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                    .disabled(ttsManager.isSpeaking)

                    if ttsManager.isSpeaking {
                        Button {
                            ttsManager.stop()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                Text("Stop")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Label("Preview", systemImage: "speaker.wave.2.bubble")
                        .font(.headline)
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        ttsManager.settings.save()
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }

    // MARK: - Voice Picker

    @ViewBuilder
    private var voicePickerForCurrentProvider: some View {
        let voices = ttsManager.settings.provider.voices

        switch ttsManager.settings.provider {
        case .groq:
            Picker("Voice", selection: $ttsManager.settings.groqVoice) {
                ForEach(voices, id: \.id) { voice in
                    Text(voice.name).tag(voice.id)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: ttsManager.settings.groqVoice) { _ in
                ttsManager.clearCache()
                ttsManager.settings.save()
            }

        case .openai:
            Picker("Voice", selection: $ttsManager.settings.openAIVoice) {
                ForEach(voices, id: \.id) { voice in
                    Text(voice.name).tag(voice.id)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: ttsManager.settings.openAIVoice) { _ in
                ttsManager.clearCache()
                ttsManager.settings.save()
            }

        case .system:
            Picker("Voice", selection: $ttsManager.settings.systemVoice) {
                ForEach(voices, id: \.id) { voice in
                    Text(voice.name).tag(voice.id)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: ttsManager.settings.systemVoice) { _ in
                ttsManager.settings.save()
            }
        }
    }

    private var rateLabel: String {
        let rate = ttsManager.settings.speechRate
        if rate < 0.25 { return "Slow" }
        if rate < 0.45 { return "Normal" }
        return "Fast"
    }
}

#Preview {
    SettingsView(ttsManager: TextToSpeechManager())
}
