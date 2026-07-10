//
//  LayoutStoreTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `LayoutStore` fetches the menu bar items from an injected provider, exposes a
/// load state the UI switches on, and persists the user's reordering to an
/// injected `UserDefaults`. These tests drive it with a stub provider and a
/// throwaway defaults domain, so they never touch Accessibility or `.standard`.
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

    @Test func startsIdleWithNoItems() {
        let store = store([], defaults: makeDefaults())
        #expect(store.items.isEmpty)
        #expect(store.state == .idle)
    }

    @Test func loadPopulatesItemsFromProvider() {
        let items = [item("a"), item("b"), item("c")]
        let store = store(items, defaults: makeDefaults())
        store.load()
        #expect(store.items == items)
        #expect(store.state == .loaded)
    }

    @Test func loadSurfacesProviderFailureAsError() {
        let store = LayoutStore(
            provider: StubProvider(result: .failure(.permissionDenied)),
            defaults: makeDefaults()
        )
        store.load()
        #expect(store.items.isEmpty)
        #expect(store.state == .failed(.permissionDenied))
    }

    @Test func moveReordersItems() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        #expect(store.items.map(\.id) == ["b", "c", "a"])
    }

    @Test func reorderIsPersistedAcrossStores() {
        let defaults = makeDefaults()
        let items = [item("a"), item("b"), item("c")]

        let first = store(items, defaults: defaults)
        first.load()
        first.move(fromOffsets: IndexSet(integer: 2), toOffset: 0) // c to front → [c, a, b]
        #expect(first.items.map(\.id) == ["c", "a", "b"])

        // A new store over the same domain must honor the saved order.
        let reloaded = store(items, defaults: defaults)
        reloaded.load()
        #expect(reloaded.items.map(\.id) == ["c", "a", "b"])
    }

    @Test func moveByIDPlacesItemAtTargetPositionForward() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "a", toPositionOf: "c")
        #expect(store.items.map(\.id) == ["b", "c", "a"])
    }

    @Test func moveByIDPlacesItemAtTargetPositionBackward() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "c", toPositionOf: "a")
        #expect(store.items.map(\.id) == ["c", "a", "b"])
    }

    @Test func moveByIDIsNoOpForSameItem() {
        let store = store([item("a"), item("b"), item("c")], defaults: makeDefaults())
        store.load()
        store.move(id: "b", toPositionOf: "b")
        #expect(store.items.map(\.id) == ["a", "b", "c"])
    }

    @Test func moveByIDIgnoresUnknownIdentifiers() {
        let store = store([item("a"), item("b")], defaults: makeDefaults())
        store.load()
        store.move(id: "zzz", toPositionOf: "a")
        #expect(store.items.map(\.id) == ["a", "b"])
    }

    @Test func moveByIDIsPersisted() {
        let defaults = makeDefaults()
        let items = [item("a"), item("b"), item("c")]

        let first = store(items, defaults: defaults)
        first.load()
        first.move(id: "c", toPositionOf: "a") // [c, a, b]

        let reloaded = store(items, defaults: defaults)
        reloaded.load()
        #expect(reloaded.items.map(\.id) == ["c", "a", "b"])
    }

    @Test func newItemsAppendAfterSavedOrder() {
        let defaults = makeDefaults()

        let first = store([item("a"), item("b")], defaults: defaults)
        first.load()
        first.move(fromOffsets: IndexSet(integer: 1), toOffset: 0) // [b, a]
        #expect(first.items.map(\.id) == ["b", "a"])

        // A later fetch that surfaces a brand-new item keeps the saved order and
        // appends the newcomer at the end.
        let second = store([item("a"), item("b"), item("c")], defaults: defaults)
        second.load()
        #expect(second.items.map(\.id) == ["b", "a", "c"])
    }
}
