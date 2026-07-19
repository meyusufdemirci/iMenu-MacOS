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

    @Test func initReadsPersistedStateWithoutTouchingTheSeparator() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        #expect(controller.isHidden == false)
        // Restoring the persisted state onto the real separator is deferred to
        // `applyPersistedState()`, so the app can wire the park-before-expand hook first.
        #expect(spy.collapseCount == 0)
        #expect(spy.expandCount == 0)
    }

    @Test func applyPersistedStateCollapsesWhenVisible() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        controller.applyPersistedState(hasHiddenItems: false)
        #expect(spy.collapseCount == 1)
        #expect(spy.expandCount == 0)
    }

    @Test func applyPersistedStateExpandsWhenHiddenWasPersisted() {
        let defaults = makeDefaults()
        let seed = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        seed.setHidden(true)

        let spy = SpySeparator()
        let restored = MenuBarHideController(separator: spy, defaults: defaults)
        restored.applyPersistedState(hasHiddenItems: true)
        #expect(spy.expandCount == 1)
        #expect(spy.collapseCount == 0)
    }

    @Test func applyPersistedStateRevertsToVisibleWhenNothingIsHidden() {
        let defaults = makeDefaults()
        let seed = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        seed.setHidden(true)

        // Restoring "hidden" with an empty Hidden section would blank real items the
        // user never chose to hide — the persisted state must be dropped instead.
        let spy = SpySeparator()
        let restored = MenuBarHideController(separator: spy, defaults: defaults)
        restored.applyPersistedState(hasHiddenItems: false)

        #expect(restored.isHidden == false)
        #expect(spy.expandCount == 0)
        #expect(spy.collapseCount == 1)
        // The drop is persisted, so the next launch starts visible too.
        let next = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        #expect(next.isHidden == false)
    }

    @Test func willExpandRunsBeforeEveryExpand() {
        let spy = SpySeparator()
        let controller = MenuBarHideController(separator: spy, defaults: makeDefaults())
        var willExpandCalls = 0
        var expandsSeenAtWillExpand: [Int] = []
        controller.willExpand = {
            willExpandCalls += 1
            expandsSeenAtWillExpand.append(spy.expandCount)
            return true
        }

        controller.setHidden(true)    // first expand
        controller.setHidden(false)
        controller.setHidden(true)    // second expand

        #expect(willExpandCalls == 2)
        // Each time, the hook ran before the separator actually expanded.
        #expect(expandsSeenAtWillExpand == [0, 1])
        #expect(spy.expandCount == 2)
    }

    @Test func setHiddenAbortsAndRevertsWhenPreparationFails() {
        let spy = SpySeparator()
        let defaults = makeDefaults()
        let controller = MenuBarHideController(separator: spy, defaults: defaults)
        controller.willExpand = { false }

        controller.setHidden(true)

        // Expanding an unprepared divider would swallow the visible items too, so the
        // hide is aborted and the state reverts to visible.
        #expect(controller.isHidden == false)
        #expect(spy.expandCount == 0)
        // The reverted state is also what's persisted, so a relaunch doesn't retry
        // the aborted hide.
        let restored = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        #expect(restored.isHidden == false)
    }

    @Test func applyPersistedStateAbortsWhenPreparationFails() {
        let defaults = makeDefaults()
        let seed = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        seed.willExpand = { true }
        seed.setHidden(true)

        let spy = SpySeparator()
        let restored = MenuBarHideController(separator: spy, defaults: defaults)
        restored.willExpand = { false }
        restored.applyPersistedState(hasHiddenItems: true)

        #expect(restored.isHidden == false)
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
        #expect(spy.collapseCount == 1)   // the second toggle
    }

    @Test func setHiddenPersistsAcrossControllers() {
        let defaults = makeDefaults()
        let first = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        first.setHidden(true)

        let restored = MenuBarHideController(separator: SpySeparator(), defaults: defaults)
        #expect(restored.isHidden == true)
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
