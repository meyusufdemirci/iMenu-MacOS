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
    @State private var navigation: AppNavigation

    /// Shared user preferences, owned here for the same reason.
    @State private var settings: SettingsStore

    /// Shared Layout state (the fetched menu bar items), owned here so the loaded
    /// items survive the window closing and reopening.
    @State private var layoutStore: LayoutStore

    /// Shared permission state (Accessibility + Screen Recording), owned here so
    /// it's re-checked and stays consistent across the window and the menu bar.
    @State private var permissionsStore: PermissionsStore

    init() {
        // Land on Permissions at launch when any required permission is still
        // missing, so the user is taken straight to granting it; otherwise Layout.
        let permissionsStore = PermissionsStore()
        let settings = SettingsStore()
        // The Accessibility provider only reads other apps' menu bar items — iMenu
        // shows them and never presses, moves, or hides them.
        let layoutStore = LayoutStore(provider: AccessibilityMenuBarProvider())

        _permissionsStore = State(initialValue: permissionsStore)
        _settings = State(initialValue: settings)
        _layoutStore = State(initialValue: layoutStore)
        _navigation = State(initialValue: AppNavigation(
            selection: AppNavigation.launchSelection(allPermissionsGranted: permissionsStore.allGranted)
        ))
    }

    var body: some Scene {
        // A single main window (not a group) so the menu bar reopens and focuses
        // the one window instead of spawning duplicates.
        Window(L10n.App.name, id: WindowID.main) {
            MainView(
                navigation: navigation,
                settings: settings,
                layoutStore: layoutStore,
                permissionsStore: permissionsStore
            )
        }

        // The menu bar control: a persistent icon whose menu opens/routes the
        // window and can quit the app.
        MenuBarExtra(L10n.App.name, systemImage: "menubar.rectangle") {
            MenuBarContent(navigation: navigation)
        }
        .menuBarExtraStyle(.menu)
    }
}
