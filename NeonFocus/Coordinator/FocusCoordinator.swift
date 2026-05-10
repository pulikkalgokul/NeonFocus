import AppKit

@MainActor
final class FocusCoordinator {
    private static let enabledKey = "NeonFocus.enabled"

    private let activeAppMonitor = ActiveAppMonitor()
    private let overlay = OverlayController()
    private let settingsStore = NeonFocusSettingsStore()
    private let statusMenu = StatusMenuController()
    private var axTracker: AXFocusTracker?
    private lazy var overlaySettings = settingsStore.load()

    private var isEnabled: Bool {
        get { (UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    private var terminalActive = false
    private var lastFrame: CGRect?
    private var shouldPlayFocusBurst = false

    func start() {
        statusMenu.onToggleEnabled = { [weak self] enabled in
            guard let self else { return }
            self.isEnabled = enabled
            self.reevaluate()
        }
        statusMenu.onSettingsChanged = { [weak self] settings in
            guard let self else { return }
            self.overlaySettings = settings
            self.settingsStore.save(settings)
            self.overlay.apply(settings: settings)
        }
        statusMenu.onQuit = { NSApp.terminate(nil) }
        overlay.apply(settings: overlaySettings)
        statusMenu.install(enabled: isEnabled, settings: overlaySettings)

        // Triggers the system prompt the very first time NeonFocus runs.
        // We don't block on it — the coordinator simply won't show the
        // overlay until trust is granted.
        AccessibilityPermissions.requestIfNeeded()

        activeAppMonitor.onChange = { [weak self] active, pid in
            guard let self else { return }
            self.terminalActive = active
            if active, let pid {
                self.startTracking(pid: pid)
            } else {
                self.stopTracking()
            }
            self.reevaluate()
        }
        activeAppMonitor.start()
    }

    func stop() {
        activeAppMonitor.stop()
        stopTracking()
        overlay.hide()
    }

    private func startTracking(pid: pid_t) {
        stopTracking()
        let tracker = AXFocusTracker(pid: pid) { [weak self] update in
            guard let self else { return }
            self.lastFrame = update.frame
            if case .focusedWindowChanged(let frame) = update, frame != nil {
                self.shouldPlayFocusBurst = true
            }
            self.reevaluate()
        }
        guard tracker.start() else { return }
        axTracker = tracker
        if let frame = tracker.currentFrame() {
            lastFrame = frame
            shouldPlayFocusBurst = true
        }
    }

    private func stopTracking() {
        axTracker?.stop()
        axTracker = nil
        lastFrame = nil
        shouldPlayFocusBurst = false
    }

    private func reevaluate() {
        let hasUsableFrame = (lastFrame?.width ?? 0) > 1 && (lastFrame?.height ?? 0) > 1
        let shouldShow = isEnabled
            && terminalActive
            && AccessibilityPermissions.isTrusted()
            && hasUsableFrame

        if shouldShow, let frame = lastFrame {
            overlay.show(at: frame, playFocusBurst: shouldPlayFocusBurst)
            shouldPlayFocusBurst = false
        } else {
            overlay.hide()
        }
    }
}
