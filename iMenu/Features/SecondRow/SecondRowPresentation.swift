//
//  SecondRowPresentation.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

/// Decides whether iMenu's second row belongs on screen.
///
/// Pure logic, split out from the AppKit `SecondRowController` so the show/hide
/// rule is unit tested on its own: the row appears only when the user has it
/// enabled *and* there are items to render (an empty bar would just be visual
/// noise under the menu bar).
enum SecondRowPresentation {

    /// - Parameters:
    ///   - automaticEnabled: The user's "show the second row automatically"
    ///     preference (`SettingsStore.showSecondRowAutomatically`).
    ///   - itemCount: How many menu bar items the store currently has.
    static func shouldShow(automaticEnabled: Bool, itemCount: Int) -> Bool {
        automaticEnabled && itemCount > 0
    }
}
