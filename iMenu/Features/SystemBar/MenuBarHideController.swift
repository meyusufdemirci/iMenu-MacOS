//
//  MenuBarHideController.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation
import Observation

/// The brain of the menu-bar show/hide toggle.
///
/// It's `@Observable` so the UI (and the AppKit toggle) can reflect `isHidden`, holds the
/// hide/show state, persists it to an **injected** `UserDefaults` so it survives relaunch,
/// and drives an **injected** `SeparatorControlling` — expanding the separator to hide the
/// items to its left, collapsing it to show them. The persisted state is re-applied at
/// `init`, so the menu bar comes back the way the user left it.
///
/// Toggling is intentionally cheap: it's only a length change on iMenu's own separator, so
/// it's instant and never moves the cursor. Positioning the separator relative to the
/// Hidden items (the fragile synthesized ⌘-drag) is a separate concern handled elsewhere.
@Observable
final class MenuBarHideController {

    /// Whether the Hidden items are currently hidden from the menu bar.
    private(set) var isHidden: Bool

    @ObservationIgnored private let separator: SeparatorControlling
    @ObservationIgnored private let defaults: UserDefaults

    /// - Parameters:
    ///   - separator: The owned separator this controller resizes. Tests inject a spy;
    ///     the app injects the live `StatusBarSeparator`.
    ///   - defaults: Where the hide/show state is persisted. Defaults to `.standard`;
    ///     tests inject an isolated suite.
    init(separator: SeparatorControlling, defaults: UserDefaults = .standard) {
        self.separator = separator
        self.defaults = defaults
        self.isHidden = defaults.object(forKey: Keys.isHidden) as? Bool ?? false
        // Restore the last state onto the real separator at launch.
        apply()
    }

    /// Flips between hidden and visible.
    func toggle() {
        setHidden(!isHidden)
    }

    /// Sets the hidden/visible state, persists it, and applies it to the separator.
    func setHidden(_ hidden: Bool) {
        isHidden = hidden
        defaults.set(hidden, forKey: Keys.isHidden)
        apply()
        AppLogger.shared.info("Menu bar hidden items \(hidden ? "hidden" : "shown")", category: .menuBar)
    }

    /// Drives the separator to match the current state.
    private func apply() {
        if isHidden {
            separator.expand()
        } else {
            separator.collapse()
        }
    }

    private enum Keys {
        static let isHidden = "menuBar.hidden"
    }
}
