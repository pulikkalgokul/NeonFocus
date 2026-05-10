import AppKit

@MainActor
final class ActiveAppMonitor {
    var onChange: ((Bool, pid_t?) -> Void)?
    var trackedTerminalApps: Set<NeonFocusSettings.TerminalApp>

    private var observers: [NSObjectProtocol] = []

    init(trackedTerminalApps: Set<NeonFocusSettings.TerminalApp> = NeonFocusSettings.defaultTrackedTerminalApps) {
        self.trackedTerminalApps = trackedTerminalApps
    }

    func start() {
        let center = NSWorkspace.shared.notificationCenter

        // Both observers post on `.main`, so it's safe to assume MainActor inside.
        // We pre-extract the Sendable bits we need so the closure doesn't capture
        // the non-Sendable `Notification` across the isolation boundary.
        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleID = app?.bundleIdentifier
            let pid = app?.processIdentifier
            MainActor.assumeIsolated {
                self?.report(bundleID: bundleID, pid: pid)
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let frontmost = NSWorkspace.shared.frontmostApplication {
                    self.report(
                        bundleID: frontmost.bundleIdentifier,
                        pid: frontmost.processIdentifier
                    )
                } else {
                    self.onChange?(false, nil)
                }
            }
        })

        if let frontmost = NSWorkspace.shared.frontmostApplication {
            report(bundleID: frontmost.bundleIdentifier, pid: frontmost.processIdentifier)
        }
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    #if DEBUG
    func debugReport(bundleID: String?, pid: pid_t?) {
        report(bundleID: bundleID, pid: pid)
    }
    #endif

    private func report(bundleID: String?, pid: pid_t?) {
        let isTrackedTerminal = bundleID.map(trackedBundleIDs.contains) ?? false
        onChange?(isTrackedTerminal, isTrackedTerminal ? pid : nil)
    }

    private var trackedBundleIDs: Set<String> {
        Set(trackedTerminalApps.map(\.rawValue))
    }
}
