//
//  SynthesizedMenuBarItemReordererTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// `SynthesizedMenuBarItemReorderer` turns "put this item next to that neighbor" into a
/// source→destination ⌘-drag along the real menu bar. These drive its coordination
/// logic with spies — where it grabs the item and where it drops it — while the live AX
/// read and CGEvent post behind the seams ride with on-device validation.
struct SynthesizedMenuBarItemReordererTests {

    /// Records the drags asked of it instead of posting real events.
    private final class SpyRelocator: MenuBarItemRelocating {
        private(set) var drags: [(source: CGPoint, destination: CGPoint)] = []
        func dragItem(from source: CGPoint, to destination: CGPoint) {
            drags.append((source, destination))
        }
    }

    /// Returns fixed frames per id, like a snapshot of the live menu bar.
    private struct StubLocator: MenuBarItemLocating {
        let frames: [String: CGRect]
        func frame(of id: String) -> CGRect? { frames[id] }
    }

    /// A menu bar item frame with a known center (`midX` = x + 10, `midY` = 21).
    private func frame(x: CGFloat) -> CGRect {
        CGRect(x: x, y: 10, width: 20, height: 22)
    }

    private func reorderer(frames: [String: CGRect], relocator: SpyRelocator) -> SynthesizedMenuBarItemReorderer {
        SynthesizedMenuBarItemReorderer(locator: StubLocator(frames: frames), relocator: relocator)
    }

    // MARK: - Dragging next to a neighbor

    @Test func movingLeftOfANeighborDragsFromTheItemCenterToJustLeftOfTheNeighbor() {
        let spy = SpyRelocator()
        let reorderer = reorderer(frames: ["moved": frame(x: 300), "neighbor": frame(x: 1000)], relocator: spy)

        reorderer.move(id: "moved", to: .leftOf("neighbor"))

        #expect(spy.drags.count == 1)
        let drag = spy.drags[0]
        #expect(drag.source == CGPoint(x: 310, y: 21))                                     // moved item's center
        #expect(drag.destination.x == 1000 - MenuBarItemDragGeometry.defaultDropMargin)    // left of the neighbor
        #expect(drag.destination.y == 21)                                                  // same menu bar row
    }

    @Test func movingRightOfANeighborDropsJustPastTheNeighborsRightEdge() {
        let spy = SpyRelocator()
        let reorderer = reorderer(frames: ["moved": frame(x: 300), "neighbor": frame(x: 1000)], relocator: spy)

        reorderer.move(id: "moved", to: .rightOf("neighbor"))

        #expect(spy.drags.count == 1)
        let drag = spy.drags[0]
        #expect(drag.source == CGPoint(x: 310, y: 21))                                       // moved item's center
        #expect(drag.destination.x == 1020 + MenuBarItemDragGeometry.defaultDropMargin)      // right of the neighbor (maxX = 1020)
    }

    // MARK: - Unreadable positions are a no-op

    @Test func movingAnUnknownItemDoesNothing() {
        let spy = SpyRelocator()
        let reorderer = reorderer(frames: ["neighbor": frame(x: 1000)], relocator: spy)
        reorderer.move(id: "ghost", to: .leftOf("neighbor"))
        #expect(spy.drags.isEmpty)
    }

    @Test func movingNextToAnUnknownNeighborDoesNothing() {
        let spy = SpyRelocator()
        let reorderer = reorderer(frames: ["moved": frame(x: 300)], relocator: spy)
        reorderer.move(id: "moved", to: .rightOf("ghost"))
        #expect(spy.drags.isEmpty)
    }
}
