//
//  SecondRowPlacementTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics
import Testing
@testable import iMenu

/// `SecondRowPlacement` computes where iMenu's second-row panel sits: a bar the
/// width of its content, right-aligned and hanging directly below the system menu
/// bar, in a given screen's Cocoa coordinate space (origin bottom-left, y up).
struct SecondRowPlacementTests {

    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test func sitsDirectlyBelowTheMenuBar() {
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: 300, height: 28),
            screenFrame: screen,
            menuBarHeight: 24
        )
        // The row's top edge lines up with the bottom of the menu bar.
        #expect(frame.maxY == screen.maxY - 24)
    }

    @Test func isRightAlignedWithInset() {
        let inset: CGFloat = 8
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: 300, height: 28),
            screenFrame: screen,
            menuBarHeight: 24,
            horizontalInset: inset
        )
        // Mirrors the menu bar filling from the right: right edge is inset in.
        #expect(frame.maxX == screen.maxX - inset)
    }

    @Test func keepsContentSize() {
        let size = CGSize(width: 312, height: 30)
        let frame = SecondRowPlacement.frame(
            contentSize: size,
            screenFrame: screen,
            menuBarHeight: 24
        )
        #expect(frame.size == size)
    }

    @Test func positionsRelativeToAnOffsetScreen() {
        // An external display to the right of the built-in one.
        let external = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: 300, height: 28),
            screenFrame: external,
            menuBarHeight: 24,
            horizontalInset: 8
        )
        #expect(frame.maxX == external.maxX - 8)
        #expect(frame.maxY == external.maxY - 24)
    }

    /// FR6: on a notched Mac the menu bar band *is* the camera-housing band, so a
    /// row hung below a notch-height menu bar must never overlap the notch. Locks
    /// this in so a future re-anchor (wider row, centered layout) can't regress it.
    @Test func doesNotIntersectTheNotch() {
        // A notched MacBook's menu bar is taller than a standard 24pt bar.
        let notchHeight: CGFloat = 38
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: 300, height: 30),
            screenFrame: screen,
            menuBarHeight: notchHeight
        )
        // The camera housing occupies the horizontal center of the menu bar band.
        let notch = CGRect(
            x: screen.midX - 100,
            y: screen.maxY - notchHeight,
            width: 200,
            height: notchHeight
        )
        #expect(frame.intersects(notch) == false)
        // And it sits entirely below the whole menu bar band, not just the notch.
        #expect(frame.maxY <= screen.maxY - notchHeight)
    }

    /// A row wider than its screen (many hidden items) must still be placed on the
    /// screen rather than running off the left edge into negative coordinates.
    @Test func staysOnScreenWhenContentIsWiderThanTheScreen() {
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: screen.width + 400, height: 28),
            screenFrame: screen,
            menuBarHeight: 24
        )
        #expect(frame.minX >= screen.minX)
    }

    /// The same clamp, relative to an offset external display: the row never runs
    /// off that screen's left edge.
    @Test func staysOnAnOffsetScreenWhenContentIsTooWide() {
        let external = CGRect(x: 1440, y: 0, width: 1024, height: 768)
        let frame = SecondRowPlacement.frame(
            contentSize: CGSize(width: external.width + 300, height: 28),
            screenFrame: external,
            menuBarHeight: 24
        )
        #expect(frame.minX >= external.minX)
    }
}
