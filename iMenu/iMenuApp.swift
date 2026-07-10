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

    /// Shared Layout state (fetched menu bar items and their order), owned here so
    /// the loaded items survive the window closing and reopening.
    @State private var layoutStore = LayoutStore()

    var body: some Scene {
        // A single main window (not a group) so the menu bar reopens and focuses
        // the one window instead of spawning duplicates.
        Window(L10n.App.name, id: WindowID.main) {
            MainView(navigation: navigation, settings: settings, layoutStore: layoutStore)
        }

        // The menu bar control: a persistent icon whose menu opens/routes the
        // window and can quit the app.
        MenuBarExtra(L10n.App.name, systemImage: "menubar.rectangle") {
            MenuBarContent(navigation: navigation)
        }
        .menuBarExtraStyle(.menu)
    }
}
