//
//  MenuBarCollapseGeometryTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// The divider's collapse width must grow by more than the whole bar so every
/// status item to its left is pushed off the visible menu bar (milestones 0.5
/// path (a)). These pin the pure rule; whether it *actually* shoves other apps'
/// items rides with the on-device validation in 0.9.
struct MenuBarCollapseGeometryTests {

    @Test func expandedLengthExceedsTheScreenWidth() {
        // Must clear the whole bar, so it's strictly wider than the screen.
        #expect(MenuBarCollapseGeometry.expandedLength(screenWidth: 1440) > 1440)
        #expect(MenuBarCollapseGeometry.expandedLength(screenWidth: 1440)
                == 1440 + MenuBarCollapseGeometry.naturalLength)
    }

    @Test func expandedLengthGrowsWithTheScreen() {
        let small = MenuBarCollapseGeometry.expandedLength(screenWidth: 1280)
        let large = MenuBarCollapseGeometry.expandedLength(screenWidth: 3840)
        #expect(large > small)
    }

    @Test func expandedLengthFallsBackToNaturalWhenNoScreen() {
        // A zero/negative width means no readable screen — collapsing to the resting
        // width is a safe no-op rather than a broken huge slot.
        #expect(MenuBarCollapseGeometry.expandedLength(screenWidth: 0)
                == MenuBarCollapseGeometry.naturalLength)
        #expect(MenuBarCollapseGeometry.expandedLength(screenWidth: -100)
                == MenuBarCollapseGeometry.naturalLength)
    }

    @Test func naturalLengthIsSmallAndPositive() {
        #expect(MenuBarCollapseGeometry.naturalLength > 0)
        #expect(MenuBarCollapseGeometry.naturalLength < 100)
    }
}
