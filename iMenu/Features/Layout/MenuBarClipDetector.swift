//
//  MenuBarClipDetector.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// Decides which menu bar items are actually **clipped** — overflowed off the
/// right edge or pushed behind the notch — versus visible, rather than merely
/// enumerated (FR1).
///
/// The macOS menu bar packs the right-side status items against the screen's right
/// edge and grows leftward. When they run out of room they collide with the notch
/// (or, on non-notched Macs, the app menus) and the system hides the overflow. This
/// detector reconstructs that decision geometrically: an item is clipped when it
/// overlaps the notch's exclusion zone, or when its horizontal frame isn't fully
/// contained in the region the status items can actually occupy.
///
/// Pure geometry, split out from the AX-reading provider so the rule is unit tested
/// on its own. **Only each item's horizontal extent matters**, so it's indifferent
/// to the Accessibility API's top-left origin versus Cocoa's bottom-left — the
/// caller may pass frames in either space as long as `x`/`width` are screen-relative.
enum MenuBarClipDetector {

    /// Whether an item renders in the menu bar or is clipped out of it.
    enum Visibility: Equatable, Sendable {
        case visible
        case clipped
    }

    /// The horizontal region the right-side status items can occupy: from the
    /// notch's right edge (or the screen's left edge when there's no notch) to the
    /// screen's right edge, spanning the menu bar band.
    ///
    /// - Parameters:
    ///   - screenFrame: the menu-bar screen's full frame.
    ///   - menuBarHeight: the menu bar's height (the notch band's height on notched
    ///     Macs), used only for the region's vertical extent.
    ///   - notchZone: the camera-housing exclusion rect, or `nil` when the display
    ///     has no notch.
    static func usableRegion(screenFrame: CGRect, menuBarHeight: CGFloat, notchZone: CGRect?) -> CGRect {
        let left = notchZone?.maxX ?? screenFrame.minX
        let top = screenFrame.maxY - menuBarHeight
        return CGRect(x: left, y: top, width: max(0, screenFrame.maxX - left), height: menuBarHeight)
    }

    /// Classifies a single item against a precomputed `usableRegion` and the notch.
    ///
    /// Clipped when the item overlaps the notch horizontally, or when it isn't
    /// wholly within the usable region — i.e. it spills off the right edge or is
    /// pushed left of where status items can render.
    static func visibility(of itemFrame: CGRect, usableRegion: CGRect, notchZone: CGRect?) -> Visibility {
        if let notchZone, overlapsHorizontally(itemFrame, notchZone) {
            return .clipped
        }
        let fullyInside = itemFrame.minX >= usableRegion.minX && itemFrame.maxX <= usableRegion.maxX
        return fullyInside ? .visible : .clipped
    }

    /// Convenience: classifies many item frames against one screen's geometry,
    /// returning a result per item in the same order.
    static func classify(
        _ itemFrames: [CGRect],
        screenFrame: CGRect,
        menuBarHeight: CGFloat,
        notchZone: CGRect?
    ) -> [Visibility] {
        let region = usableRegion(screenFrame: screenFrame, menuBarHeight: menuBarHeight, notchZone: notchZone)
        return itemFrames.map { visibility(of: $0, usableRegion: region, notchZone: notchZone) }
    }

    /// Two rects overlap on the x-axis (their vertical extents are ignored — every
    /// menu bar item shares the bar's single horizontal band).
    private static func overlapsHorizontally(_ a: CGRect, _ b: CGRect) -> Bool {
        a.minX < b.maxX && b.minX < a.maxX
    }
}
