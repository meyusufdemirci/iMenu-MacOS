//
//  SystemBarCollapseTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// Moving an item to Hidden must hide it from the *real* menu bar, and emptying
/// Hidden must bring everything back (milestones 0.5 path (a)). `LayoutStore` owns
/// that: whenever the Hidden set changes it tells an injected
/// `SystemMenuBarCollapsing` whether to collapse iMenu's divider. These tests drive
/// the wiring with a spy — the live `NSStatusItem` work lives behind the protocol
/// and rides with on-device validation, never touched here.
struct SystemBarCollapseTests {

    /// Records collapse toggles and reports the current state back, like the real
    /// collapser, so the store can avoid redundant work.
    private final class SpyCollapser: SystemMenuBarCollapsing {
        private(set) var calls: [Bool] = []
        private(set) var isCollapsed = false

        func setCollapsed(_ collapsed: Bool) {
            calls.append(collapsed)
            isCollapsed = collapsed
        }
    }

    private struct StubProvider: MenuBarLayoutProviding {
        let items: [MenuBarItemDescriptor]
        func fetchItems() throws -> [MenuBarItemDescriptor] { items }
    }

    /// A provider whose result can be flipped between loads, so a test can make a
    /// second fetch fail after a first one succeeded.
    private final class FlakyProvider: MenuBarLayoutProviding {
        var result: Result<[MenuBarItemDescriptor], AppError>
        init(_ result: Result<[MenuBarItemDescriptor], AppError>) { self.result = result }
        func fetchItems() throws -> [MenuBarItemDescriptor] { try result.get() }
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SystemBarCollapseTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func item(_ id: String) -> MenuBarItemDescriptor {
        MenuBarItemDescriptor(id: id, title: id, ownerName: "Test", systemSymbolName: nil, bundleIdentifier: nil)
    }

    private func store(_ items: [MenuBarItemDescriptor], collapser: SpyCollapser, defaults: UserDefaults) -> LayoutStore {
        LayoutStore(provider: StubProvider(items: items), collapser: collapser, defaults: defaults)
    }

    @Test func loadWithNothingHiddenLeavesTheBarExpanded() {
        let spy = SpyCollapser()
        let store = store([item("a"), item("b")], collapser: spy, defaults: makeDefaults())
        store.load()
        #expect(spy.isCollapsed == false)
    }

    @Test func movingAnItemToHiddenCollapsesTheRealBar() {
        let spy = SpyCollapser()
        let store = store([item("a"), item("b")], collapser: spy, defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .hidden)
        #expect(spy.isCollapsed == true)
    }

    @Test func emptyingHiddenRestoresTheRealBar() {
        let spy = SpyCollapser()
        let store = store([item("a"), item("b")], collapser: spy, defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .hidden)   // collapse
        store.move(id: "a", toEndOf: .visible)  // nothing hidden → restore
        #expect(spy.isCollapsed == false)
    }

    @Test func loadingASavedHiddenSetCollapsesImmediately() {
        let defaults = makeDefaults()
        // Arrange a saved split with one item Hidden.
        let first = store([item("a"), item("b")], collapser: SpyCollapser(), defaults: defaults)
        first.load()
        first.move(id: "b", toEndOf: .hidden)

        // A fresh store over the same domain must collapse as soon as it loads,
        // without any further edit.
        let spy = SpyCollapser()
        let reloaded = store([item("a"), item("b")], collapser: spy, defaults: defaults)
        reloaded.load()
        #expect(reloaded.hiddenItems.map(\.id) == ["b"])
        #expect(spy.isCollapsed == true)
    }

    @Test func aFailedReloadRestoresTheRealBar() {
        let spy = SpyCollapser()
        let provider = FlakyProvider(.success([item("a"), item("b")]))
        let store = LayoutStore(provider: provider, collapser: spy, defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .hidden)   // collapse: one item Hidden
        #expect(spy.isCollapsed == true)

        // A later read that fails must not leave items stranded off the bar.
        provider.result = .failure(.permissionDenied)
        store.load()
        #expect(spy.isCollapsed == false)
    }

    @Test func aStoreWithoutACollapserNeverTouchesTheBar() {
        // Previews and sample data inject no collapser; moving to Hidden must stay a
        // safe no-op rather than crashing.
        let store = LayoutStore(provider: StubProvider(items: [item("a")]), defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .hidden)
        #expect(store.hiddenItems.map(\.id) == ["a"])
    }
}
