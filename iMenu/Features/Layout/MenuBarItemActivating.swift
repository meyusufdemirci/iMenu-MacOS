//
//  MenuBarItemActivating.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Opens the *real* menu bar item behind one of iMenu's second-row tiles.
///
/// The second row renders the Hidden items as plain data (`MenuBarItemDescriptor`);
/// to act on a tile we need to reach back to the live element the descriptor was
/// built from. This protocol is that seam (PRD FR3 / US2): `LayoutStore` depends on
/// it, not on the Accessibility API, so the click-forwarding wiring stays
/// unit-testable with a spy. The real implementation
/// (`AccessibilityMenuBarProvider`) keeps the live `AXUIElement`s it read during
/// the last fetch and presses the matching one.
protocol MenuBarItemActivating {
    /// Activates (opens) the menu bar item identified by `id` — the same id its
    /// `MenuBarItemDescriptor` carries.
    /// - Throws: `AppError` when the item can't be pressed (unknown/stale id, or
    ///   the press was rejected).
    func activate(id: String) throws
}
