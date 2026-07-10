//
//  iMenuApp.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

@main
struct iMenuApp: App {

    /// Shared page selection, owned here so it survives the window closing and
    /// reopening and stays in sync between the window and the menu bar.
    @State private var navigation = AppNavigation()

    /// Shared user preferences, owned here for the same reason.
    @State private var settings = SettingsStore()

    var body: some Scene {
        // A single main window (not a group) so the menu bar reopens and focuses
        // the one window instead of spawning duplicates.
        Window(L10n.App.name, id: WindowID.main) {
            MainView(navigation: navigation, settings: settings)
        }

        // The menu bar control: a persistent icon whose menu opens/routes the
        // window and can quit the app.
        MenuBarExtra(L10n.App.name, systemImage: "menubar.rectangle") {
            MenuBarContent(navigation: navigation)
        }
        .menuBarExtraStyle(.menu)
    }
}
