import Foundation
import Testing

@Suite("NeonFocus Settings Store")
struct NeonFocusSettingsStoreTests {
    @Test
    func loadReturnsDefaultsWhenUnset() {
        let defaults = makeDefaults()
        let store = NeonFocusSettingsStore(defaults: defaults)

        #expect(store.load() == .default)
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
            vibration: .off
        )

        store.save(settings)

        #expect(store.load() == settings)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NeonFocusSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
