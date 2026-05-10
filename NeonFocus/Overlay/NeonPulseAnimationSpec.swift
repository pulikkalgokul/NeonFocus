import CoreGraphics
import QuartzCore

struct NeonPulseAnimationSpec {
    static let animationKey = "neonPulse.borderAndGlow"
    static let vibrationAnimationKey = "neonPulse.vibration"
    static let inset: CGFloat = 32

    private let settings: NeonFocusSettings

    var neonColor: CGColor { settings.color.cgColor }
    var edgeFadeOpacity: Float { settings.glowIntensity.gradientOpacity }
    var baseLineWidth: CGFloat { settings.thickness.baseLineWidth }
    var peakLineWidth: CGFloat { settings.thickness.peakLineWidth }
    let cornerRadius: CGFloat = 10
    var baseShadowRadius: CGFloat { settings.glowIntensity.baseShadowRadius }
    var peakShadowRadius: CGFloat { settings.glowIntensity.peakShadowRadius }
    var baseShadowOpacity: Float { settings.glowIntensity.baseShadowOpacity }
    var peakShadowOpacity: Float { settings.glowIntensity.peakShadowOpacity }
    var duration: CFTimeInterval { settings.pulseSpeed.duration }
    let vibrationDuration: CFTimeInterval = 0.18
    let vibrationRepeatCount: Float = 4

    init(settings: NeonFocusSettings = .default) {
        self.settings = settings
    }

    func edgeFadeStrokeColors(count: Int) -> [CGColor] {
        settings.color.edgeFadeStrokeColors(for: settings.glowIntensity, count: count)
    }

    func makePulseAnimation() -> CAAnimationGroup {
        let lineWidth = makeBasicAnimation(
            keyPath: "lineWidth",
            fromValue: baseLineWidth,
            toValue: peakLineWidth
        )
        let shadowRadius = makeBasicAnimation(
            keyPath: "shadowRadius",
            fromValue: baseShadowRadius,
            toValue: peakShadowRadius
        )
        let shadowOpacity = makeBasicAnimation(
            keyPath: "shadowOpacity",
            fromValue: baseShadowOpacity,
            toValue: peakShadowOpacity
        )

        let group = CAAnimationGroup()
        group.animations = [lineWidth, shadowRadius, shadowOpacity]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.autoreverses = true
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        return group
    }

    func makeEdgeFadePulseAnimation() -> CAAnimationGroup {
        let opacity = makeBasicAnimation(
            keyPath: "opacity",
            fromValue: edgeFadeOpacity * 0.65,
            toValue: edgeFadeOpacity
        )

        let group = CAAnimationGroup()
        group.animations = [opacity]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.autoreverses = true
        group.repeatCount = .infinity
        group.isRemovedOnCompletion = false
        return group
    }

    func makeVibrationAnimation() -> CAAnimationGroup {
        let horizontal = makeKeyframeAnimation(
            keyPath: "transform.translation.x",
            values: [0, -2.5, 2, -1.5, 2.5, -1, 0]
        )
        let vertical = makeKeyframeAnimation(
            keyPath: "transform.translation.y",
            values: [0, 1.5, -2, 1, -1.5, 2, 0]
        )

        let group = CAAnimationGroup()
        group.animations = [horizontal, vertical]
        group.duration = vibrationDuration
        group.repeatCount = vibrationRepeatCount
        group.isRemovedOnCompletion = true
        return group
    }

    private func makeBasicAnimation(
        keyPath: String,
        fromValue: Any,
        toValue: Any
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return animation
    }

    private func makeKeyframeAnimation(
        keyPath: String,
        values: [CGFloat]
    ) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        animation.duration = vibrationDuration
        animation.calculationMode = .linear
        return animation
    }
}
