import SwiftUI

struct ContentView: View {
    @StateObject private var ttsManager = TextToSpeechManager()
    @StateObject private var itemStore = ItemStore()
    @State private var showingAddItem = false
    @State private var showingSettings = false
    @State private var isEditing = false
    @State private var editingItem: AACItem?

    // Image cache for custom items
    @State private var imageCache: [String: UIImage] = [:]

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        // 2 columns on both iPhone and iPad
        return Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    }

    var body: some View {
        VStack(spacing: 0) {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    // Current voice indicator
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                        Text("Voice: \(ttsManager.settings.provider.displayName) — \(ttsManager.settings.currentVoiceDisplayName)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                    if let error = ttsManager.lastError {
                        // Log errors to console only, don't show on AAC screen
                        let _ = print("[TTS UI] \(error)")
                    }

                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(itemStore.items) { item in
                            ZStack(alignment: .topTrailing) {
                                AACButtonView(
                                    item: item,
                                    isSpeaking: ttsManager.currentlySpeakingId == item.id,
                                    customImage: imageCache[item.id]
                                ) {
                                    if isEditing {
                                        editingItem = item
                                    } else {
                                        ttsManager.speak(text: item.speechText, itemId: item.id)
                                    }
                                }
                                .frame(minHeight: sizeClass == .compact ? 180 : 280)

                                // Edit/delete overlay in edit mode
                                if isEditing {
                                    VStack(spacing: 8) {
                                        Button {
                                            withAnimation {
                                                itemStore.deleteItem(id: item.id)
                                                imageCache.removeValue(forKey: item.id)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(.white).padding(3))
                                        }

                                        Button {
                                            editingItem = item
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.blue)
                                                .background(Circle().fill(.white).padding(3))
                                        }
                                    }
                                    .offset(x: -8, y: 8)
                                }
                            }
                        }
                    }
                    .padding(sizeClass == .compact ? 16 : 32)
                    .padding(.bottom, 80)
                }
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))

                // Floating Add button — always visible
                if !isEditing {
                    Button {
                        showingAddItem = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                            Text("Add Button")
                                .font(.headline)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(color: .accentColor.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("My Words")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { isEditing.toggle() }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.headline)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if ttsManager.isSpeaking {
                        Button {
                            ttsManager.stop()
                        } label: {
                            Image(systemName: "speaker.slash.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Stop speaking")
                    }

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Voice Settings")
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(itemStore: itemStore)
                    .onDisappear { refreshImageCache() }
            }
            .sheet(item: $editingItem) { item in
                EditItemView(
                    itemStore: itemStore,
                    item: item,
                    existingImage: imageCache[item.id]
                )
                .onDisappear { refreshImageCache() }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(ttsManager: ttsManager)
            }
            .onAppear {
                refreshImageCache()
            }
        }
        BannerAdView()
            .frame(height: BannerAdView.height)
            .frame(maxWidth: .infinity)
        } // VStack
    }

    private func refreshImageCache() {
        for item in itemStore.items {
            if item.customImageName != nil {
                imageCache[item.id] = itemStore.loadImageForItem(item)
            }
        }
    }
}

#Preview {
    ContentView()
}
