//
//  MenuBarItemDragGeometryTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// Reordering the real menu bar drops a chosen item next to one of its neighbors by
/// synthesizing a ⌘-drag. These pin the pure drop/path geometry — where the item is
/// released relative to the neighbor and the interpolated path it travels; whether a
/// synthesized drag *actually* moves a third-party item rides with on-device
/// validation (`SynthesizedMenuBarItemRelocator`).
struct MenuBarItemDragGeometryTests {

    /// A menu bar item frame with a known left edge, right edge, and vertical center.
    private func frame(x: CGFloat) -> CGRect {
        CGRect(x: x, y: 10, width: 20, height: 22) // minX = x, maxX = x + 20, midY = 21
    }

    // MARK: - Drop point relative to a neighbor

    @Test func dropPointLeftOfNeighborLandsJustBeforeItsLeftEdge() {
        let neighbor = frame(x: 1000) // minX = 1000
        let drop = MenuBarItemDragGeometry.dropPoint(leftOf: neighbor, margin: 8)
        #expect(drop.x < neighbor.minX)          // strictly left of the neighbor
        #expect(drop.x == neighbor.minX - 8)     // by exactly the margin
    }

    @Test func dropPointRightOfNeighborLandsJustAfterItsRightEdge() {
        let neighbor = frame(x: 1000) // maxX = 1020
        let drop = MenuBarItemDragGeometry.dropPoint(rightOf: neighbor, margin: 8)
        #expect(drop.x > neighbor.maxX)          // strictly right of the neighbor
        #expect(drop.x == neighbor.maxX + 8)     // by exactly the margin
    }

    @Test func dropPointKeepsTheNeighborsMenuBarRow() {
        // The drag stays on the one menu bar row, so the drop keeps the neighbor's y.
        #expect(MenuBarItemDragGeometry.dropPoint(leftOf: frame(x: 800)).y == 21)
        #expect(MenuBarItemDragGeometry.dropPoint(rightOf: frame(x: 800)).y == 21)
    }

    @Test func defaultDropMarginIsPositive() {
        // A positive margin guarantees the drop lands past the neighbor's edge, not on
        // top of it.
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
