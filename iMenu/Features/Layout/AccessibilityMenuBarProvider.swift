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
/// status items), reads each item's title and on-screen x position, and returns
/// them sorted left-to-right. Requires the app to run **un-sandboxed** and the
/// user to have granted **Accessibility** permission — without it, `fetchItems()`
/// throws `AppError.permissionDenied` so the Layout page can prompt.
///
/// The Accessibility API exposes titles and positions but not the rendered status
/// icon, so items carry their owning app's `bundleIdentifier` and the view draws
/// the app's icon.
struct AccessibilityMenuBarProvider: MenuBarLayoutProviding {

    func fetchItems() throws -> [MenuBarItemDescriptor] {
        guard AXIsProcessTrusted() else {
            throw AppError.permissionDenied
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        var positioned: [(item: MenuBarItemDescriptor, x: CGFloat)] = []

        for app in NSWorkspace.shared.runningApplications {
            // Skip apps that can't own menu bar items, and iMenu itself.
            guard app.activationPolicy != .prohibited, app.processIdentifier != ownPID else { continue }

            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let extras = copyElement(axApp, attribute: "AXExtrasMenuBar"),
                  let children = copyChildren(of: extras) else { continue }

            let ownerName = app.localizedName ?? app.bundleIdentifier ?? "—"

            for (index, child) in children.enumerated() {
                let title = copyString(child, attribute: kAXTitleAttribute as String) ?? ""
                let x = copyPositionX(of: child) ?? CGFloat(index)
                let identity = (app.bundleIdentifier ?? ownerName) + "#" + (title.isEmpty ? "\(index)" : title)

                positioned.append((
                    MenuBarItemDescriptor(
                        id: identity,
                        title: title,
                        ownerName: ownerName,
                        systemSymbolName: nil,
                        bundleIdentifier: app.bundleIdentifier
                    ),
                    x
                ))
            }
        }

        return positioned.sorted { $0.x < $1.x }.map(\.item)
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

    /// Reads the element's on-screen x position, used to order items left-to-right.
    private func copyPositionX(of element: AXUIElement) -> CGFloat? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        var point = CGPoint.zero
        guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else { return nil }
        return point.x
    }
}
