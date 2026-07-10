//
//  MenuBarItemRelocating.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// Synthesizes the ⌘-drag that physically moves a status item along the real menu
/// bar — the primitive behind per-item auto-placement (milestones 0.5 path (a)).
///
/// macOS lets a user ⌘-drag any menu bar item to rearrange it; iMenu automates that
/// gesture to park a chosen item past its divider instead of asking the user to drag
/// by hand. This protocol is the seam so the coordinator (`MenuBarItemPlacer`)
/// depends on the *intent* ("drag the item at A to B"), not on `CGEvent`, keeping the
/// coordinator testable with a spy. The live implementation
/// (`SynthesizedMenuBarItemRelocator`) posts the actual mouse events.
///
/// Both points are in the **top-left-origin global display space** (the space the
/// Accessibility API reports item frames in and `CGEvent` posts mouse events in).
protocol MenuBarItemRelocating {
    /// Grabs the menu bar item at `source` and drops it at `destination` by
    /// synthesizing a ⌘-drag. Best-effort: an item that macOS refuses to move (some
    /// custom items) simply stays put — failures are logged, never thrown, so a
    /// stuck item never disrupts the app.
    func dragItem(from source: CGPoint, to destination: CGPoint)
}
