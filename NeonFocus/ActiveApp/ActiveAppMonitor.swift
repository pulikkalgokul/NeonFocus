import AppKit

@MainActor
final class ActiveAppMonitor {
    static let terminalBundleID = "com.apple.Terminal"

    var onChange: ((Bool, pid_t?) -> Void)?

    private var observers: [NSObjectProtocol] = []

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

    private func report(bundleID: String?, pid: pid_t?) {
        let isTerminal = (bundleID == Self.terminalBundleID)
        onChange?(isTerminal, isTerminal ? pid : nil)
    }
}
