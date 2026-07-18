//
//  SettingsStore.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Observation

/// The single source of truth for user preferences.
///
/// It's `@Observable` so SwiftUI views update automatically, and it persists to
/// an **injected** `UserDefaults` so it can be unit-tested against a throwaway
/// domain (see `SettingsStoreTests`) instead of the shared `.standard` one.
///
/// Preferences here are stored today and honored by their features as those
/// features land (e.g. launch-at-login registration); the store stays the durable
/// home for the *intent* regardless.
@Observable
final class SettingsStore {

    /// Open iMenu automatically when the user logs in.
    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// - Parameter defaults: Where preferences are persisted. Defaults to
    ///   `.standard`; tests inject an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
    }

    /// Persistence keys, kept private so the storage layout is an implementation
    /// detail of the store.
    private enum Keys {
        static let launchAtLogin = "settings.launchAtLogin"
    }
}
