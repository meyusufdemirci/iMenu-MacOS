//
//  SystemMenuBarCollapsing.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Collapses (and restores) iMenu's slice of the **real** system menu bar — the
/// active mechanic behind moving an item to Hidden (PRD FR3, milestones 0.5 path
/// **(a)**).
///
/// iMenu owns a divider status item in the menu bar. The user parks the items they
/// want hidden to the **left** of that divider (a one-time ⌘-drag, as in Hidden
/// Bar / Dozer); collapsing expands the divider so those left-of-divider items are
/// pushed off the visible bar, and expanding brings them back. They don't
/// disappear — they become *clipped*, which is exactly what the existing clip
/// detection surfaces in the second row and what `AXPress` can still activate.
///
/// This protocol is the seam so `LayoutStore` depends on the *intent* ("there are
/// hidden items → collapse the bar"), not on AppKit. Tests drive the wiring with a
/// spy; the real implementation (`DividerMenuBarCollapser`) does the live
/// `NSStatusItem` work. Kept deliberately tiny: a single toggle plus a read-back of
/// the current state so callers can avoid redundant work.
protocol SystemMenuBarCollapsing {

    /// Whether iMenu's divider is currently expanded to hide the left-of-divider
    /// items.
    var isCollapsed: Bool { get }

    /// Collapses (`true`) or restores (`false`) the hidden zone. Idempotent —
    /// setting it to its current value does nothing.
    func setCollapsed(_ collapsed: Bool)
}
