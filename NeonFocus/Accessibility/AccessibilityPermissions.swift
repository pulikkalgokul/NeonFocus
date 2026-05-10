import AppKit
import ApplicationServices

enum AccessibilityPermissions {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestIfNeeded() -> Bool {
        // Use the literal string instead of `kAXTrustedCheckOptionPrompt` because
        // the imported CFStringRef is a mutable global, which Swift 6 strict
        // concurrency rejects.
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options: [CFString: Any] = [promptKey: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
