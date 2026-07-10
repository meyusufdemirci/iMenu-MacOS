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
}
