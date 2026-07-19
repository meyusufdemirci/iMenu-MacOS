//
//  SynthesizedMenuBarHiderTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import CoreGraphics
import Foundation
import Testing
@testable import iMenu

/// `SynthesizedMenuBarHider` turns a Layout hide/show into a real menu-bar move: it reads
/// where the item and the separator sit now, and synthesizes a ⌘-drag to drop the item on
/// the correct side of the separator (or to park the separator left of the visible items).
/// These tests inject spies, so they assert the *geometry of the intended drag* without
/// touching Accessibility or posting real events.
struct SynthesizedMenuBarHiderTests {

    private final class SpyLocator: MenuBarItemLocating {
        let frames: [String: CGRect]
        init(_ frames: [String: CGRect]) { self.frames = frames }
        func frame(of id: String) -> CGRect? { frames[id] }
    }

    private final class SpyRelocator: MenuBarItemRelocating {
        private(set) var drags: [(from: CGPoint, to: CGPoint)] = []
        func dragItem(from source: CGPoint, to destination: CGPoint) {
            drags.append((source, destination))
        }
    }

    private final class StubSeparator: SeparatorControlling {
        let stubFrame: CGRect?
        init(frame: CGRect?) { stubFrame = frame }
        func expand() {}
        func collapse() {}
        var frame: CGRect? { stubFrame }
    }

    private func makeHider(_ locator: SpyLocator, _ relocator: SpyRelocator, _ separator: StubSeparator) -> SynthesizedMenuBarHider {
        SynthesizedMenuBarHider(locator: locator, relocator: relocator, separator: separator)
    }

    @Test func moveToHiddenDragsItemToLeftOfSeparator() {
        let sepFrame = CGRect(x: 500, y: 0, width: 1, height: 24)
        let itemFrame = CGRect(x: 100, y: 0, width: 30, height: 24)
        let relocator = SpyRelocator()
        makeHider(SpyLocator(["a": itemFrame]), relocator, StubSeparator(frame: sepFrame)).moveToHidden(id: "a")

        #expect(relocator.drags.count == 1)
        #expect(relocator.drags[0].from == CGPoint(x: itemFrame.midX, y: itemFrame.midY))
        #expect(relocator.drags[0].to == MenuBarItemDragGeometry.dropPoint(leftOf: sepFrame))
    }

    @Test func moveToVisibleDragsItemToRightOfSeparator() {
        let sepFrame = CGRect(x: 500, y: 0, width: 1, height: 24)
        let itemFrame = CGRect(x: 100, y: 0, width: 30, height: 24)
        let relocator = SpyRelocator()
        makeHider(SpyLocator(["a": itemFrame]), relocator, StubSeparator(frame: sepFrame)).moveToVisible(id: "a")

        #expect(relocator.drags.count == 1)
        #expect(relocator.drags[0].to == MenuBarItemDragGeometry.dropPoint(rightOf: sepFrame))
    }

    @Test func positionSeparatorDragsSeparatorLeftOfTheLeftmostVisibleItem() {
        let sepFrame = CGRect(x: 900, y: 0, width: 1, height: 24)
        let a = CGRect(x: 300, y: 0, width: 30, height: 24)
        let b = CGRect(x: 100, y: 0, width: 30, height: 24)   // leftmost
        let c = CGRect(x: 500, y: 0, width: 30, height: 24)
        let relocator = SpyRelocator()
        makeHider(SpyLocator(["a": a, "b": b, "c": c]), relocator, StubSeparator(frame: sepFrame))
            .positionSeparator(leftOfLeftmostOf: ["a", "b", "c"])

        #expect(relocator.drags.count == 1)
        #expect(relocator.drags[0].from == CGPoint(x: sepFrame.midX, y: sepFrame.midY))
        #expect(relocator.drags[0].to == MenuBarItemDragGeometry.dropPoint(leftOf: b))
    }

    @Test func moveToHiddenIsNoOpWhenItemFrameUnreadable() {
        let relocator = SpyRelocator()
        makeHider(SpyLocator([:]), relocator, StubSeparator(frame: CGRect(x: 500, y: 0, width: 1, height: 24)))
            .moveToHidden(id: "missing")
        #expect(relocator.drags.isEmpty)
    }

    @Test func moveToHiddenIsNoOpWhenSeparatorFrameUnreadable() {
        let relocator = SpyRelocator()
        makeHider(SpyLocator(["a": CGRect(x: 100, y: 0, width: 30, height: 24)]), relocator, StubSeparator(frame: nil))
            .moveToHidden(id: "a")
        #expect(relocator.drags.isEmpty)
    }

    @Test func positionSeparatorIsNoOpWhenNoVisibleFramesReadable() {
        let relocator = SpyRelocator()
        makeHider(SpyLocator([:]), relocator, StubSeparator(frame: CGRect(x: 900, y: 0, width: 1, height: 24)))
            .positionSeparator(leftOfLeftmostOf: ["x", "y"])
        #expect(relocator.drags.isEmpty)
    }
}
