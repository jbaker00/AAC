import SwiftUI
import PhotosUI

struct EditItemView: View {
    @ObservedObject var itemStore: ItemStore
    let item: AACItem
    let existingImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var label: String
    @State private var speechText: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var backgroundColor: Color
    @State private var borderColor: Color

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

    init(itemStore: ItemStore, item: AACItem, existingImage: UIImage?) {
        self.itemStore = itemStore
        self.item = item
        self.existingImage = existingImage
        _label = State(initialValue: item.label)
        _speechText = State(initialValue: item.speechText)
        _selectedImage = State(initialValue: existingImage)
        _backgroundColor = State(initialValue: item.backgroundColor)
        _borderColor = State(initialValue: item.borderColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Image
                Section("Picture") {
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
                        } else if item.isBuiltIn {
                            Text("Built-in illustration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(height: 100)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 200, height: 200)
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(item.isBuiltIn && selectedImage == nil ? "Replace with Photo" : "Change Picture")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.title3)
                    }
                    .onChange(of: selectedPhoto) { newValue in
                        loadImage(from: newValue)
                    }
                }

                // MARK: - Text
                Section("Words") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Button Label")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g. Water", text: $label)
                            .font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Words to Speak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Leave empty to use label", text: $speechText)
                            .font(.title3)
                    }
                }

                // MARK: - Color
                Section("Button Color") {
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
                }
            }
            .navigationTitle("Edit Button")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .font(.headline)
                    .disabled(label.isEmpty)
                }
            }
        }
    }

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

    private func saveItem() {
        // If user picked a new photo (even for built-in items), convert to custom
        let hasNewImage = (selectedImage != nil && selectedImage != existingImage)
        let shouldConvertToCustom = item.isBuiltIn && hasNewImage
        
        let updatedItem = AACItem(
            id: item.id,
            label: label,
            speechText: speechText.isEmpty ? label : speechText,
            backgroundColorHex: backgroundColor.hexString,
            borderColorHex: borderColor.hexString,
            customImageName: shouldConvertToCustom ? "\(item.id).jpg" : item.customImageName,
            isBuiltIn: shouldConvertToCustom ? false : item.isBuiltIn
        )

        let newImage = hasNewImage ? selectedImage : nil
        itemStore.updateItem(updatedItem, newImage: newImage)
        dismiss()
    }
}
