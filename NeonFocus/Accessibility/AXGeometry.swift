import AppKit
import ApplicationServices

enum AXGeometry {
    static func appKitFrame(of window: AXUIElement) -> CGRect? {
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
            let posCF = posValue, let sizeCF = sizeValue
        else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posCF as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeCF as! AXValue, .cgSize, &size)

        return convertToAppKit(axOrigin: origin, size: size)
    }

    /// AX gives top-left origin with Y measured from the top of the primary screen
    /// (the screen whose AppKit origin is (0,0)). AppKit uses bottom-left origin.
    /// Flip with: y' = primary.height - axY - height. Works on multi-display because
    /// both coordinate systems share the primary screen as their anchor.
    static func convertToAppKit(axOrigin: CGPoint, size: CGSize) -> CGRect {
        let primaryHeight = primaryScreenHeight()
        let y = primaryHeight - axOrigin.y - size.height
        return CGRect(x: axOrigin.x, y: y, width: size.width, height: size.height)
    }

    private static func primaryScreenHeight() -> CGFloat {
        if let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) {
            return primary.frame.height
        }
        return NSScreen.main?.frame.height ?? 0
    }
}
