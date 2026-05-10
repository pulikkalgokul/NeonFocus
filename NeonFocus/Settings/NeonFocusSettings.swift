import CoreGraphics
import Foundation

struct NeonFocusSettings: Equatable {
    enum Color: String, CaseIterable {
        case hotPink
        case electricCyan
        case acidGreen

        var title: String {
            switch self {
            case .hotPink: "Hot Pink"
            case .electricCyan: "Electric Cyan"
            case .acidGreen: "Acid Green"
            }
        }

        var cgColor: CGColor {
            makeColor(alpha: 1)
        }

        func edgeFadeStrokeColors(for intensity: GlowIntensity, count: Int) -> [CGColor] {
            guard count > 0 else { return [] }

            let maxIndex = max(count - 1, 1)
            return (0..<count).map { index in
                let progress = CGFloat(index) / CGFloat(maxIndex)
                let fade = max(0, 1 - progress)
                let alpha = intensity.coreAlpha * fade * fade * 0.85
                let blend = intensity.highlightBlend * (0.3 + fade * 0.2)
                return blended(toward: (red: 1, green: 1, blue: 1), amount: blend, alpha: alpha)
            }
        }

        private var components: (red: CGFloat, green: CGFloat, blue: CGFloat) {
            switch self {
            case .hotPink:
                (red: 1.0, green: 0x3D / 255.0, blue: 0xF4 / 255.0)
            case .electricCyan:
                (red: 0x23 / 255.0, green: 0xC4 / 255.0, blue: 0xE8 / 255.0)
            case .acidGreen:
                (red: 0xA3 / 255.0, green: 0xFF / 255.0, blue: 0x12 / 255.0)
            }
        }

        private func makeColor(alpha: CGFloat) -> CGColor {
            let components = components
            return CGColor(
                red: components.red,
                green: components.green,
                blue: components.blue,
                alpha: alpha
            )
        }

        private func blended(
            toward target: (red: CGFloat, green: CGFloat, blue: CGFloat),
            amount: CGFloat,
            alpha: CGFloat
        ) -> CGColor {
            let components = components
            return CGColor(
                red: components.red + (target.red - components.red) * amount,
                green: components.green + (target.green - components.green) * amount,
                blue: components.blue + (target.blue - components.blue) * amount,
                alpha: alpha
            )
        }
    }

    enum Thickness: String, CaseIterable {
        case slim
        case regular
        case bold

        var title: String {
            switch self {
            case .slim: "Slim"
            case .regular: "Regular"
            case .bold: "Bold"
            }
        }

        var baseLineWidth: CGFloat {
            switch self {
            case .slim: 1.5
            case .regular: 2
            case .bold: 3
            }
        }

        var peakLineWidth: CGFloat {
            switch self {
            case .slim: 2.5
            case .regular: 4
            case .bold: 5
            }
        }
    }

    enum PulseSpeed: String, CaseIterable {
        case slow
        case normal
        case fast

        var title: String {
            switch self {
            case .slow: "Slow"
            case .normal: "Normal"
            case .fast: "Fast"
            }
        }

        var duration: CFTimeInterval {
            switch self {
            case .slow: 2.4
            case .normal: 1.6
            case .fast: 0.9
            }
        }
    }

    enum GlowIntensity: String, CaseIterable {
        case subtle
        case bright
        case vivid

        var title: String {
            switch self {
            case .subtle: "Subtle"
            case .bright: "Bright"
            case .vivid: "Vivid"
            }
        }

        var baseShadowRadius: CGFloat {
            switch self {
            case .subtle: 26
            case .bright: 42
            case .vivid: 56
            }
        }

        var peakShadowRadius: CGFloat {
            switch self {
            case .subtle: 38
            case .bright: 64
            case .vivid: 82
            }
        }

        var baseShadowOpacity: Float {
            switch self {
            case .subtle: 0.35
            case .bright: 0.72
            case .vivid: 0.88
            }
        }

        var peakShadowOpacity: Float {
            switch self {
            case .subtle: 0.5
            case .bright: 0.92
            case .vivid: 1
            }
        }

        var gradientOpacity: Float {
            switch self {
            case .subtle: 0.65
            case .bright: 0.92
            case .vivid: 1
            }
        }

        var highlightBlend: CGFloat {
            switch self {
            case .subtle: 0.35
            case .bright: 0.58
            case .vivid: 0.72
            }
        }

        var coreAlpha: CGFloat {
            switch self {
            case .subtle: 0.75
            case .bright: 0.95
            case .vivid: 1
            }
        }
    }

    enum Vibration: String, CaseIterable {
        case focusBurst
        case off

        var title: String {
            switch self {
            case .focusBurst: "Focus Burst"
            case .off: "Off"
            }
        }
    }

    enum TerminalApp: String, CaseIterable {
        case appleTerminal = "com.apple.Terminal"
        case iterm2 = "com.googlecode.iterm2"
        case ghostty = "com.mitchellh.ghostty"
        case warp = "dev.warp.Warp-Stable"
        case warpPreview = "dev.warp.Warp-Preview"
        case wezTerm = "com.github.wez.wezterm"
        case kitty = "net.kovidgoyal.kitty"
        case alacritty = "org.alacritty"

        var title: String {
            switch self {
            case .appleTerminal: "Apple Terminal"
            case .iterm2: "iTerm2"
            case .ghostty: "Ghostty"
            case .warp: "Warp"
            case .warpPreview: "Warp Preview"
            case .wezTerm: "WezTerm"
            case .kitty: "kitty"
            case .alacritty: "Alacritty"
            }
        }
    }

    static let `default` = NeonFocusSettings()
    static let defaultTrackedTerminalApps: Set<TerminalApp> = [.appleTerminal]

    var color: Color
    var thickness: Thickness
    var pulseSpeed: PulseSpeed
    var glowIntensity: GlowIntensity
    var vibration: Vibration
    var trackedTerminalApps: Set<TerminalApp>

    init(
        color: Color = .hotPink,
        thickness: Thickness = .regular,
        pulseSpeed: PulseSpeed = .normal,
        glowIntensity: GlowIntensity = .bright,
        vibration: Vibration = .focusBurst,
        trackedTerminalApps: Set<TerminalApp> = Self.defaultTrackedTerminalApps
    ) {
        self.color = color
        self.thickness = thickness
        self.pulseSpeed = pulseSpeed
        self.glowIntensity = glowIntensity
        self.vibration = vibration
        self.trackedTerminalApps = trackedTerminalApps
    }
}

struct NeonFocusSettingsStore {
    private enum Key {
        static let color = "NeonFocus.settings.color"
        static let thickness = "NeonFocus.settings.thickness"
        static let pulseSpeed = "NeonFocus.settings.pulseSpeed"
        static let glowIntensity = "NeonFocus.settings.glowIntensity"
        static let vibration = "NeonFocus.settings.vibration"
        static let trackedTerminalApps = "NeonFocus.settings.trackedTerminalApps"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> NeonFocusSettings {
        let fallback = NeonFocusSettings.default
        return NeonFocusSettings(
            color: load(NeonFocusSettings.Color.self, key: Key.color) ?? fallback.color,
            thickness: load(NeonFocusSettings.Thickness.self, key: Key.thickness) ?? fallback.thickness,
            pulseSpeed: load(NeonFocusSettings.PulseSpeed.self, key: Key.pulseSpeed) ?? fallback.pulseSpeed,
            glowIntensity: load(NeonFocusSettings.GlowIntensity.self, key: Key.glowIntensity) ?? fallback.glowIntensity,
            vibration: load(NeonFocusSettings.Vibration.self, key: Key.vibration) ?? fallback.vibration,
            trackedTerminalApps: loadTrackedTerminalApps() ?? fallback.trackedTerminalApps
        )
    }

    func save(_ settings: NeonFocusSettings) {
        defaults.set(settings.color.rawValue, forKey: Key.color)
        defaults.set(settings.thickness.rawValue, forKey: Key.thickness)
        defaults.set(settings.pulseSpeed.rawValue, forKey: Key.pulseSpeed)
        defaults.set(settings.glowIntensity.rawValue, forKey: Key.glowIntensity)
        defaults.set(settings.vibration.rawValue, forKey: Key.vibration)
        defaults.set(
            NeonFocusSettings.TerminalApp.allCases
                .filter(settings.trackedTerminalApps.contains)
                .map(\.rawValue),
            forKey: Key.trackedTerminalApps
        )
    }

    private func load<Value: RawRepresentable>(
        _ type: Value.Type,
        key: String
    ) -> Value? where Value.RawValue == String {
        guard let rawValue = defaults.string(forKey: key) else { return nil }
        return Value(rawValue: rawValue)
    }

    private func loadTrackedTerminalApps() -> Set<NeonFocusSettings.TerminalApp>? {
        guard defaults.object(forKey: Key.trackedTerminalApps) != nil else { return nil }
        let rawValues = defaults.stringArray(forKey: Key.trackedTerminalApps) ?? []
        return Set(rawValues.compactMap(NeonFocusSettings.TerminalApp.init(rawValue:)))
    }
}
