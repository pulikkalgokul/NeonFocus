import AppKit
import ApplicationServices

/// Watches a single app pid for focused-window changes, plus move/resize
/// on the currently-focused window. Emits the AppKit-converted frame whenever
/// it changes, or `nil` if no window is currently focused.
@MainActor
final class AXFocusTracker {
    enum FrameUpdate {
        case focusedWindowChanged(CGRect?)
        case geometryChanged(CGRect?)

        var frame: CGRect? {
            switch self {
            case .focusedWindowChanged(let frame), .geometryChanged(let frame):
                frame
            }
        }
    }

    private let pid: pid_t
    private let appElement: AXUIElement
    private let onFrame: (FrameUpdate) -> Void

    private var observer: AXObserver?
    private var observedAppNotifications: [String] = []
    private var observedWindow: AXUIElement?

    private static let appNotifications: [String] = [
        kAXFocusedWindowChangedNotification as String,
        kAXMainWindowChangedNotification as String,
        kAXWindowCreatedNotification as String,
    ]

    private static let windowNotifications: [String] = [
        kAXMovedNotification as String,
        kAXResizedNotification as String,
        kAXUIElementDestroyedNotification as String,
    ]

    init(pid: pid_t, onFrame: @escaping (FrameUpdate) -> Void) {
        self.pid = pid
        self.appElement = AXUIElementCreateApplication(pid)
        self.onFrame = onFrame
    }

    @discardableResult
    func start() -> Bool {
        var observerRef: AXObserver?
        guard
            AXObserverCreate(pid, axCallback, &observerRef) == .success,
            let observerRef
        else { return false }
        observer = observerRef

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observerRef),
            .commonModes
        )

        let context = Unmanaged.passUnretained(self).toOpaque()
        for note in Self.appNotifications {
            if AXObserverAddNotification(observerRef, appElement, note as CFString, context) == .success {
                observedAppNotifications.append(note)
            }
        }

        if let window = focusedWindow() {
            subscribeToWindow(window)
        }
        return true
    }

    func stop() {
        guard let observer else { return }

        for note in observedAppNotifications {
            AXObserverRemoveNotification(observer, appElement, note as CFString)
        }
        observedAppNotifications.removeAll()

        if let window = observedWindow {
            for note in Self.windowNotifications {
                AXObserverRemoveNotification(observer, window, note as CFString)
            }
            observedWindow = nil
        }

        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
        self.observer = nil
    }

    func currentFrame() -> CGRect? {
        guard let window = focusedWindow() else { return nil }
        return AXGeometry.appKitFrame(of: window)
    }

    fileprivate nonisolated func handle(notification: String, element: AXUIElement) {
        // AX callbacks fire on the main run loop (we attached the observer source
        // there in start()) but the closure type is `@convention(c)`, so Swift treats
        // this entry point as nonisolated. AXUIElement is a thread-safe CF type that
        // isn't marked Sendable, so wrap it before crossing the actor boundary.
        let boxed = SendableAXElement(element)
        Task { @MainActor [weak self] in
            self?.process(notification: notification, element: boxed.element)
        }
    }

    // MARK: - Private

    private func focusedWindow() -> AXUIElement? {
        var value: AnyObject?
        guard
            AXUIElementCopyAttributeValue(
                appElement,
                kAXFocusedWindowAttribute as CFString,
                &value
            ) == .success,
            let raw = value
        else { return nil }
        return (raw as! AXUIElement)
    }

    private func subscribeToWindow(_ window: AXUIElement) {
        guard let observer else { return }
        unsubscribeCurrentWindow()

        let context = Unmanaged.passUnretained(self).toOpaque()
        for note in Self.windowNotifications {
            AXObserverAddNotification(observer, window, note as CFString, context)
        }
        observedWindow = window
        onFrame(.focusedWindowChanged(AXGeometry.appKitFrame(of: window)))
    }

    private func unsubscribeCurrentWindow() {
        guard let observer, let window = observedWindow else { return }
        for note in Self.windowNotifications {
            AXObserverRemoveNotification(observer, window, note as CFString)
        }
        observedWindow = nil
    }

    private func process(notification: String, element: AXUIElement) {
        if Self.refocusEvents.contains(notification) {
            if let window = focusedWindow() {
                subscribeToWindow(window)
            } else {
                unsubscribeCurrentWindow()
                onFrame(.focusedWindowChanged(nil))
            }
        } else if Self.geometryEvents.contains(notification) {
            onFrame(.geometryChanged(AXGeometry.appKitFrame(of: element)))
        }
    }

    private static let refocusEvents: Set<String> = Set(appNotifications + [
        kAXUIElementDestroyedNotification as String,
    ])

    private static let geometryEvents: Set<String> = [
        kAXMovedNotification as String,
        kAXResizedNotification as String,
    ]
}

/// Hand-rolled Sendable wrapper for `AXUIElement`. The underlying CF type is
/// thread-safe (the AX framework is documented as accepting calls from any
/// thread) but isn't marked Sendable in the SDK.
struct SendableAXElement: @unchecked Sendable {
    let element: AXUIElement
    init(_ element: AXUIElement) { self.element = element }
}

private let axCallback: AXObserverCallback = { _, element, notification, userInfo in
    guard let userInfo else { return }
    let tracker = Unmanaged<AXFocusTracker>.fromOpaque(userInfo).takeUnretainedValue()
    tracker.handle(notification: notification as String, element: element)
}
