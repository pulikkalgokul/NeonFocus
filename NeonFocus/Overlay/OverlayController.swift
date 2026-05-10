import AppKit

@MainActor
final class OverlayController {
    private var settings = NeonFocusSettings.default
    private lazy var pulseView = NeonPulseView(frame: .zero, settings: settings)
    private lazy var panel: OverlayPanel = {
        let panel = OverlayPanel()
        panel.contentView = pulseView
        return panel
    }()

    func apply(settings: NeonFocusSettings) {
        self.settings = settings
        pulseView.apply(settings: settings)
    }

    func show(at windowFrame: CGRect, playFocusBurst: Bool = false) {
        let wasVisible = panel.isVisible
        let inflated = windowFrame.insetBy(
            dx: -NeonPulseView.inset,
            dy: -NeonPulseView.inset
        )
        panel.setFrame(inflated, display: true, animate: false)
        panel.contentView?.needsLayout = true
        panel.contentView?.layoutSubtreeIfNeeded()
        panel.orderFrontRegardless()

        if playFocusBurst || !wasVisible {
            (panel.contentView as? NeonPulseView)?.playFocusBurst()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }
}
