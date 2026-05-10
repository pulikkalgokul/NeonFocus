import AppKit
import QuartzCore
import Testing

@MainActor
@Suite("Neon Pulse View")
struct NeonPulseViewTests {
    @Test
    func layoutInstallsContinuousPulseWithoutVibration() throws {
        let sut = NeonPulseView(frame: CGRect(x: 0, y: 0, width: 240, height: 160))

        sut.layout()

        let pulseLayer = sut.debugPulseLayer
        let animation = try #require(
            pulseLayer.animation(forKey: NeonPulseAnimationSpec.animationKey) as? CAAnimationGroup
        )

        #expect(animation.animations?.isEmpty == false)
        #expect(sut.debugEffectLayer.animation(forKey: NeonPulseAnimationSpec.vibrationAnimationKey) == nil)
        #expect(pulseLayer.path != nil)
        #expect(pulseLayer.shadowPath != nil)
        #expect(pulseLayer.frame == sut.bounds)
        #expect(sut.debugEdgeFadeLayer.animation(forKey: NeonPulseAnimationSpec.animationKey) != nil)
    }

    @Test
    func layoutPlacesRoundedFadeStrokesBetweenBorderAndPanelEdge() throws {
        let sut = NeonPulseView(frame: CGRect(x: 0, y: 0, width: 240, height: 160))

        sut.layout()

        let inset = NeonPulseView.inset
        let fadeLayers = sut.debugEdgeFadeStrokeLayers
        let innerFade = try #require(fadeLayers.first)
        let outerFade = try #require(fadeLayers.last)
        let innerBounds = try #require(innerFade.path?.boundingBoxOfPath)
        let outerBounds = try #require(outerFade.path?.boundingBoxOfPath)
        let innerAlpha = try #require(innerFade.strokeColor?.alpha)
        let outerAlpha = try #require(outerFade.strokeColor?.alpha)

        #expect(fadeLayers.count == NeonPulseView.edgeFadeStrokeCount)
        #expect(fadeLayers.allSatisfy { $0.frame == sut.bounds })
        #expect(fadeLayers.allSatisfy { $0.fillColor == CGColor.clear })
        #expect(fadeLayers.allSatisfy { $0.lineJoin == .round })
        #expect(fadeLayers.allSatisfy { $0.lineCap == .round })

        #expect(innerBounds == sut.bounds.insetBy(dx: inset, dy: inset))
        #expect(outerBounds.minX > sut.bounds.minX)
        #expect(outerBounds.minX < innerBounds.minX)
        #expect(outerBounds.maxX < sut.bounds.maxX)
        #expect(outerBounds.maxX > innerBounds.maxX)
        #expect(innerAlpha > outerAlpha)
    }

    @Test
    func playFocusBurstInstallsFiniteVibration() throws {
        let sut = NeonPulseView(
            frame: CGRect(x: 0, y: 0, width: 240, height: 160),
            settings: NeonFocusSettings(vibration: .focusBurst)
        )

        sut.layout()
        sut.playFocusBurst()

        let vibration = try #require(
            sut.debugEffectLayer.animation(
                forKey: NeonPulseAnimationSpec.vibrationAnimationKey
            ) as? CAAnimationGroup
        )

        #expect(vibration.animations?.isEmpty == false)
        #expect(vibration.repeatCount < .infinity)
    }

    @Test
    func playFocusBurstRespectsDisabledVibrationSetting() {
        let sut = NeonPulseView(
            frame: CGRect(x: 0, y: 0, width: 240, height: 160),
            settings: NeonFocusSettings(vibration: .off)
        )

        sut.layout()
        sut.playFocusBurst()

        #expect(
            sut.debugEffectLayer.animation(
                forKey: NeonPulseAnimationSpec.vibrationAnimationKey
            ) == nil
        )
    }

    @Test
    func applyingSettingsUpdatesStrokeAndRestartsPulse() throws {
        let sut = NeonPulseView(frame: CGRect(x: 0, y: 0, width: 240, height: 160))
        let settings = NeonFocusSettings(
            color: .acidGreen,
            thickness: .bold,
            pulseSpeed: .slow,
            glowIntensity: .bright,
            vibration: .off
        )

        sut.layout()
        sut.apply(settings: settings)

        let animation = try #require(
            sut.debugPulseLayer.animation(forKey: NeonPulseAnimationSpec.animationKey) as? CAAnimationGroup
        )

        #expect(sut.debugPulseLayer.lineWidth == settings.thickness.baseLineWidth)
        #expect(sut.debugPulseLayer.strokeColor == settings.color.cgColor)
        #expect(animation.duration == settings.pulseSpeed.duration)
    }

    @Test
    func applyingSettingsUpdatesGradientAndGlowIntensity() {
        let sut = NeonPulseView(frame: CGRect(x: 0, y: 0, width: 240, height: 160))
        let settings = NeonFocusSettings(
            color: .electricCyan,
            glowIntensity: .vivid
        )

        sut.layout()
        sut.apply(settings: settings)

        #expect(sut.debugEdgeFadeLayer.opacity == settings.glowIntensity.gradientOpacity)
        #expect(sut.debugEdgeFadeStrokeLayers.first?.strokeColor == settings.color.edgeFadeStrokeColors(for: settings.glowIntensity, count: NeonPulseView.edgeFadeStrokeCount).first)
        #expect(sut.debugPulseLayer.shadowRadius == settings.glowIntensity.baseShadowRadius)
        #expect(sut.debugPulseLayer.shadowOpacity == settings.glowIntensity.baseShadowOpacity)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
