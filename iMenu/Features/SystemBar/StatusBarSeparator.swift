//
//  StatusBarSeparator.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import AppKit

/// The live `SeparatorControlling`: the width-expander `NSStatusItem` that marks the
/// boundary between hidden (left) and visible (right) items.
///
/// It shows a thin divider glyph — deliberately, not just for looks: the separator has to
/// be **grabbable**, because parking/repositioning it is done with a synthesized ⌘-drag
/// that grabs whatever sits under the drag's start point. A 1px invisible item was too
/// thin to grab reliably and the drag caught the adjacent chevron instead. A real (if
/// subtle) glyph gives the drag a dependable target.
///
/// macOS packs status items from the right, so growing this item's `.length` pushes the
/// items to its **left** off the edge of the menu bar (hiding them); shrinking it back
/// (auto-sizing to the glyph) brings them into view. It **wraps an existing status item**
/// chosen by `MenuBarStatusItemController` — specifically the one that ended up to the
/// *left*, so the chevron (the one on the right) is never the item that gets hidden.
///
/// Untested AppKit glue — it rides on-device validation like the other status-bar/CGEvent
/// code; the state/persistence logic that drives it (`MenuBarHideController`) is unit-tested.
final class StatusBarSeparator: SeparatorControlling {

    private let item: NSStatusItem
    private let expandedLength: CGFloat

    /// - Parameters:
    ///   - item: the status item to drive as the separator (the leftmost of the pair).
    ///   - expandedLength: how wide to grow when hiding — large enough to push every
    ///     left-hand item off the screen. Tuning knob for on-device validation.
    init(item: NSStatusItem, expandedLength: CGFloat = 10_000) {
        self.item = item
        self.expandedLength = expandedLength
        item.length = NSStatusItem.variableLength
        // A thin divider that also serves as the ⌘-drag grab target (see the type doc).
        item.button?.title = "│"
        item.button?.image = nil
    }

    func expand() {
        item.length = expandedLength
        AppLogger.shared.info("Expanded the menu bar separator", category: .menuBar)
    }

    func collapse() {
        item.length = NSStatusItem.variableLength
        AppLogger.shared.info("Collapsed the menu bar separator", category: .menuBar)
    }

    /// The separator button's frame converted from AppKit's bottom-left-origin screen
    /// space to the **top-left-origin global space** the Accessibility API and `CGEvent`
    /// use — so a located item frame and this frame share one coordinate system.
    var frame: CGRect? {
        guard let window = item.button?.window else { return nil }
        let appKit = window.frame
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main
        else { return nil }
        let flippedY = primary.frame.height - appKit.origin.y - appKit.height
        return CGRect(x: appKit.origin.x, y: flippedY, width: appKit.width, height: appKit.height)
    }
}
