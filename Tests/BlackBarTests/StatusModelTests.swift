import Testing
@testable import BlackBar

@Suite("Blacksmith status model")
struct StatusModelTests {
    @Test("operational status stays compact")
    func operationalStatusStaysCompact() {
        let status = BlacksmithStatus(pageStatus: "UP", incidents: [], maintenances: [])

        #expect(status.hasActiveNotice == false)
        #expect(status.badgeLabel == "UP")
    }

    @Test("incidents take badge priority")
    func incidentsTakeBadgePriority() {
        let status = BlacksmithStatus(
            pageStatus: "UP",
            incidents: [StatusEvent(id: "i1", name: "Queue delay", status: "investigating")],
            maintenances: [StatusEvent(id: "m1", name: "Maintenance", status: "scheduled")]
        )

        #expect(status.hasActiveNotice)
        #expect(status.badgeLabel == "INCIDENT")
        #expect(status.noticeKind == "Incident")
        #expect(status.noticeTitle == "Queue delay")
    }
}
