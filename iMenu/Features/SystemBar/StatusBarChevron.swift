//
//  StatusBarChevron.swift
//  iMenu
//
//  Created by Yusuf Demirci on 19.07.2026.
//

import AppKit

/// The live `SeparatorControlling`: iMenu's single status item — the **chevron toggle
/// that doubles as the hidden/visible divider**. Hidden items live to its left, visible
/// items to its right; there is no separate `│` separator item.
///
/// macOS packs status items from the right, so growing this item's `.length` pushes the
/// items to its **left** off the edge of the menu bar (hiding them); shrinking it back
/// (auto-sizing to the glyph) brings them into view.
///
/// **How the chevron stays visible while expanded:** the button centers its image, so at
/// ~10000pt a plain symbol would sit thousands of points off-screen. Instead the expanded
/// state sets an image **as wide as the button itself** (macOS clamps the requested
/// length, so the real width is read back) with the chevron glyph drawn at its right
/// edge — a centered full-width image *is* right-aligned. This deliberately stays inside
/// the button's normal image pipeline: on macOS 26 the menu bar is rendered by Control
/// Center in its own windows, and subviews added to the button are not reliably
/// composited there.
///
/// The chevron always points the way that reveals: **left** when everything is shown
/// (click to push the hidden group off to the left), **right** when hidden (click to
/// bring it back). Because expanded ⟺ hidden, the direction is fully determined by
/// `expand()`/`collapse()` and no one else has to manage the glyph.
///
/// The visible glyph also matters mechanically: parking the divider is done with a
/// synthesized ⌘-drag that grabs whatever sits under the drag's start point, and the
/// chevron gives that drag a dependable target.
///
/// Untested AppKit glue — it rides on-device validation like the other status-bar/CGEvent
/// code; the state/persistence logic that drives it (`MenuBarHideController`) is unit-tested.
final class StatusBarChevron: SeparatorControlling {

    private let item: NSStatusItem
    private let expandedLength: CGFloat

    /// - Parameters:
    ///   - item: the status item to drive — the app's one and only.
    ///   - expandedLength: how wide to grow when hiding — large enough to push every
    ///     left-hand item off the screen. Tuning knob for on-device validation.
    init(item: NSStatusItem, expandedLength: CGFloat = 10_000) {
        self.item = item
        self.expandedLength = expandedLength
        // Remember the item's bar position across relaunches, so the parked
        // hidden/visible boundary sticks instead of resetting to rightmost.
        item.autosaveName = "iMenuChevron"
        item.button?.imageScaling = .scaleNone
        collapse()
    }

    func expand() {
        item.length = expandedLength
        let width = item.button?.bounds.width ?? expandedLength
        let height = item.button?.bounds.height ?? NSStatusBar.system.thickness
        item.button?.image = Self.trailingChevronImage(symbol: "chevron.right", width: width, height: height)
        AppLogger.shared.info("Expanded the menu bar chevron divider (width \(Int(width)))", category: .menuBar)
    }

    func collapse() {
        item.length = NSStatusItem.variableLength
        item.button?.image = Self.symbolImage("chevron.left")
        AppLogger.shared.info("Collapsed the menu bar chevron divider", category: .menuBar)
    }

    /// The chevron button's frame converted from AppKit's bottom-left-origin screen
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

    // MARK: - Images

    /// How far in from the image's right edge the expanded glyph sits, roughly matching
    /// the padding the collapsed variable-length item gives its centered symbol.
    private static let trailingMargin: CGFloat = 7

    private static func symbolImage(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: L10n.MenuBar.toggleAccessibility)
        image?.isTemplate = true
        return image
    }

    /// A template image spanning the whole (expanded) button with the chevron glyph
    /// drawn at its **right edge** — the only part of the expanded item still on screen.
    private static func trailingChevronImage(symbol: String, width: CGFloat, height: CGFloat) -> NSImage? {
        guard let glyph = symbolImage(symbol), width > 0, height > 0 else { return nil }
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size, flipped: false) { _ in
            let glyphSize = glyph.size
            glyph.draw(in: NSRect(
                x: size.width - glyphSize.width - trailingMargin,
                y: (size.height - glyphSize.height) / 2,
                width: glyphSize.width,
                height: glyphSize.height
            ))
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = L10n.MenuBar.toggleAccessibility
        return image
    }
}
