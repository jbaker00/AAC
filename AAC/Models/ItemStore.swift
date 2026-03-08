import Foundation
import SwiftUI
import UIKit

/// Manages persistence of AAC items and their images
class ItemStore: ObservableObject {
    @Published var items: [AACItem] = []

    private let itemsFileName = "aac_items.json"
    private let imageDirectoryName = "AACImages"

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var itemsFileURL: URL {
        documentsDirectory.appendingPathComponent(itemsFileName)
    }

    private var imageDirectory: URL {
        documentsDirectory.appendingPathComponent(imageDirectoryName)
    }

    init() {
        createImageDirectoryIfNeeded()
        loadItems()
    }

    // MARK: - Public API

    func addItem(_ item: AACItem, image: UIImage?) {
        var newItem = item
        if let image = image {
            let imageName = "\(item.id).png"
            saveImage(image, named: imageName)
            newItem.customImageName = imageName
        }
        items.append(newItem)
        saveItems()
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            if let imageName = item.customImageName {
                deleteImage(named: imageName)
            }
        }
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func deleteItem(id: String) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            if let imageName = items[index].customImageName {
                deleteImage(named: imageName)
            }
            items.remove(at: index)
            saveItems()
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }

    func loadImageForItem(_ item: AACItem) -> UIImage? {
        guard let imageName = item.customImageName else { return nil }
        let imageURL = imageDirectory.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }

    func resetToDefaults() {
        // Remove all custom images
        for item in items {
            if let imageName = item.customImageName {
                deleteImage(named: imageName)
            }
        }
        items = AACItem.defaultItems
        saveItems()
    }

    // MARK: - Private

    private func createImageDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: imageDirectory,
                                                   withIntermediateDirectories: true)
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: itemsFileURL)
        } catch {
            print("[ItemStore] Failed to save items: \(error)")
        }
    }

    private func loadItems() {
        guard FileManager.default.fileExists(atPath: itemsFileURL.path) else {
            // First launch - use defaults
            items = AACItem.defaultItems
            saveItems()
            return
        }

        do {
            let data = try Data(contentsOf: itemsFileURL)
            items = try JSONDecoder().decode([AACItem].self, from: data)
        } catch {
            print("[ItemStore] Failed to load items, using defaults: \(error)")
            items = AACItem.defaultItems
        }
    }

    private func saveImage(_ image: UIImage, named name: String) {
        let url = imageDirectory.appendingPathComponent(name)
        // Save as PNG for best quality
        if let data = image.pngData() {
            try? data.write(to: url)
        } else if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: url)
        }
    }

    private func deleteImage(named name: String) {
        let url = imageDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
    }
}
