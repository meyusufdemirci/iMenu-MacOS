//
//  MenuBarItemDragGeometry.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The geometry of a synthesized ⌘-drag that parks a chosen menu bar item to the
/// **left** of iMenu's divider — the per-item auto-placement half of milestones
/// 0.5 path (a).
///
/// The divider trick can already hide *everything* left of the divider; to hide a
/// *specific* item without the user ⌘-dragging it by hand, iMenu grabs the item
/// and drops it just past the divider itself. macOS moves a status item to
/// wherever a ⌘-drag releases, so the two things this rule computes are: **where
/// to drop** (just left of the divider, on the item's own menu bar row) and **the
/// path to drag along** (a single leap frequently fails to register as a drag, so
/// the motion is broken into evenly-spaced steps).
///
/// Pure geometry, split out from the CGEvent-posting `SynthesizedMenuBarItemRelocator`
/// so the rule is unit tested on its own; whether a synthesized drag *actually*
/// relocates a third-party item is the fragile unknown that rides with the
/// on-device validation in milestone 0.9.
///
/// All points are in the **top-left-origin global display space** — the same space
/// the Accessibility API reports item frames in (`kAXPositionAttribute`) and
/// `CGEvent` posts mouse events in — so an item's read frame feeds straight into a
/// drag with no coordinate conversion. Only the divider's `minX` is borrowed from
/// its (bottom-left) Cocoa window frame, and x is identical across the two spaces.
enum MenuBarItemDragGeometry {

    /// How far left of the divider's left edge to release the item, so it lands
    /// *past* the divider rather than on top of it.
    static let defaultDropMargin: CGFloat = 8

    /// How many intermediate points the drag is broken into. More than one so the
    /// WindowServer reads the motion as a drag, not a teleport.
    static let defaultStepCount = 10

    /// The point to release the dragged item at: just left of the divider, keeping
    /// the item on its own menu bar row (same `y`).
    ///
    /// - Parameters:
    ///   - dividerMinX: the divider's left edge in global x (origin-independent).
    ///   - itemCenter: the item's current center, in top-left global coordinates.
    ///   - margin: how far left of the divider to drop; defaults to `defaultDropMargin`.
    static func dropPoint(leftOfDividerMinX dividerMinX: CGFloat,
                          itemCenter: CGPoint,
                          margin: CGFloat = defaultDropMargin) -> CGPoint {
        CGPoint(x: dividerMinX - margin, y: itemCenter.y)
    }

    /// The ordered points to post `leftMouseDragged` events at, from just after
    /// `start` through `end` inclusive. Evenly spaced, so `end` is always the last
    /// point; a non-positive `steps` degrades to a single move straight to `end`
    /// rather than an empty (no-op) drag.
    static func interpolatedPath(from start: CGPoint, to end: CGPoint, steps: Int) -> [CGPoint] {
        guard steps > 0 else { return [end] }
        return (1...steps).map { step in
            let t = CGFloat(step) / CGFloat(steps)
            return CGPoint(x: start.x + (end.x - start.x) * t,
                           y: start.y + (end.y - start.y) * t)
        }
    }
}
