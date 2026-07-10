//
//  MenuBarItemDragGeometryTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// Per-item hiding parks a chosen item to the **left** of iMenu's divider by
/// synthesizing a ⌘-drag from the item to just past the divider (milestones 0.5,
/// per-item auto-placement). These pin the pure path/drop geometry; whether a
/// synthesized drag *actually* moves a third-party item rides with the on-device
/// validation in 0.9 (`SynthesizedMenuBarItemRelocator`).
struct MenuBarItemDragGeometryTests {

    // MARK: - Drop point

    @Test func dropPointLandsLeftOfTheDivider() {
        let dividerMinX: CGFloat = 1000
        let margin: CGFloat = 8
        let item = CGPoint(x: 900, y: 12)
        let drop = MenuBarItemDragGeometry.dropPoint(leftOfDividerMinX: dividerMinX, itemCenter: item, margin: margin)
        #expect(drop.x < dividerMinX)               // strictly left of the divider's left edge
        #expect(drop.x == dividerMinX - margin)     // by exactly the margin
    }

    @Test func dropPointKeepsTheItemsMenuBarRow() {
        // The drag stays on the one menu bar row, so the drop keeps the item's y.
        let item = CGPoint(x: 640, y: 19)
        let drop = MenuBarItemDragGeometry.dropPoint(leftOfDividerMinX: 800, itemCenter: item, margin: 8)
        #expect(drop.y == 19)
    }

    @Test func defaultDropMarginIsPositive() {
        // A positive margin guarantees the drop lands past (left of) the divider,
        // not on top of it.
        #expect(MenuBarItemDragGeometry.defaultDropMargin > 0)
    }

    // MARK: - Interpolated path

    @Test func pathEndsAtTheDestination() {
        let path = MenuBarItemDragGeometry.interpolatedPath(from: .init(x: 0, y: 10),
                                                            to: .init(x: 100, y: 10),
                                                            steps: 5)
        #expect(path.count == 5)
        #expect(path.last == CGPoint(x: 100, y: 10))
    }

    @Test func pathMovesMonotonicallyTowardTheDestination() {
        // A single jump often fails to register as a drag; the path steps toward the
        // target, each point further along than the last.
        let path = MenuBarItemDragGeometry.interpolatedPath(from: .init(x: 1000, y: 12),
                                                            to: .init(x: 200, y: 12),
                                                            steps: 8)
        for (earlier, later) in zip(path, path.dropFirst()) {
            #expect(later.x < earlier.x)   // dragging leftward: x strictly decreases
        }
    }

    @Test func pathIsEvenlySpaced() {
        let path = MenuBarItemDragGeometry.interpolatedPath(from: .init(x: 0, y: 0),
                                                            to: .init(x: 100, y: 0),
                                                            steps: 4)
        #expect(path.map(\.x) == [25, 50, 75, 100])
    }

    @Test func pathWithNonPositiveStepsIsJustTheDestination() {
        // A degenerate step count must never produce an empty drag; fall back to a
        // single move straight to the destination.
        let dest = CGPoint(x: 42, y: 7)
        #expect(MenuBarItemDragGeometry.interpolatedPath(from: .zero, to: dest, steps: 0) == [dest])
        #expect(MenuBarItemDragGeometry.interpolatedPath(from: .zero, to: dest, steps: -3) == [dest])
    }

    @Test func defaultStepCountIsSeveralSteps() {
        // Enough intermediate points that the WindowServer reads it as a drag.
        #expect(MenuBarItemDragGeometry.defaultStepCount > 1)
    }
}
