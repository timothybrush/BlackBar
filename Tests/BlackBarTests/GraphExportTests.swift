import AppKit
import SwiftUI
import Testing
@testable import BlackBar

@Suite("Graph export")
struct GraphExportTests {
    @Test("SwiftUI export render uses requested dimensions")
    @MainActor
    func swiftUIExportRenderUsesRequestedDimensions() throws {
        let image = try GraphExport.image(
            from: Text("BlackBar")
                .padding()
                .background(Color(nsColor: .windowBackgroundColor)),
            size: CGSize(width: 240, height: 120),
            scale: 1
        )

        #expect(image.size == NSSize(width: 240, height: 120))
        #expect(image.isTemplate == false)
    }

    @Test("saved graph is a readable PNG")
    @MainActor
    func savedGraphIsReadablePNG() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let image = try Self.makeImage()
        let url = try GraphExport.saveToDownloads(
            image,
            filenamePrefix: "BlackBar-test",
            downloadsDirectory: directory,
            date: Date(timeIntervalSince1970: 0)
        )

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.lastPathComponent == "BlackBar-test-1970-01-01T00-00-00Z.png")

        let data = try Data(contentsOf: url)
        #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        #expect(NSImage(data: data)?.size == image.size)
    }

    @Test("clipboard write exposes a readable image")
    @MainActor
    func clipboardWriteExposesReadableImage() throws {
        let pasteboard = NSPasteboard(name: .init("BlackBarGraphExportTests-\(UUID().uuidString)"))
        let image = try Self.makeImage()

        try GraphExport.writeToPasteboard(image, pasteboard: pasteboard)

        #expect(pasteboard.canReadObject(forClasses: [NSImage.self], options: nil))
        let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage]
        #expect(images?.first?.size == image.size)
    }

    @MainActor
    private static func makeImage() throws -> NSImage {
        try GraphExport.image(
            from: VStack {
                Text("BlackBar")
                Rectangle().fill(Color.cyan).frame(width: 80, height: 24)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor)),
            size: CGSize(width: 160, height: 90),
            scale: 1
        )
    }
}
