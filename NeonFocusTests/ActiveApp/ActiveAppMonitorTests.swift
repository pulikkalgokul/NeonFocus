import AppKit
import Testing

@MainActor
@Suite("Active App Monitor")
struct ActiveAppMonitorTests {
    @Test
    func reportsSelectedTerminalAppAsActive() {
        let sut = ActiveAppMonitor(
            trackedTerminalApps: [.appleTerminal, .ghostty]
        )
        var received: (active: Bool, pid: pid_t?)?
        sut.onChange = { received = ($0, $1) }

        sut.debugReport(
            bundleID: NeonFocusSettings.TerminalApp.ghostty.rawValue,
            pid: 42
        )

        #expect(received?.active == true)
        #expect(received?.pid == 42)
    }

    @Test
    func reportsUnselectedTerminalAppAsInactive() {
        let sut = ActiveAppMonitor(
            trackedTerminalApps: [.appleTerminal]
        )
        var received: (active: Bool, pid: pid_t?)?
        sut.onChange = { received = ($0, $1) }

        sut.debugReport(
            bundleID: NeonFocusSettings.TerminalApp.ghostty.rawValue,
            pid: 42
        )

        #expect(received?.active == false)
        #expect(received?.pid == nil)
    }
}
