//
//  MenuBarItemDragGeometry.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The geometry of a synthesized ⌘-drag that reorders a chosen menu bar item — the
/// pure math behind editing the real menu bar's order from the Layout page.
///
/// macOS moves a status item to wherever a ⌘-drag releases, so the two things this rule
/// computes are: **where to drop** (just past one edge of the item's new neighbor, so
/// it lands immediately before or after it) and **the path to drag along** (a single
/// leap frequently fails to register as a drag, so the motion is broken into
/// evenly-spaced steps).
///
/// Pure geometry, split out from the CGEvent-posting `SynthesizedMenuBarItemRelocator`
/// so the rule is unit tested on its own; whether a synthesized drag *actually*
/// relocates a third-party item — and lands it exactly where these points aim — is the
/// fragile unknown that rides with on-device validation. The margins are the tuning
/// knobs for that.
///
/// All points are in the **top-left-origin global display space** — the same space the
/// Accessibility API reports item frames in (`kAXPositionAttribute`) and `CGEvent`
/// posts mouse events in — so an item's read frame feeds straight into a drag with no
/// coordinate conversion.
enum MenuBarItemDragGeometry {

    /// How far past the neighbor's edge to release the item, so it lands *beside* the
    /// neighbor rather than on top of it.
    static let defaultDropMargin: CGFloat = 8

    /// How many intermediate points the drag is broken into. More than one so the
    /// WindowServer reads the motion as a drag, not a teleport.
    static let defaultStepCount = 10

    /// The point to release the dragged item at so it lands **immediately to the left**
    /// of `neighbor`: just past the neighbor's left edge, on the same menu bar row.
    ///
    /// - Parameters:
    ///   - neighbor: the item the dragged item should end up to the left of.
    ///   - margin: how far past the neighbor's left edge to drop; defaults to `defaultDropMargin`.
    static func dropPoint(leftOf neighbor: CGRect, margin: CGFloat = defaultDropMargin) -> CGPoint {
        CGPoint(x: neighbor.minX - margin, y: neighbor.midY)
    }

    /// The point to release the dragged item at so it lands **immediately to the right**
    /// of `neighbor`: just past the neighbor's right edge, on the same menu bar row.
    ///
    /// - Parameters:
    ///   - neighbor: the item the dragged item should end up to the right of.
    ///   - margin: how far past the neighbor's right edge to drop; defaults to `defaultDropMargin`.
    static func dropPoint(rightOf neighbor: CGRect, margin: CGFloat = defaultDropMargin) -> CGPoint {
        CGPoint(x: neighbor.maxX + margin, y: neighbor.midY)
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
