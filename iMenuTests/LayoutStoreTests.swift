//
//  LayoutStoreTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `LayoutStore` fetches the menu bar items from an injected provider and splits
/// them into two local sections — **Visible** and **Hidden**. The split only
/// organizes this list and never touches the real menu bar. The store exposes a
/// load state the UI switches on, lets items move within and between the sections,
/// and persists both the section assignment and the order to an injected
/// `UserDefaults`. These tests drive it with a stub provider and a throwaway
/// defaults domain, so they never touch Accessibility or `.standard`.
struct LayoutStoreTests {

    /// A provider whose result the test controls (success payload or failure).
    private struct StubProvider: MenuBarLayoutProviding {
        let result: Result<[MenuBarItemDescriptor], AppError>
        func fetchItems() throws -> [MenuBarItemDescriptor] { try result.get() }
    }

    /// A fresh, empty `UserDefaults` domain unique to each test.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "LayoutStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func item(_ id: String) -> MenuBarItemDescriptor {
        MenuBarItemDescriptor(id: id, title: id.capitalized, ownerName: "Test", systemSymbolName: nil, bundleIdentifier: nil)
    }

    private func store(_ items: [MenuBarItemDescriptor], defaults: UserDefaults) -> LayoutStore {
        LayoutStore(provider: StubProvider(result: .success(items)), defaults: defaults)
    }

    // MARK: - Loading & partition

    @Test func startsIdleWithNoItems() {
        let store = store([], defaults: makeDefaults())
        #expect(store.visibleItems.isEmpty)
        #expect(store.hiddenItems.isEmpty)
        #expect(store.state == .idle)
    }

    @Test func loadPutsEveryItemInVisibleByDefault() {
        let items = [item("a"), item("b"), item("c")]
        let store = store(items, defaults: makeDefaults())
        store.load()
        #expect(store.visibleItems == items)
        #expect(store.hiddenItems.isEmpty)
        #expect(store.state == .loaded)
    }

    @Test func loadSurfacesProviderFailureAsError() {
        let store = LayoutStore(
            provider: StubProvider(result: .failure(.permissionDenied)),
            defaults: makeDefaults()
        )
        store.load()
        #expect(store.visibleItems.isEmpty)
        #expect(store.hiddenItems.isEmpty)
        #expect(store.state == .failed(.permissionDenied))
    }

    // MARK: - Moving between sections

    @Test func moveToEndOfHiddenMovesItemAcrossSections() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "b", toEndOf: .hidden)
        #expect(store.visibleItems.map(\.id) == ["a", "c"])
        #expect(store.hiddenItems.map(\.id) == ["b"])
    }

    @Test func moveBackToVisibleReturnsItemToTheMenuBarSection() {
        let store = store([item("a"), item("b")], defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .hidden)   // visible: [b], hidden: [a]
        store.move(id: "a", toEndOf: .visible)  // visible: [b, a], hidden: []
        #expect(store.visibleItems.map(\.id) == ["b", "a"])
        #expect(store.hiddenItems.isEmpty)
    }

    @Test func moveToPositionCanCrossSectionsAndLandBeforeTarget() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "c", toEndOf: .hidden)   // visible: [a, b], hidden: [c]
        store.move(id: "a", toPositionOf: "c")  // a lands before c in hidden
        #expect(store.visibleItems.map(\.id) == ["b"])
        #expect(store.hiddenItems.map(\.id) == ["a", "c"])
    }

    // MARK: - Reordering within a section

    @Test func moveToPositionReordersWithinASectionBeforeTarget() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "a", toPositionOf: "c") // [a, b, c] → [b, a, c] (a before c)
        #expect(store.visibleItems.map(\.id) == ["b", "a", "c"])
        #expect(store.hiddenItems.isEmpty)
    }

    @Test func moveToPositionBackwardLandsBeforeTarget() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "c", toPositionOf: "a") // [a, b, c] → [c, a, b]
        #expect(store.visibleItems.map(\.id) == ["c", "a", "b"])
    }

    @Test func moveToEndOfSameSectionReorders() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "a", toEndOf: .visible) // [a, b, c] → [b, c, a]
        #expect(store.visibleItems.map(\.id) == ["b", "c", "a"])
    }

    // MARK: - No-ops

    @Test func moveToPositionIsNoOpForSameItem() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "b", toPositionOf: "b")
        #expect(store.visibleItems.map(\.id) == ["a", "b", "c"])
    }

    @Test func moveIgnoresUnknownIdentifiers() {
        let store = store([item("a"), item("b")], defaults: makeDefaults())
        store.load()
        store.move(id: "zzz", toPositionOf: "a")
        store.move(id: "zzz", toEndOf: .hidden)
        #expect(store.visibleItems.map(\.id) == ["a", "b"])
        #expect(store.hiddenItems.isEmpty)
    }

    // MARK: - Persistence

    @Test func sectionAssignmentAndOrderPersistAcrossStores() {
        let defaults = makeDefaults()
        let items = [item("a"), item("b"), item("c")]

        let first = store(items, defaults: defaults)
        first.load()
        first.move(id: "b", toEndOf: .hidden)  // visible: [a, c], hidden: [b]
        first.move(id: "c", toPositionOf: "a") // visible: [c, a], hidden: [b]

        // A new store over the same domain must restore both the split and the order.
        let reloaded = store(items, defaults: defaults)
        reloaded.load()
        #expect(reloaded.visibleItems.map(\.id) == ["c", "a"])
        #expect(reloaded.hiddenItems.map(\.id) == ["b"])
    }

    @Test func newItemsDefaultToVisibleAfterSavedOrder() {
        let defaults = makeDefaults()

        let first = store([item("a"), item("b")], defaults: defaults)
        first.load()
        first.move(id: "a", toEndOf: .hidden) // visible: [b], hidden: [a]

        // A later fetch that surfaces a brand-new item keeps the saved split and
        // appends the newcomer to Visible.
        let second = store([item("a"), item("b"), item("c")], defaults: defaults)
        second.load()
        #expect(second.visibleItems.map(\.id) == ["b", "c"])
        #expect(second.hiddenItems.map(\.id) == ["a"])
    }

    // MARK: - Refresh (re-sync to the real menu bar)

    @Test func refreshAdoptsRealMenuOrderOverSavedOrder() {
        let items = [item("a"), item("b"), item("c")]
        let store = store(items, defaults: makeDefaults())
        store.load()
        store.move(id: "c", toPositionOf: "a") // saved visible order: [c, a, b]
        #expect(store.visibleItems.map(\.id) == ["c", "a", "b"])

        store.refresh() // the real fetch order is [a, b, c]
        #expect(store.visibleItems.map(\.id) == ["a", "b", "c"])
        #expect(store.state == .loaded)
    }

    @Test func refreshPreservesTheHiddenSplit() {
        let items = [item("a"), item("b"), item("c")]
        let store = store(items, defaults: makeDefaults())
        store.load()
        store.move(id: "b", toEndOf: .hidden) // visible: [a, c], hidden: [b]

        store.refresh()
        #expect(store.visibleItems.map(\.id) == ["a", "c"])
        #expect(store.hiddenItems.map(\.id) == ["b"])
    }

    @Test func refreshPersistsTheRealOrderAcrossStores() {
        let defaults = makeDefaults()
        let items = [item("a"), item("b"), item("c")]

        let first = store(items, defaults: defaults)
        first.load()
        first.move(id: "c", toPositionOf: "a") // saved visible order: [c, a, b]
        first.refresh()                        // adopts the real order [a, b, c] and saves it

        // A new store over the same domain restores the refreshed (real) order,
        // proving refresh persisted it rather than the earlier manual order.
        let reloaded = store(items, defaults: defaults)
        reloaded.load()
        #expect(reloaded.visibleItems.map(\.id) == ["a", "b", "c"])
    }

    @Test func refreshRestoresSavedHiddenSplitAfterAFailedLoad() {
        let defaults = makeDefaults()
        let items = [item("a"), item("b"), item("c")]

        // Establish a saved split, then simulate a load that cleared the items
        // (e.g. permission was revoked) before regaining access on refresh.
        let seed = store(items, defaults: defaults)
        seed.load()
        seed.move(id: "b", toEndOf: .hidden) // saved split: hidden = [b]

        let store = self.store(items, defaults: defaults)
        // Refresh without a prior successful load must still honor the saved split.
        store.refresh()
        #expect(store.visibleItems.map(\.id) == ["a", "c"])
        #expect(store.hiddenItems.map(\.id) == ["b"])
    }

    @Test func refreshSurfacesProviderFailureAsError() {
        let store = LayoutStore(
            provider: StubProvider(result: .failure(.permissionDenied)),
            defaults: makeDefaults()
        )
        store.refresh()
        #expect(store.visibleItems.isEmpty)
        #expect(store.hiddenItems.isEmpty)
        #expect(store.state == .failed(.permissionDenied))
    }
}
