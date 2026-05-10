import Foundation
import Testing

@Suite("NeonFocus Settings Store")
struct NeonFocusSettingsStoreTests {
    @Test
    func loadReturnsDefaultsWhenUnset() {
        let defaults = makeDefaults()
        let store = NeonFocusSettingsStore(defaults: defaults)

        #expect(store.load() == .default)
        #expect(store.load().trackedTerminalApps == [.appleTerminal])
    }

    @Test
    func savePersistsOverlaySettings() {
        let defaults = makeDefaults()
        let store = NeonFocusSettingsStore(defaults: defaults)
        let settings = NeonFocusSettings(
            color: .electricCyan,
            thickness: .bold,
            pulseSpeed: .fast,
            glowIntensity: .vivid,
            vibration: .off,
            trackedTerminalApps: [.appleTerminal, .ghostty, .warp]
        )

        store.save(settings)

        #expect(store.load() == settings)
    }

    @Test
    func loadIgnoresUnknownTerminalBundleIDs() {
        let defaults = makeDefaults()
        defaults.set(
            [
                NeonFocusSettings.TerminalApp.appleTerminal.rawValue,
                "com.example.NotATerminal",
                NeonFocusSettings.TerminalApp.iterm2.rawValue,
            ],
            forKey: "NeonFocus.settings.trackedTerminalApps"
        )
        let store = NeonFocusSettingsStore(defaults: defaults)

        #expect(store.load().trackedTerminalApps == [.appleTerminal, .iterm2])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NeonFocusSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
