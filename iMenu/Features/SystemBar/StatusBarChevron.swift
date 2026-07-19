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
/// state sets an image **as wide as the button itself** with the chevron glyph drawn at
/// its right edge — a centered full-width image *is* right-aligned. This deliberately
/// stays inside the button's normal image pipeline: on macOS 26 the menu bar is rendered
/// by Control Center in its own windows, and subviews added to the button are not
/// reliably composited there.
///
/// Two hard-won rules keep that image honest (an image wider than the button clips the
/// glyph out and blanks the chevron — measured on device):
/// - The expanded length is **derived from the screen**, not a huge constant: just wide
///   enough to push everything on the chevron's left off-screen. Requesting ~10000pt made
///   macOS grant different widths to the app's window and Control Center's mirror of it,
///   and the stale first measurement baked a 5000pt image into what ended up an ~1100pt
///   button.
/// - The width is **not trusted once**: macOS re-clamps the button's width *after*
///   `expand()` returns (the synchronous read-back is only the first clamp), so the
///   image is rebuilt from the button's actual bounds on every frame change while
///   expanded.
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
    private let maximumExpandedLength: CGFloat
    private var isExpanded = false
    private var frameObserver: (any NSObjectProtocol)?

    /// - Parameters:
    ///   - item: the status item to drive — the app's one and only.
    ///   - maximumExpandedLength: upper bound on how wide to grow when hiding. The real
    ///     expanded length is derived from the chevron's on-screen position; this cap
    ///     only applies when that position can't be read. Tuning knob for on-device
    ///     validation.
    init(item: NSStatusItem, maximumExpandedLength: CGFloat = 10_000) {
        self.item = item
        self.maximumExpandedLength = maximumExpandedLength
        // Remember the item's bar position across relaunches, so the parked
        // hidden/visible boundary sticks instead of resetting to rightmost.
        item.autosaveName = "iMenuChevron"
        item.button?.imageScaling = .scaleNone
        if let button = item.button {
            // macOS re-clamps the expanded width after `expand()` returns; follow every
            // frame change so the trailing-glyph image always matches the real width.
            button.postsFrameChangedNotifications = true
            frameObserver = NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: button,
                queue: .main
            ) { [weak self] _ in
                self?.syncExpandedImageToButtonSize()
            }
        }
        collapse()
    }

    deinit {
        if let frameObserver {
            NotificationCenter.default.removeObserver(frameObserver)
        }
    }

    func expand() {
        // Just enough width to push everything on the chevron's left off the screen:
        // the distance from the screen's left edge to the chevron's right edge (which
        // stays pinned to its right-hand neighbor while the item grows leftward). Read
        // before the length change, while the collapsed frame is still trustworthy.
        let requested = frame.map { min(maximumExpandedLength, $0.maxX) } ?? maximumExpandedLength
        isExpanded = true
        item.length = requested
        syncExpandedImageToButtonSize()
        AppLogger.shared.info(
            "Expanded the menu bar chevron divider (requested \(Int(requested)), granted \(Int(item.button?.bounds.width ?? -1)))",
            category: .menuBar
        )
    }

    /// Rebuilds the expanded trailing-glyph image at the button's *actual* size whenever
    /// it drifts — the button width is what macOS granted, not what was requested, and
    /// it can change again after `expand()` returns. An image wider than the button gets
    /// centered and clipped, which cuts the right-edge glyph off entirely (an invisible
    /// chevron); redrawing at the real width keeps the glyph on the visible edge.
    private func syncExpandedImageToButtonSize() {
        guard isExpanded, let button = item.button else { return }
        let width = button.bounds.width
        let height = button.bounds.height
        guard width > 0, height > 0, button.image?.size.width != width else { return }
        button.image = Self.trailingChevronImage(symbol: "chevron.right", width: width, height: height)
        AppLogger.shared.info(
            "Redrew the expanded chevron image at the button's real width (\(Int(width)))",
            category: .menuBar
        )
    }

    /// The collapsed chevron's explicit width. Deliberately **not** `variableLength`:
    /// a variable-length item is sized by the system from whatever content happens to be
    /// attached at layout time, while an explicit length is the app-requested contract
    /// the system always honors (the same contract `expand()` relies on) — so collapse
    /// lands on a definite small width no matter which image is briefly in place.
    private static let collapsedLength: CGFloat = 24

    func collapse() {
        // Flag first, so the frame changes the shrink triggers don't re-attach an
        // expanded image; then image, then length: measured on device, a variable-length
        // item *stays* at the expanded width as long as the full-width expanded image is
        // attached — the small glyph has to be in place before the length change.
        isExpanded = false
        item.button?.image = Self.symbolImage("chevron.left")
        item.length = Self.collapsedLength
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
