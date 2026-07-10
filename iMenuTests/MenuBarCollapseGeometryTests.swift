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

    // MARK: - Two-item split (fixed toggle + invisible spacer)

    @Test func theToggleKeepsAFixedWidthOpenOrCollapsed() {
        // The fix for the vanishing arrow: the clickable toggle holds one fixed
        // width in both states, so collapsing can never shove it off the bar. Only
        // the spacer grows.
        let open = MenuBarCollapseGeometry.lengths(collapsed: false, screenWidth: 1440)
        let collapsed = MenuBarCollapseGeometry.lengths(collapsed: true, screenWidth: 1440)
        #expect(open.toggle == collapsed.toggle)
        #expect(open.toggle == MenuBarCollapseGeometry.naturalLength)
    }

    @Test func theOpenSpacerTakesNoSpace() {
        // The spacer is invisible and reserves no room until it collapses the bar,
        // so an open bar looks like nothing but the toggle glyph.
        let open = MenuBarCollapseGeometry.lengths(collapsed: false, screenWidth: 1440)
        #expect(open.spacer == MenuBarCollapseGeometry.spacerOpenLength)
        #expect(MenuBarCollapseGeometry.spacerOpenLength == 0)
    }

    @Test func onlyTheSpacerGrowsToClearTheBar() {
        // Collapsing grows the spacer past the whole screen (so every parked item to
        // its left is pushed off) while the toggle stays put.
        let collapsed = MenuBarCollapseGeometry.lengths(collapsed: true, screenWidth: 1440)
        #expect(collapsed.spacer == MenuBarCollapseGeometry.expandedLength(screenWidth: 1440))
        #expect(collapsed.spacer > 1440)
        #expect(collapsed.toggle < collapsed.spacer)
    }
}
