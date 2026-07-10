//
//  MenuBarClipDetectorTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// `MenuBarClipDetector` decides which menu bar items are actually *clipped*
/// (overflowed off the right edge or pushed behind the notch) versus visible, by
/// comparing each item's horizontal frame against the region the right-side status
/// items can occupy and the notch's exclusion zone (FR1). Pure geometry — only the
/// items' horizontal extent matters, so AX's top-left origin vs. Cocoa's
/// bottom-left is irrelevant here.
struct MenuBarClipDetectorTests {

    // A standard, non-notched 1440×900 screen with a 24pt menu bar.
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let menuBarHeight: CGFloat = 24

    // A notched screen: taller 38pt bar, camera housing centered over [620, 820].
    private let notchedHeight: CGFloat = 38
    private var notchZone: CGRect {
        CGRect(x: 620, y: screen.maxY - notchedHeight, width: 200, height: notchedHeight)
    }

    // MARK: - Usable region

    @Test func usableRegionSpansFullWidthWithoutANotch() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: menuBarHeight, notchZone: nil
        )
        #expect(region.minX == screen.minX)
        #expect(region.maxX == screen.maxX)
    }

    @Test func usableRegionStartsAtTheNotchRightEdge() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        // Status items live to the right of the notch, up to the screen's edge.
        #expect(region.minX == notchZone.maxX)
        #expect(region.maxX == screen.maxX)
    }

    // MARK: - Single-item classification

    @Test func itemWellInsideTheBarIsVisible() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: menuBarHeight, notchZone: nil
        )
        let item = CGRect(x: 1300, y: 876, width: 30, height: 24)
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: nil) == .visible)
    }

    @Test func itemSpillingOffTheRightEdgeIsClipped() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: menuBarHeight, notchZone: nil
        )
        let item = CGRect(x: 1425, y: 876, width: 30, height: 24) // maxX 1455 > 1440
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: nil) == .clipped)
    }

    @Test func itemOverlappingTheNotchIsClipped() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        let item = CGRect(x: 700, y: 862, width: 30, height: 38) // inside [620, 820]
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: notchZone) == .clipped)
    }

    @Test func itemPushedLeftOfTheNotchIsClipped() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        // Left of the notch entirely — not usable space for the right-side cluster.
        let item = CGRect(x: 100, y: 862, width: 30, height: 38)
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: notchZone) == .clipped)
    }

    @Test func itemRightOfTheNotchIsVisible() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        let item = CGRect(x: 1000, y: 862, width: 30, height: 38)
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: notchZone) == .visible)
    }

    @Test func itemFlushWithTheUsableLeftEdgeIsVisible() {
        let region = MenuBarClipDetector.usableRegion(
            screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        // Left edge exactly at the notch's right edge counts as inside (>=).
        let item = CGRect(x: notchZone.maxX, y: 862, width: 30, height: 38)
        #expect(MenuBarClipDetector.visibility(of: item, usableRegion: region, notchZone: notchZone) == .visible)
    }

    // MARK: - Batch classification

    @Test func classifyReturnsAResultPerItemInOrder() {
        let frames = [
            CGRect(x: 100, y: 862, width: 30, height: 38),  // left of notch → clipped
            CGRect(x: 700, y: 862, width: 30, height: 38),  // over notch → clipped
            CGRect(x: 1000, y: 862, width: 30, height: 38), // right of notch → visible
        ]
        let result = MenuBarClipDetector.classify(
            frames, screenFrame: screen, menuBarHeight: notchedHeight, notchZone: notchZone
        )
        #expect(result == [.clipped, .clipped, .visible])
    }
}
