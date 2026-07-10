//
//  AccessibilityMenuBarProvider.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit
import ApplicationServices

/// The real menu bar provider: reads other apps' menu bar extras via the
/// Accessibility API.
///
/// For every running app it queries the `AXExtrasMenuBar` element (the right-side
/// status items), reads each item's title and on-screen frame (position + size),
/// and returns them sorted left-to-right. Requires the app to run **un-sandboxed**
/// and the user to have granted **Accessibility** permission — without it,
/// `fetchItems()` throws `AppError.permissionDenied` so the Layout page can prompt.
///
/// Beyond enumerating, it runs `MenuBarClipDetector` over the items' frames and the
/// menu-bar screen's geometry and logs how many are actually **clipped** (behind
/// the notch or off the right edge) — the runtime side of FR1. The classification
/// itself is pure and unit-tested; this reader is the AppKit glue that feeds it.
///
/// The Accessibility API exposes titles and positions but not the rendered status
/// icon, so items carry their owning app's `bundleIdentifier` and the view draws
/// the app's icon.
///
/// It also **activates** items on demand (`MenuBarItemActivating`, PRD FR3 / US2):
/// each fetch retains the live `AXUIElement`s it read, keyed by the same id the
/// descriptor carries, so a click on a second-row tile can press the real item —
/// even one clipped behind the notch, since `kAXPressAction` doesn't depend on the
/// item being on screen. A reference type because that element registry is
/// mutable state shared across a fetch and a later press.
final class AccessibilityMenuBarProvider: MenuBarLayoutProviding, MenuBarItemActivating {

    /// The live elements from the most recent fetch, keyed by descriptor id, so a
    /// tapped tile can be pressed. Refreshed wholesale on every `fetchItems()`;
    /// handles for items that have since gone away simply fail to press.
    private var elements: [String: AXUIElement] = [:]

    func fetchItems() throws -> [MenuBarItemDescriptor] {
        guard AXIsProcessTrusted() else {
            throw AppError.permissionDenied
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        var positioned: [(item: MenuBarItemDescriptor, frame: CGRect)] = []
        var freshElements: [String: AXUIElement] = [:]

        for app in NSWorkspace.shared.runningApplications {
            // Skip apps that can't own menu bar items, and iMenu itself.
            guard app.activationPolicy != .prohibited, app.processIdentifier != ownPID else { continue }

            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let extras = copyElement(axApp, attribute: "AXExtrasMenuBar"),
                  let children = copyChildren(of: extras) else { continue }

            let ownerName = app.localizedName ?? app.bundleIdentifier ?? "—"

            for (index, child) in children.enumerated() {
                let title = copyString(child, attribute: kAXTitleAttribute as String) ?? ""
                // Fall back to an index-derived x (zero size) when the frame is
                // unreadable, so ordering is preserved even if we can't measure it.
                let frame = copyFrame(of: child) ?? CGRect(x: CGFloat(index), y: 0, width: 0, height: 0)
                let identity = (app.bundleIdentifier ?? ownerName) + "#" + (title.isEmpty ? "\(index)" : title)

                positioned.append((
                    MenuBarItemDescriptor(
                        id: identity,
                        title: title,
                        ownerName: ownerName,
                        systemSymbolName: nil,
                        bundleIdentifier: app.bundleIdentifier
                    ),
                    frame
                ))
                freshElements[identity] = child
            }
        }

        elements = freshElements
        let sorted = positioned.sorted { $0.frame.minX < $1.frame.minX }
        logClipDetection(frames: sorted.map(\.frame))
        return sorted.map(\.item)
    }

    /// Presses the menu bar item with `id` through the Accessibility API, opening
    /// its menu at the real item's location. Uses `kAXPressAction`, which works
    /// even when the item is clipped off-screen — the whole point of the second
    /// row. Throws `AppError.menuBarItemActivationFailed` when the item is unknown
    /// (never fetched, or gone since) or the press is rejected.
    func activate(id: String) throws {
        guard AXIsProcessTrusted() else {
            throw AppError.permissionDenied
        }
        guard let element = elements[id] else {
            throw AppError.menuBarItemActivationFailed
        }
        guard AXUIElementPerformAction(element, kAXPressAction as CFString) == .success else {
            throw AppError.menuBarItemActivationFailed
        }
        AppLogger.shared.info("Activated a menu bar item", category: .menuBar)
    }

    // MARK: - AX helpers

    /// Reads an `AXUIElement`-valued attribute (e.g. the extras menu bar).
    private func copyElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    /// Reads the child elements of an element.
    private func copyChildren(of element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else { return nil }
        return value as? [AXUIElement]
    }

    /// Reads a string-valued attribute.
    private func copyString(_ element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    /// Reads the element's on-screen frame (position + size). Used to order items
    /// left-to-right and to feed `MenuBarClipDetector`.
    private func copyFrame(of element: AXUIElement) -> CGRect? {
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard copyAXValue(element, kAXPositionAttribute as String, .cgPoint, into: &origin),
              copyAXValue(element, kAXSizeAttribute as String, .cgSize, into: &size) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    /// Reads an `AXValue`-typed attribute (a point, size, …) into `result`.
    private func copyAXValue<T>(_ element: AXUIElement, _ attribute: String, _ type: AXValueType, into result: inout T) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return false }
        return AXValueGetValue(value as! AXValue, type, &result)
    }

    // MARK: - Clip detection (glue)

    /// Classifies the fetched items' frames against the menu-bar screen and logs
    /// how many are clipped — the runtime proof of FR1. Best-effort: skips quietly
    /// when no screen is available. The rule lives in `MenuBarClipDetector`; this
    /// glue feeds it real geometry (untested here, like `SecondRowController` — it
    /// needs live AX + a notch Mac to exercise). Only counts are logged, never item
    /// titles, so nothing app/PII-identifying reaches the unified log.
    private func logClipDetection(frames: [CGRect]) {
        guard let screen = menuBarScreen() else { return }
        let clipped = MenuBarClipDetector.classify(
            frames,
            screenFrame: screen.frame,
            menuBarHeight: menuBarHeight(of: screen),
            notchZone: notchZone(of: screen)
        ).filter { $0 == .clipped }.count
        AppLogger.shared.info("Clip detection: \(clipped) of \(frames.count) menu bar items clipped", category: .menuBar)
    }

    /// The screen hosting the system menu bar — the primary display, at the global
    /// coordinate origin. Which display hosts iMenu's *row* is a separate concern
    /// (milestones 0.9); this only reads the bar's geometry for detection.
    private func menuBarScreen() -> NSScreen? {
        NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
    }

    /// Menu bar height: the inset the visible frame leaves at the top (the notch
    /// band's height on notched Macs), falling back to the status bar thickness.
    private func menuBarHeight(of screen: NSScreen) -> CGFloat {
        let inset = screen.frame.maxY - screen.visibleFrame.maxY
        return inset > 0 ? inset : NSStatusBar.system.thickness
    }

    /// The notch's horizontal exclusion zone, derived from the screen's auxiliary
    /// top areas, or `nil` on a display without a camera housing.
    private func notchZone(of screen: NSScreen) -> CGRect? {
        guard let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea else { return nil }
        let width = right.minX - left.maxX
        guard width > 0 else { return nil }
        let height = menuBarHeight(of: screen)
        return CGRect(x: left.maxX, y: screen.frame.maxY - height, width: width, height: height)
    }
}
