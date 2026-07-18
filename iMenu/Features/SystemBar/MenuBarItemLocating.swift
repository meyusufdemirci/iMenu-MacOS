//
//  MenuBarItemLocating.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// Reads the *current* on-screen frame of a menu bar item by id — the source point a
/// synthesized ⌘-drag has to grab, and the neighbor position it drops next to.
///
/// Reordering a chosen item needs to know where it (and its target neighbor) sit
/// *right now*, not where they were when the Layout page last fetched — the positions
/// shift as items move. `AccessibilityMenuBarProvider` already retains the live
/// `AXUIElement`s it read, so it can re-read a single item's live position on demand;
/// this protocol is the seam so `SynthesizedMenuBarItemReorderer` depends on that
/// capability, not on the Accessibility API, and stays testable with a stub.
///
/// The frame is in **top-left-origin global display coordinates** (the Accessibility
/// API's space), which is also the space `MenuBarItemRelocating` drags in — so a
/// located frame feeds straight into a drag with no conversion.
protocol MenuBarItemLocating {
    /// The live frame of the item with `id`, or `nil` when it's unknown (never
    /// fetched, or gone since) or its position can't be read.
    func frame(of id: String) -> CGRect?
}
