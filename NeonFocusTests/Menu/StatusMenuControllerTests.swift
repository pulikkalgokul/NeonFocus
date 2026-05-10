import AppKit
import Testing

@MainActor
@Suite("Status Menu Settings")
struct StatusMenuControllerTests {
    @Test
    func colorMenuUpdatesSettingsAndCheckmark() throws {
        let sut = StatusMenuController()
        defer { sut.uninstall() }
        var receivedSettings: NeonFocusSettings?
        sut.onSettingsChanged = { receivedSettings = $0 }
        sut.debugInstallMenu(enabled: true, settings: .default)

        let cyanItem = try #require(
            sut.debugMenu?
                .item(withTitle: "Color")?
                .submenu?
                .item(withTitle: NeonFocusSettings.Color.electricCyan.title)
        )

        sut.debugPerformAction(for: cyanItem)

        #expect(receivedSettings?.color == .electricCyan)
        #expect(cyanItem.state == .on)
    }

    @Test
    func vibrationMenuCanDisableFocusBurst() throws {
        let sut = StatusMenuController()
        defer { sut.uninstall() }
        var receivedSettings: NeonFocusSettings?
        sut.onSettingsChanged = { receivedSettings = $0 }
        sut.debugInstallMenu(enabled: true, settings: .default)

        let offItem = try #require(
            sut.debugMenu?
                .item(withTitle: "Vibration")?
                .submenu?
                .item(withTitle: NeonFocusSettings.Vibration.off.title)
        )

        sut.debugPerformAction(for: offItem)

        #expect(receivedSettings?.vibration == .off)
        #expect(offItem.state == .on)
    }

    @Test
    func glowMenuUpdatesSettingsAndCheckmark() throws {
        let sut = StatusMenuController()
        defer { sut.uninstall() }
        var receivedSettings: NeonFocusSettings?
        sut.onSettingsChanged = { receivedSettings = $0 }
        sut.debugInstallMenu(enabled: true, settings: .default)

        let vividItem = try #require(
            sut.debugMenu?
                .item(withTitle: "Glow")?
                .submenu?
                .item(withTitle: NeonFocusSettings.GlowIntensity.vivid.title)
        )

        sut.debugPerformAction(for: vividItem)

        #expect(receivedSettings?.glowIntensity == .vivid)
        #expect(vividItem.state == .on)
    }
}
