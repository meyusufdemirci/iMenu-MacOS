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
/// It never moves items itself: it only **reads** the menu bar — enumerating items and
/// re-reading their live positions. Reordering the real bar is done separately, by the
/// `MenuBarItemRelocating` synthesized ⌘-drag; this provider just supplies the "where is
/// it now" that drag needs.
///
/// Beyond enumerating, it runs `MenuBarClipDetector` over the items' frames and the
/// menu-bar screen's geometry and logs how many are actually **clipped** (behind
/// the notch or off the right edge). The classification itself is pure and
/// unit-tested; this reader is the AppKit glue that feeds it.
///
/// The Accessibility API exposes titles and positions but not the rendered status
/// icon, so items carry their owning app's `bundleIdentifier` and the view draws
/// the app's icon.
///
/// It also **locates** items on demand (`MenuBarItemLocating`): each fetch retains the
/// live `AXUIElement`s it read, keyed by the same id the descriptor carries, so a Layout
/// reorder can re-read an item's *current* frame — the source point a synthesized ⌘-drag
/// grabs, and the neighbor position it drops next to. A reference type because that
/// element registry is mutable state shared across a fetch and later position reads.
final class AccessibilityMenuBarProvider: MenuBarLayoutProviding, MenuBarItemLocating {

    /// The live elements from the most recent fetch, keyed by descriptor id, so a later
    /// reorder can re-read their positions. Refreshed wholesale on every `fetchItems()`;
    /// handles for items that have since gone away simply fail to locate.
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
                let rawTitle = copyString(child, attribute: kAXTitleAttribute as String)
                let description = copyString(child, attribute: kAXDescriptionAttribute as String)
                let identifier = copyString(child, attribute: "AXIdentifier")

                // Control Center reserves anonymous, disabled slots for modules that
                // aren't currently in the menu bar. They carry no title, description,
                // or identifier and would otherwise all surface as their owner
                // ("Control Center"), so drop these empty placeholders.
                let isEnabled = copyBool(child, attribute: kAXEnabledAttribute as String) ?? true
                if rawTitle == nil, description == nil, identifier == nil, isEnabled == false { continue }

                // Most Control Center items have an empty AXTitle; their readable
                // name lives in AXDescription (the label VoiceOver announces), so
                // resolve across both rather than falling back to the owner.
                let title = MenuBarItemNaming.resolveTitle(title: rawTitle, description: description)
                // Control Center items all share one app icon, so map the known
                // system items to a representative glyph (the real menu bar icon):
                // an SF Symbol, or an app-drawn one for items SF Symbols can't cover.
                let symbol = MenuBarItemSymbols.symbolName(identifier: identifier, bundleIdentifier: app.bundleIdentifier)
                // Fall back to an index-derived x (zero size) when the frame is
                // unreadable, so ordering is preserved even if we can't measure it.
                let frame = copyFrame(of: child) ?? CGRect(x: CGFloat(index), y: 0, width: 0, height: 0)
                let identity = (app.bundleIdentifier ?? ownerName) + "#" + (title.isEmpty ? "\(index)" : title)

                positioned.append((
                    MenuBarItemDescriptor(
                        id: identity,
                        title: title,
                        ownerName: ownerName,
                        systemSymbolName: symbol,
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

    // MARK: - Locating

    /// The live frame of the item with `id`, re-read from the `AXUIElement` retained
    /// during the last fetch — so a Layout reorder grabs the item (and aims at its
    /// neighbor) where they sit *now*, not where the page last saw them. `nil` when the
    /// id is unknown (never fetched, or gone since) or its position can't be read.
    /// Top-left-origin global coordinates, same as `CGEvent`.
    func frame(of id: String) -> CGRect? {
        guard let element = elements[id] else { return nil }
        return copyFrame(of: element)
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

    /// Reads a boolean-valued attribute (e.g. `AXEnabled`). `nil` when it can't be read.
    private func copyBool(_ element: AXUIElement, attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else { return nil }
        return (value as? NSNumber)?.boolValue
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
    /// how many are clipped. Best-effort: skips quietly when no screen is available.
    /// The rule lives in `MenuBarClipDetector`; this glue feeds it real geometry
    /// (untested here — it needs live AX + a notch Mac to exercise). Only counts are
    /// logged, never item titles, so nothing app/PII-identifying reaches the log.
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
    /// coordinate origin.
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
