//
//  MenuBarItemActivationTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// Clicking a tile in the second row must open the *real* menu bar item behind it
/// (PRD FR3 / US2). `LayoutStore` owns that action: it forwards the tapped item's
/// id to an injected `MenuBarItemActivating` (the Accessibility "press" lives
/// behind that protocol, so these tests drive the wiring with a spy and never
/// touch the live menu bar). Failures must be swallowed — a stale or unpressable
/// item just does nothing, it never crashes the row.
struct MenuBarItemActivationTests {

    /// Records the ids it's asked to activate; can be told to fail like a stale
    /// element would.
    private final class SpyActivator: MenuBarItemActivating {
        private(set) var activatedIDs: [String] = []
        var error: AppError?

        func activate(id: String) throws {
            activatedIDs.append(id)
            if let error { throw error }
        }
    }

    private struct StubProvider: MenuBarLayoutProviding {
        func fetchItems() throws -> [MenuBarItemDescriptor] { [] }
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MenuBarItemActivationTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func activateForwardsTheIdentifierToTheActivator() {
        let spy = SpyActivator()
        let store = LayoutStore(provider: StubProvider(), activator: spy, defaults: makeDefaults())
        store.activate(id: "com.acme.app#Status")
        #expect(spy.activatedIDs == ["com.acme.app#Status"])
    }

    @Test func activateSwallowsActivatorFailures() {
        let spy = SpyActivator()
        spy.error = .menuBarItemActivationFailed
        let store = LayoutStore(provider: StubProvider(), activator: spy, defaults: makeDefaults())
        // Must not throw or crash: it forwards the id, then absorbs the failure.
        store.activate(id: "x")
        #expect(spy.activatedIDs == ["x"])
    }

    @Test func activateIsANoOpWithoutAnActivator() {
        // Previews/sample stores inject no activator — activating must be a safe
        // no-op rather than a crash.
        let store = LayoutStore(provider: StubProvider(), defaults: makeDefaults())
        store.activate(id: "x")
    }
}
