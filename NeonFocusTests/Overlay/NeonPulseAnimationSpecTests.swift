import QuartzCore
import Testing

@Suite("Neon Pulse Animation")
struct NeonPulseAnimationSpecTests {
    @Test
    func pulseBreathesBorderAndGlowTogether() throws {
        let animation = NeonPulseAnimationSpec().makePulseAnimation()
        let childAnimations = try #require(animation.animations)
        let keyPaths = childAnimations.compactMap { ($0 as? CAPropertyAnimation)?.keyPath }

        #expect(keyPaths.contains("lineWidth"))
        #expect(keyPaths.contains("shadowRadius"))
        #expect(keyPaths.contains("shadowOpacity"))
        #expect(animation.duration == 1.6)
        #expect(animation.autoreverses)
        #expect(animation.repeatCount == .infinity)
    }

    @Test
    func pulseUsesConfiguredSpeedAndThickness() throws {
        let settings = NeonFocusSettings(
            color: .electricCyan,
            thickness: .bold,
            pulseSpeed: .fast,
            glowIntensity: .bright,
            vibration: .focusBurst
        )
        let spec = NeonPulseAnimationSpec(settings: settings)
        let animation = spec.makePulseAnimation()
        let lineWidth = try #require(
            animation.animations?
                .compactMap { $0 as? CABasicAnimation }
                .first { $0.keyPath == "lineWidth" }
        )

        #expect(animation.duration == NeonFocusSettings.PulseSpeed.fast.duration)
        #expect(lineWidth.fromValue as? CGFloat == NeonFocusSettings.Thickness.bold.baseLineWidth)
        #expect(lineWidth.toValue as? CGFloat == NeonFocusSettings.Thickness.bold.peakLineWidth)
    }

    @Test
    func pulseUsesConfiguredGlowIntensity() throws {
        let spec = NeonPulseAnimationSpec(
            settings: NeonFocusSettings(glowIntensity: .vivid)
        )
        let animation = spec.makePulseAnimation()
        let shadowOpacity = try #require(
            animation.animations?
                .compactMap { $0 as? CABasicAnimation }
                .first { $0.keyPath == "shadowOpacity" }
        )
        let shadowRadius = try #require(
            animation.animations?
                .compactMap { $0 as? CABasicAnimation }
                .first { $0.keyPath == "shadowRadius" }
        )

        #expect(shadowOpacity.fromValue as? Float == NeonFocusSettings.GlowIntensity.vivid.baseShadowOpacity)
        #expect(shadowOpacity.toValue as? Float == NeonFocusSettings.GlowIntensity.vivid.peakShadowOpacity)
        #expect(shadowRadius.fromValue as? CGFloat == NeonFocusSettings.GlowIntensity.vivid.baseShadowRadius)
        #expect(shadowRadius.toValue as? CGFloat == NeonFocusSettings.GlowIntensity.vivid.peakShadowRadius)
        #expect(spec.edgeFadeOpacity == NeonFocusSettings.GlowIntensity.vivid.gradientOpacity)
        #expect(spec.edgeFadeStrokeColors(count: 8).count == 8)
        #expect((try #require(spec.edgeFadeStrokeColors(count: 8).first)).alpha > (try #require(spec.edgeFadeStrokeColors(count: 8).last)).alpha)
    }

    @Test
    func edgeFadePulseBreathesGradientVisibility() throws {
        let spec = NeonPulseAnimationSpec(
            settings: NeonFocusSettings(glowIntensity: .vivid)
        )
        let animation = spec.makeEdgeFadePulseAnimation()
        let opacity = try #require(
            animation.animations?
                .compactMap { $0 as? CABasicAnimation }
                .first { $0.keyPath == "opacity" }
        )

        #expect(opacity.toValue as? Float == spec.edgeFadeOpacity)
        #expect((opacity.fromValue as? Float ?? 0) < spec.edgeFadeOpacity)
        #expect(animation.autoreverses)
        #expect(animation.repeatCount == .infinity)
    }

    @Test
    func vibrationJittersBorderPositionAsShortBurst() throws {
        let animation = NeonPulseAnimationSpec(
            settings: NeonFocusSettings(vibration: .focusBurst)
        ).makeVibrationAnimation()
        let childAnimations = try #require(animation.animations)
        let keyPaths = childAnimations.compactMap { ($0 as? CAPropertyAnimation)?.keyPath }

        #expect(keyPaths.contains("transform.translation.x"))
        #expect(keyPaths.contains("transform.translation.y"))
        #expect(animation.duration <= 0.3)
        #expect(animation.repeatCount > 1)
        #expect(animation.repeatCount < .infinity)
    }
}
