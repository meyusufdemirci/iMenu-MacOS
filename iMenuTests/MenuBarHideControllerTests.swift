//
//  MenuBarHideControllerTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `MenuBarHideController` is the brain of the menu-bar show/hide toggle: it holds the
/// `isHidden` state, persists it to an injected `UserDefaults`, and drives an injected
/// `SeparatorControlling` (expand to hide, collapse to show). These tests inject a spy
/// separator and a throwaway defaults domain, so they never create a real status item.
struct MenuBarHideControllerTests {

    /// Records the expand/collapse calls instead of resizing a real status item.
    private final class SpySeparator: SeparatorControlling {
        private(set) var expandCount = 0
        private(set) var collapseCount = 0
        func expand() { expandCount += 1 }
        func collapse() { collapseCount += 1 }
        var frame: CGRect? { nil }
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MenuBarHideControllerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func startsVisibleAndCollapsesTheSeparatorAtInit() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        #expect(controller.isHidden == false)
        #expect(spy.collapseCount == 1)   // restored (default) state applied at init
        #expect(spy.expandCount == 0)
    }

    @Test func toggleHidesAndExpandsTheSeparator() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        controller.toggle()
        #expect(controller.isHidden == true)
        #expect(spy.expandCount == 1)
    }

    @Test func toggleTwiceReturnsToVisible() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        controller.toggle()   // hide
        controller.toggle()   // show
        #expect(controller.isHidden == false)
        #expect(spy.expandCount == 1)
        #expect(spy.collapseCount == 2)   // init + second toggle
    }

    @Test func setHiddenPersistsAcrossControllers() {
        let defaults = makeDefaults()
        let first = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        first.setHidden(true)

        let restored = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        #expect(restored.isHidden == true)
    }

    @Test func restoredHiddenStateExpandsTheSeparatorAtInit() {
        let defaults = makeDefaults()
        let seed = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        seed.setHidden(true)

        let spy = SpySeparator()
        _ = MenuBarHideController(separator: spy, defaults: defaults)
        #expect(spy.expandCount == 1)     // restored "hidden" applied at init
        #expect(spy.collapseCount == 0)
    }

    @Test func setHiddenToTrueThenFalseTracksState() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        controller.setHidden(true)
        #expect(controller.isHidden == true)
        controller.setHidden(false)
        #expect(controller.isHidden == false)
    }
}
