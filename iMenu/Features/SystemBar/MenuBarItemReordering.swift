//
//  MenuBarItemReordering.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Where a reordered item should come to rest relative to one of its neighbors on the
/// real menu bar. The neighbor is named by id (resolved to a live position when the
/// drag runs), so the intent survives the positions shifting as items move.
enum MenuBarItemDropSide: Equatable, Sendable {
    /// Land immediately to the **left** of the item with this id.
    case leftOf(String)
    /// Land immediately to the **right** of the item with this id.
    case rightOf(String)

    /// The neighbor the moved item is placed next to.
    var referenceID: String {
        switch self {
        case .leftOf(let id), .rightOf(let id):
            return id
        }
    }
}

/// Reflects a Layout reorder onto the real macOS menu bar: moves the real item next to
/// the neighbor it now sits beside in the Visible list.
///
/// This is the seam `LayoutStore` depends on, so the store expresses the *intent*
/// ("put item X left of Y") without knowing about live positions or `CGEvent`. The
/// live implementation (`SynthesizedMenuBarItemReorderer`) reads the current positions
/// and synthesizes a ⌘-drag; tests inject a spy, and a store with no real menu bar to
/// drive uses `NullMenuBarItemReordering`.
protocol MenuBarItemReordering {
    /// Physically move the real menu bar item `id` so it lands on the given `side` of
    /// its neighbor. Best-effort: unreadable or immovable items are left in place.
    func move(id: String, to side: MenuBarItemDropSide)
}

/// A no-op `MenuBarItemReordering` for when there's no real menu bar to drive — e.g. a
/// store built over a provider that can't locate live items (sample data, test stubs).
/// Reordering stays a purely local list edit in that case.
struct NullMenuBarItemReordering: MenuBarItemReordering {
    func move(id: String, to side: MenuBarItemDropSide) {}
}
