import SwiftUI

/// A large, tappable AAC button with an image and label
struct AACButtonView: View {
    let item: AACItem
    let isSpeaking: Bool
    let customImage: UIImage?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Image area
                itemImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Label
                Text(item.label)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(item.backgroundColor)
                    .shadow(color: item.borderColor.opacity(0.3), radius: isSpeaking ? 12 : 6, x: 0, y: isSpeaking ? 6 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(item.borderColor, lineWidth: isSpeaking ? 5 : 3)
            )
            .scaleEffect(isSpeaking ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSpeaking)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.speechText)
        .accessibilityHint("Double tap to speak \(item.speechText)")
    }

    @ViewBuilder
    private var itemImage: some View {
        if let uiImage = customImage {
            // User-provided image
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if item.isBuiltIn {
            // Built-in SwiftUI illustration
            builtInImage
        } else {
            // Fallback placeholder
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray.opacity(0.5))
                .padding(20)
        }
    }

    @ViewBuilder
    private var builtInImage: some View {
        switch item.id {
        case "milk":
            MilkCartonView()
        case "time-to-go":
            StrollerView()
        case "brush-teeth":
            ElectricToothbrushView()
        case "potty":
            PottyView()
        default:
            Image(systemName: "questionmark.circle")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    AACButtonView(
        item: AACItem.defaultItems[0],
        isSpeaking: false,
        customImage: nil,
        action: {}
    )
    .frame(width: 250, height: 300)
    .padding()
}
