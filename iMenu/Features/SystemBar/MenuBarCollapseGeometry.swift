//
//  MenuBarCollapseGeometry.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The lengths iMenu's divider status item takes when the hidden zone is open vs.
/// collapsed.
///
/// Collapsing works by growing the divider's slot so everything to its **left**
/// is shoved off the left edge of the menu-bar screen (behind the notch, on
/// notched Macs). To guarantee even a left-neighbor sitting at the far edge is
/// pushed fully off, the divider must grow by more than the whole bar's width — so
/// the expanded length is the screen's width plus the divider's own natural slot.
///
/// Pure geometry, split out from the AppKit `DividerMenuBarCollapser` so the rule
/// is unit tested on its own (the collapser itself needs a live menu bar and rides
/// with the on-device validation in milestone 0.9).
enum MenuBarCollapseGeometry {

    /// The divider's resting width when the hidden zone is open: thin, just enough
    /// to render a boundary glyph the user can ⌘-drag items past.
    static let naturalLength: CGFloat = 12

    /// The length the divider expands to so every status item to its left leaves
    /// the visible bar. `screenWidth` is a safe upper bound on how far a
    /// left-neighbor can sit from the edge; adding the natural slot guarantees the
    /// shift exceeds it. Non-positive widths (no readable screen) fall back to the
    /// resting width so collapsing is a no-op rather than a broken huge slot.
    static func expandedLength(screenWidth: CGFloat) -> CGFloat {
        guard screenWidth > 0 else { return naturalLength }
        return screenWidth + naturalLength
    }
}
