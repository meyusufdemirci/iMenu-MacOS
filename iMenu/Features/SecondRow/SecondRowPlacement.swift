//
//  SecondRowPlacement.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// Computes where iMenu's second-row panel sits on screen.
///
/// The row is a bar the width of its content, **right-aligned** (mirroring the
/// menu bar, which fills from the right) and hanging **directly below the system
/// menu bar**. Pure geometry, kept separate from the AppKit panel so it's unit
/// tested without a window — see `SecondRowController` for the placement's use.
///
/// Coordinates are Cocoa screen space: origin bottom-left, y increasing upward,
/// relative to the given screen's `frame` (so it's correct on offset external
/// displays too).
enum SecondRowPlacement {

    /// - Parameters:
    ///   - contentSize: The intrinsic size of the row's content.
    ///   - screenFrame: The target screen's full frame (menu-bar screen).
    ///   - menuBarHeight: The height of the system menu bar, so the row hangs
    ///     just below it.
    ///   - horizontalInset: Gap from the screen's right edge.
    /// - Returns: The panel frame in the screen's coordinate space.
    static func frame(
        contentSize: CGSize,
        screenFrame: CGRect,
        menuBarHeight: CGFloat,
        horizontalInset: CGFloat = 8
    ) -> CGRect {
        // Top edge lines up with the bottom of the menu bar; the row hangs below.
        // On a notched Mac the menu bar band *is* the notch band, so hanging below
        // it keeps the row clear of the notch (FR6).
        let originY = screenFrame.maxY - menuBarHeight - contentSize.height
        // Right edge sits `horizontalInset` in from the screen's right edge, but
        // never let a row wider than the screen run off the left edge — clamp its
        // left edge to the screen so it stays on-screen (degenerate over-wide case).
        let rightAlignedX = screenFrame.maxX - contentSize.width - horizontalInset
        let originX = max(screenFrame.minX, rightAlignedX)
        return CGRect(origin: CGPoint(x: originX, y: originY), size: contentSize)
    }
}
