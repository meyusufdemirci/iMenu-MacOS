//
//  SeparatorControlling.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import CoreGraphics

/// The seam over iMenu's owned **divider** status item — the chevron toggle whose width
/// grows to hide the menu bar items to its left.
///
/// `MenuBarHideController` depends on this intent ("expand to hide, collapse to show")
/// rather than on `NSStatusItem`, so its state/persistence logic is unit-testable with a
/// spy. The live implementation (`StatusBarChevron`) resizes the real status item; a
/// store with no real menu bar to drive uses `NullSeparatorControlling`.
protocol SeparatorControlling {
    /// Grow the separator so the items to its left are pushed off-screen (hidden).
    func expand()
    /// Shrink the separator back so the items to its left are visible again.
    func collapse()
    /// The separator's current on-screen frame in **top-left-origin global display
    /// space** (the space the Accessibility API reports item frames in and `CGEvent`
    /// posts in), so a drag can land items just beside it. `nil` when it can't be read.
    var frame: CGRect? { get }
}

/// A no-op `SeparatorControlling` for when there's no real menu bar to drive — previews
/// and any code path that wants the controller's state without a live status item.
struct NullSeparatorControlling: SeparatorControlling {
    func expand() {}
    func collapse() {}
    var frame: CGRect? { nil }
}
