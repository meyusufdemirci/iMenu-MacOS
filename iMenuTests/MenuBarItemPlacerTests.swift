//
//  MenuBarItemPlacerTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// `MenuBarItemPlacer` turns "hide this item" into a source→destination ⌘-drag past
/// iMenu's divider (milestones 0.5 path (a)). These drive its coordination logic with
/// spies — where it grabs, where it drops, and which item the debug trigger picks — while
/// the live AX read and CGEvent post behind the seams ride with on-device validation.
@MainActor
struct MenuBarItemPlacerTests {

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

    private func placer(frames: [String: CGRect],
                        divider: CGRect?,
                        relocator: SpyRelocator) -> MenuBarItemPlacer {
        MenuBarItemPlacer(locator: StubLocator(frames: frames),
                          relocator: relocator,
                          dividerFrame: { divider })
    }

    // MARK: - park(id:)

    @Test func parkDragsFromTheItemCenterToJustLeftOfTheDivider() {
        let spy = SpyRelocator()
        let placer = placer(frames: ["a": frame(x: 890)], divider: frame(x: 1000), relocator: spy)

        placer.park(id: "a")

        #expect(spy.drags.count == 1)
        let drag = spy.drags[0]
        #expect(drag.source == CGPoint(x: 900, y: 21))                                   // item center
        #expect(drag.destination.x == 1000 - MenuBarItemDragGeometry.defaultDropMargin)  // left of divider
        #expect(drag.destination.y == 21)                                                // same menu bar row
    }

    @Test func parkWithAnUnknownItemDoesNothing() {
        let spy = SpyRelocator()
        let placer = placer(frames: [:], divider: frame(x: 1000), relocator: spy)
        placer.park(id: "ghost")
        #expect(spy.drags.isEmpty)
    }

    @Test func parkWithNoReadableDividerDoesNothing() {
        let spy = SpyRelocator()
        let placer = placer(frames: ["a": frame(x: 500)], divider: nil, relocator: spy)
        placer.park(id: "a")
        #expect(spy.drags.isEmpty)
    }

    // MARK: - debugParkRightmostItem(among:)

    @Test func debugParkPicksTheRightmostItemRightOfTheDivider() {
        let spy = SpyRelocator()
        let placer = placer(
            frames: ["left": frame(x: 100), "far": frame(x: 900), "near": frame(x: 500)],
            divider: frame(x: 400),
            relocator: spy
        )

        placer.debugParkRightmostItem(among: ["left", "far", "near"])

        #expect(spy.drags.count == 1)
        // "far" (x 900) is the rightmost of the two items right of the divider (x 400);
        // "left" (x 100) sits left of it and is skipped.
        #expect(spy.drags[0].source == CGPoint(x: 910, y: 21))
    }

    @Test func debugParkSkipsItemsAlreadyLeftOfTheDivider() {
        let spy = SpyRelocator()
        let placer = placer(
            frames: ["a": frame(x: 100), "b": frame(x: 200)],
            divider: frame(x: 500),
            relocator: spy
        )
        placer.debugParkRightmostItem(among: ["a", "b"])
        #expect(spy.drags.isEmpty)
    }
}
