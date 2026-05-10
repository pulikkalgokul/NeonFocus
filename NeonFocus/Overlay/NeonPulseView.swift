import AppKit
import QuartzCore

/// Draws the Neon Pulse Border. The view is sized to the tracked window's frame
/// inflated by `inset` on every side so the outer halo has room to render
/// without being clipped by the panel bounds.
@MainActor
final class NeonPulseView: NSView {
    /// Padding between the panel edge and the rounded-rect stroke.
    static let inset = NeonPulseAnimationSpec.inset
    static let edgeFadeStrokeCount = 10

    private var settings: NeonFocusSettings
    private var pulseSpec: NeonPulseAnimationSpec { NeonPulseAnimationSpec(settings: settings) }
    private let effectLayer = CALayer()
    private let glowLayer = CAShapeLayer()
    private let edgeFadeLayer = CALayer()
    private let edgeFadeStrokeLayers: [CAShapeLayer]
    private var edgeFadeStrokeWidth: CGFloat {
        let steps = CGFloat(max(Self.edgeFadeStrokeCount - 1, 1))
        return Self.inset / steps * 1.35
    }

    #if DEBUG
    var debugPulseLayer: CAShapeLayer { glowLayer }
    var debugEdgeFadeLayer: CALayer { edgeFadeLayer }
    var debugEdgeFadeStrokeLayers: [CAShapeLayer] { edgeFadeStrokeLayers }
    var debugEffectLayer: CALayer { effectLayer }
    #endif

    init(frame frameRect: NSRect, settings: NeonFocusSettings = .default) {
        self.settings = settings
        self.edgeFadeStrokeLayers = (0..<Self.edgeFadeStrokeCount).map { _ in CAShapeLayer() }
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay

        let host = CALayer()
        host.masksToBounds = false
        host.backgroundColor = CGColor.clear
        layer = host

        effectLayer.masksToBounds = false
        host.addSublayer(effectLayer)

        edgeFadeLayer.masksToBounds = false
        edgeFadeStrokeLayers.forEach { layer in
            configureShapeLayer(layer)
            edgeFadeLayer.addSublayer(layer)
        }
        effectLayer.addSublayer(edgeFadeLayer)

        configureShapeLayer(glowLayer)
        glowLayer.shadowOffset = .zero

        applyLayerConfiguration()
        effectLayer.addSublayer(glowLayer)

        startPulseIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { false }

    override func layout() {
        super.layout()
        updateLayerPath()
        startPulseIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        startPulseIfNeeded()
    }

    func apply(settings: NeonFocusSettings) {
        self.settings = settings
        applyLayerConfiguration()
        updateLayerPath()
        restartPulse()
    }

    func playFocusBurst() {
        guard settings.vibration == .focusBurst else {
            effectLayer.removeAnimation(forKey: NeonPulseAnimationSpec.vibrationAnimationKey)
            return
        }
        effectLayer.removeAnimation(forKey: NeonPulseAnimationSpec.vibrationAnimationKey)
        effectLayer.add(
            pulseSpec.makeVibrationAnimation(),
            forKey: NeonPulseAnimationSpec.vibrationAnimationKey
        )
    }

    private func configureShapeLayer(_ layer: CAShapeLayer) {
        layer.masksToBounds = false
        layer.fillColor = CGColor.clear
        layer.lineJoin = .round
        layer.lineCap = .round
    }

    private func applyLayerConfiguration() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let pulseSpec = pulseSpec

        edgeFadeLayer.opacity = pulseSpec.edgeFadeOpacity
        let fadeColors = pulseSpec.edgeFadeStrokeColors(count: edgeFadeStrokeLayers.count)
        zip(edgeFadeStrokeLayers, fadeColors).forEach { layer, color in
            layer.strokeColor = color
            layer.lineWidth = edgeFadeStrokeWidth
        }

        glowLayer.strokeColor = pulseSpec.neonColor
        glowLayer.lineWidth = pulseSpec.baseLineWidth
        glowLayer.shadowColor = pulseSpec.neonColor
        glowLayer.shadowRadius = pulseSpec.baseShadowRadius
        glowLayer.shadowOpacity = pulseSpec.baseShadowOpacity
        CATransaction.commit()
    }

    private func updateLayerPath() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        effectLayer.frame = bounds
        edgeFadeLayer.frame = effectLayer.bounds
        glowLayer.frame = effectLayer.bounds

        let strokeRect = effectLayer.bounds.insetBy(dx: Self.inset, dy: Self.inset)
        layoutEdgeFadeStrokes(around: strokeRect)
        let path = CGPath(
            roundedRect: strokeRect,
            cornerWidth: pulseSpec.cornerRadius,
            cornerHeight: pulseSpec.cornerRadius,
            transform: nil
        )
        glowLayer.path = path
        glowLayer.shadowPath = path.copy(
            strokingWithWidth: pulseSpec.peakLineWidth,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 10
        )
        CATransaction.commit()
    }

    private func layoutEdgeFadeStrokes(around strokeRect: CGRect) {
        let strokeWidth = edgeFadeStrokeWidth
        let maxOffset = max(0, Self.inset - strokeWidth / 2)
        let maxIndex = max(edgeFadeStrokeLayers.count - 1, 1)

        for (index, layer) in edgeFadeStrokeLayers.enumerated() {
            let progress = CGFloat(index) / CGFloat(maxIndex)
            let offset = maxOffset * progress
            let rect = strokeRect.insetBy(dx: -offset, dy: -offset)
            let radius = pulseSpec.cornerRadius + offset
            layer.frame = effectLayer.bounds
            layer.lineWidth = strokeWidth
            layer.path = CGPath(
                roundedRect: rect,
                cornerWidth: radius,
                cornerHeight: radius,
                transform: nil
            )
        }
    }

    /// Reapplies the long-running pulse if AppKit drops layer animations while
    /// the transparent panel is out of the render tree.
    private func startPulseIfNeeded() {
        if glowLayer.animation(forKey: NeonPulseAnimationSpec.animationKey) == nil {
            glowLayer.add(
                pulseSpec.makePulseAnimation(),
                forKey: NeonPulseAnimationSpec.animationKey
            )
        }
        if edgeFadeLayer.animation(forKey: NeonPulseAnimationSpec.animationKey) == nil {
            edgeFadeLayer.add(
                pulseSpec.makeEdgeFadePulseAnimation(),
                forKey: NeonPulseAnimationSpec.animationKey
            )
        }
    }

    private func restartPulse() {
        glowLayer.removeAnimation(forKey: NeonPulseAnimationSpec.animationKey)
        edgeFadeLayer.removeAnimation(forKey: NeonPulseAnimationSpec.animationKey)
        glowLayer.add(
            pulseSpec.makePulseAnimation(),
            forKey: NeonPulseAnimationSpec.animationKey
        )
        edgeFadeLayer.add(
            pulseSpec.makeEdgeFadePulseAnimation(),
            forKey: NeonPulseAnimationSpec.animationKey
        )
    }
}
