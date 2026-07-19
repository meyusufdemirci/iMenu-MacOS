//
//  MenuBarHiding.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation

/// Reflects a Layout hide/show onto the real macOS menu bar by moving items across the
/// separator boundary: hidden items live to the separator's **left** (where expanding it
/// pushes them off-screen), visible items to its **right**.
///
/// This is the seam `LayoutStore` depends on, so the store expresses the *intent* ("hide
/// item X", "show item X", "park the separator left of the visible items") without knowing
/// about live positions or `CGEvent`. The live implementation (`SynthesizedMenuBarHider`)
/// reads the current positions and synthesizes a ⌘-drag; tests inject a spy, and a store
/// with no real menu bar to drive uses `NullMenuBarHiding`.
protocol MenuBarHiding {
    /// Move the real item so it lands just **left** of the separator (into the hidden
    /// zone). Best-effort: unreadable or immovable items are left in place.
    func moveToHidden(id: String)

    /// Move the real item so it lands just **right** of the separator (into the visible
    /// zone). Best-effort.
    func moveToVisible(id: String)

    /// Park the separator immediately **left of the leftmost visible item**, so that by
    /// default every visible item sits to its right (nothing hidden) and hidden items can
    /// accumulate to its left. Returns whether the park could be carried out — callers
    /// must not treat the divider as parked (or expand it) after a `false`.
    @discardableResult
    func positionSeparator(leftOfLeftmostOf visibleIDs: [String]) -> Bool
}

/// A no-op `MenuBarHiding` for when there's no real menu bar to drive — e.g. a store built
/// over a provider that can't locate live items (sample data, test stubs). Hiding stays a
/// purely local list edit in that case.
struct NullMenuBarHiding: MenuBarHiding {
    func moveToHidden(id: String) {}
    func moveToVisible(id: String) {}
    func positionSeparator(leftOfLeftmostOf visibleIDs: [String]) -> Bool { true }
}
