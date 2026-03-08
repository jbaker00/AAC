import Foundation

struct AACItem: Identifiable, Hashable, Codable {
    let id: String
    let label: String
    let speechText: String
    let backgroundColorHex: String
    let borderColorHex: String
    /// Filename of user-imported image stored in app Documents, or nil for built-in items
    var customImageName: String?
    /// Whether this is a built-in item with a SwiftUI-drawn illustration
    var isBuiltIn: Bool

    init(id: String = UUID().uuidString, label: String, speechText: String? = nil,
         backgroundColorHex: String = "#D9EDFF", borderColorHex: String = "#0059B3",
         customImageName: String? = nil, isBuiltIn: Bool = false) {
        self.id = id
        self.label = label
        self.speechText = speechText ?? label
        self.backgroundColorHex = backgroundColorHex
        self.borderColorHex = borderColorHex
        self.customImageName = customImageName
        self.isBuiltIn = isBuiltIn
    }
}

import SwiftUI

// MARK: - Color Helpers
extension AACItem {
    var backgroundColor: Color {
        Color(hex: backgroundColorHex) ?? .white
    }

    var borderColor: Color {
        Color(hex: borderColorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let r = Int((components[0]) * 255)
        let g = Int((components.count > 1 ? components[1] : components[0]) * 255)
        let b = Int((components.count > 2 ? components[2] : components[0]) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Default Items
extension AACItem {
    static let defaultItems: [AACItem] = [
        AACItem(
            id: "milk",
            label: "Milk",
            speechText: "Milk",
            backgroundColorHex: "#D9EDFF",
            borderColorHex: "#0059B3",
            isBuiltIn: true
        ),
        AACItem(
            id: "time-to-go",
            label: "Time to Go",
            speechText: "Time to Go",
            backgroundColorHex: "#FFF2D9",
            borderColorHex: "#CC8000",
            isBuiltIn: true
        ),
        AACItem(
            id: "brush-teeth",
            label: "Brush Teeth",
            speechText: "Brush Teeth",
            backgroundColorHex: "#D9FFE6",
            borderColorHex: "#009966",
            isBuiltIn: true
        ),
        AACItem(
            id: "potty",
            label: "Potty",
            speechText: "Potty",
            backgroundColorHex: "#F2E6FF",
            borderColorHex: "#804DB3",
            isBuiltIn: true
        )
    ]
}

