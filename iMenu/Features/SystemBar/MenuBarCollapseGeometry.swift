//
//  MenuBarCollapseGeometry.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The widths iMenu's two menu bar status items — a fixed **toggle** and an
/// invisible **spacer** — take when the hidden zone is open vs. collapsed.
///
/// Collapsing works by growing the spacer's slot so everything to its **left** is
/// shoved off the left edge of the menu-bar screen (behind the notch, on notched
/// Macs). To guarantee even a left-neighbor sitting at the far edge is pushed fully
/// off, the spacer must grow by more than the whole bar's width — so the expanded
/// length is the screen's width plus the toggle's own natural slot.
///
/// A single status item can't do both jobs: if the *visible* item is the one that
/// grows, its glyph rides off-screen with it and the user loses the control that
/// toggles the bar back. So the arrow (toggle) keeps a fixed width and stays put,
/// while a separate, invisible, zero-width spacer to its left is the only thing that
/// grows. `lengths(collapsed:screenWidth:)` maps a collapse state to both widths.
///
/// Pure geometry, split out from the AppKit `DividerMenuBarCollapser` so the rule
/// is unit tested on its own (the collapser itself needs a live menu bar and rides
/// with the on-device validation in milestone 0.9).
enum MenuBarCollapseGeometry {

    /// The toggle's fixed width — thin, just enough to render the arrow glyph the
    /// user clicks to toggle the hidden zone and ⌘-drags items past. Constant across
    /// states, so the arrow never moves or disappears.
    static let naturalLength: CGFloat = 12

    /// The spacer's width while the hidden zone is open: zero, so it's invisible and
    /// reserves no room. An open bar is then just the toggle glyph. (A named constant
    /// so it's a one-line bump if a hairline slot turns out to drag/park more
    /// reliably on device.)
    static let spacerOpenLength: CGFloat = 0

    /// The length the spacer expands to so every status item to its left leaves
    /// the visible bar. `screenWidth` is a safe upper bound on how far a
    /// left-neighbor can sit from the edge; adding the natural slot guarantees the
    /// shift exceeds it. Non-positive widths (no readable screen) fall back to the
    /// natural width so collapsing is a no-op rather than a broken huge slot.
    static func expandedLength(screenWidth: CGFloat) -> CGFloat {
        guard screenWidth > 0 else { return naturalLength }
        return screenWidth + naturalLength
    }

    /// The widths of the two items for a collapse state: the toggle is always
    /// `naturalLength`; the spacer is `spacerOpenLength` when open and
    /// `expandedLength(screenWidth:)` when collapsed.
    static func lengths(collapsed: Bool, screenWidth: CGFloat) -> SystemBarLengths {
        SystemBarLengths(
            toggle: naturalLength,
            spacer: collapsed ? expandedLength(screenWidth: screenWidth) : spacerOpenLength
        )
    }
}

/// The width each of iMenu's two status items takes in a given collapse state.
struct SystemBarLengths: Equatable {

    /// The always-visible, always-clickable arrow. Fixed across states so collapsing
    /// can never push it off the bar.
    let toggle: CGFloat

    /// The invisible item, sitting just left of the toggle, that grows to shove the
    /// parked hidden items off the bar and shrinks back to reveal them.
    let spacer: CGFloat
}
