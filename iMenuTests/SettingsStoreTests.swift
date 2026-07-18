//
//  SettingsStoreTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `SettingsStore` is the single source of truth for user preferences. It's
/// backed by an injected `UserDefaults`, so these tests use a throwaway suite
/// per store and never touch the real `.standard` domain.
struct SettingsStoreTests {

    /// A fresh, empty `UserDefaults` domain unique to each test.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "SettingsStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func launchAtLoginDefaultsToFalse() {
        let store = SettingsStore(defaults: makeDefaults())
        #expect(store.launchAtLogin == false)
    }

    @Test func changesArePersistedAcrossStores() {
        let defaults = makeDefaults()

        let store = SettingsStore(defaults: defaults)
        store.launchAtLogin = true

        // A new store over the same domain must observe the saved value.
        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.launchAtLogin == true)
    }
}
