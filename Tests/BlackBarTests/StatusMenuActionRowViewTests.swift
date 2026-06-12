import AppKit
import SwiftUI
import Testing
@testable import BlackBar

@Suite("Status menu action row")
struct StatusMenuActionRowViewTests {
    @Test("operational status stays compact")
    @MainActor
    func operationalStatusStaysCompact() {
        let operationalHeight = Self.height(status: Self.status())
        let incidentHeight = Self.height(status: Self.status(incidentName: "Storage cluster degraded"))

        #expect(incidentHeight > operationalHeight)
    }

    @Test("incident notice grows to four lines and then caps its height")
    @MainActor
    func incidentNoticeHeightCapsAtFourLines() {
        let oneLineHeight = Self.height(status: Self.status(incidentName: "Line one"))
        let fourLineHeight = Self.height(status: Self.status(incidentName: "Line one\nLine two\nLine three\nLine four"))
        let sixLineHeight = Self.height(
            status: Self.status(incidentName: "Line one\nLine two\nLine three\nLine four\nLine five\nLine six")
        )

        #expect(fourLineHeight > oneLineHeight)
        #expect(abs(sixLineHeight - fourLineHeight) <= 1)
    }

    private static func status(incidentName: String? = nil) -> BlacksmithStatus {
        BlacksmithStatus(
            pageStatus: "UP",
            incidents: incidentName.map { [StatusEvent(id: "incident", name: $0, status: "investigating")] } ?? [],
            maintenances: []
        )
    }

    @MainActor
    private static func height(status: BlacksmithStatus) -> CGFloat {
        let controller = NSHostingController(rootView: StatusMenuActionRowView(status: status) {})

        return controller.sizeThatFits(in: NSSize(width: 360, height: 720)).height
    }
}
