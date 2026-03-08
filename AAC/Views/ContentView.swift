import SwiftUI

struct ContentView: View {
    @StateObject private var ttsManager = TextToSpeechManager()
    @StateObject private var itemStore = ItemStore()
    @State private var showingAddItem = false
    @State private var showingSettings = false
    @State private var isEditing = false

    // Image cache for custom items
    @State private var imageCache: [String: UIImage] = [:]

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(itemStore.items) { item in
                        ZStack(alignment: .topTrailing) {
                            AACButtonView(
                                item: item,
                                isSpeaking: ttsManager.currentlySpeakingId == item.id,
                                customImage: imageCache[item.id]
                            ) {
                                if !isEditing {
                                    ttsManager.speak(text: item.speechText, itemId: item.id)
                                }
                            }
                            .frame(minHeight: 280)

                            // Delete badge in edit mode
                            if isEditing {
                                Button {
                                    withAnimation {
                                        itemStore.deleteItem(id: item.id)
                                        imageCache.removeValue(forKey: item.id)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.red)
                                        .background(Circle().fill(.white).padding(2))
                                }
                                .offset(x: -8, y: 8)
                            }
                        }
                    }

                    // Add button tile
                    if !isEditing {
                        Button {
                            showingAddItem = true
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.accentColor)
                                Text("Add New")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(.accentColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(minHeight: 280)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [12]))
                                    .foregroundColor(.accentColor.opacity(0.4))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(32)
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
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
            .sheet(isPresented: $showingSettings) {
                SettingsView(ttsManager: ttsManager)
            }
            .onAppear {
                refreshImageCache()
            }
        }
    }

    private func refreshImageCache() {
        for item in itemStore.items {
            if item.customImageName != nil, imageCache[item.id] == nil {
                imageCache[item.id] = itemStore.loadImageForItem(item)
            }
        }
    }
}

#Preview {
    ContentView()
}
