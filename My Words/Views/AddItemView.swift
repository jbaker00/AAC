import SwiftUI
import PhotosUI

struct AddItemView: View {
    @ObservedObject var itemStore: ItemStore
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var speechText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var backgroundColor = Color(red: 0.9, green: 0.95, blue: 1.0)
    @State private var borderColor = Color.blue

    private let presetColors: [(name: String, bg: Color, border: Color)] = [
        ("Blue", Color(hex: "#D9EDFF")!, Color(hex: "#0059B3")!),
        ("Orange", Color(hex: "#FFF2D9")!, Color(hex: "#CC8000")!),
        ("Green", Color(hex: "#D9FFE6")!, Color(hex: "#009966")!),
        ("Purple", Color(hex: "#F2E6FF")!, Color(hex: "#804DB3")!),
        ("Red", Color(hex: "#FFE0E0")!, Color(hex: "#CC3333")!),
        ("Teal", Color(hex: "#D9FFF5")!, Color(hex: "#008080")!),
        ("Pink", Color(hex: "#FFE6F2")!, Color(hex: "#CC3399")!),
        ("Yellow", Color(hex: "#FFFBD9")!, Color(hex: "#B38F00")!)
    ]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Image
                Section {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(borderColor, lineWidth: 3)
                                )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 200, height: 200)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("Choose a Picture")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(selectedImage == nil ? "Select from Photos" : "Change Picture")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.title3)
                    }
                    .onChange(of: selectedPhoto) { newValue in
                        loadImage(from: newValue)
                    }
                } header: {
                    Label("Picture", systemImage: "photo")
                        .font(.headline)
                } footer: {
                    Text("Choose a clear, recognizable photo. JPEG and PNG work best.")
                }

                // MARK: - Text
                Section {
                    TextField("Button Label (e.g. Water)", text: $label)
                        .font(.title3)
                        .autocorrectionDisabled()

                    TextField("Words to Speak (optional)", text: $speechText)
                        .font(.title3)
                        .autocorrectionDisabled()
                } header: {
                    Label("Words", systemImage: "text.bubble")
                        .font(.headline)
                } footer: {
                    Text("If 'Words to Speak' is empty, the button label will be spoken instead.")
                }

                // MARK: - Color
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(presetColors, id: \.name) { preset in
                            Button {
                                backgroundColor = preset.bg
                                borderColor = preset.border
                            } label: {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(preset.bg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(preset.border, lineWidth: 3)
                                    )
                                    .frame(height: 50)
                                    .overlay(
                                        Group {
                                            if backgroundColor == preset.bg && borderColor == preset.border {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(preset.border)
                                                    .font(.title2)
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Button Color", systemImage: "paintpalette")
                        .font(.headline)
                }

                // MARK: - Preview
                if !label.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            previewButton
                            Spacer()
                        }
                    } header: {
                        Label("Preview", systemImage: "eye")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Add New Button")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .font(.headline)
                    .disabled(label.isEmpty || selectedImage == nil)
                }
            }
        }
    }

    // MARK: - Preview Button
    private var previewButton: some View {
        VStack(spacing: 8) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .padding()
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 3)
        )
    }

    // MARK: - Actions

    private func loadImage(from photoItem: PhotosPickerItem?) {
        guard let photoItem else { return }
        photoItem.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data = data,
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }

    private func addItem() {
        let newItem = AACItem(
            label: label,
            speechText: speechText.isEmpty ? label : speechText,
            backgroundColorHex: backgroundColor.hexString,
            borderColorHex: borderColor.hexString,
            isBuiltIn: false
        )
        itemStore.addItem(newItem, image: selectedImage)
        dismiss()
    }
}

#Preview {
    AddItemView(itemStore: ItemStore())
}
