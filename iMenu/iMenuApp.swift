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

    /// Shared Layout state (fetched menu bar items and their order), owned here so
    /// the loaded items survive the window closing and reopening.
    @State private var layoutStore: LayoutStore

    /// Shared permission state (Accessibility), owned here so it's re-checked and
    /// stays consistent across the window and the menu bar.
    @State private var permissionsStore: PermissionsStore

    /// Owns the second-row panel. It reads the *same* `layoutStore`/`settings`, so
    /// reordering on the Layout page updates the row live, and it lives on beyond
    /// the main window closing.
    @State private var secondRow: SecondRowController

    init() {
        // Land on Permissions at launch when any required permission is still
        // missing, so the user is taken straight to granting it; otherwise Layout.
        let permissionsStore = PermissionsStore()
        let settings = SettingsStore()
        // One Accessibility provider serves as both reader and activator: it keeps
        // the live elements it fetched, so a click on a second-row tile presses the
        // very item it read.
        let menuBarProvider = AccessibilityMenuBarProvider()
        let layoutStore = LayoutStore(provider: menuBarProvider, activator: menuBarProvider)

        _permissionsStore = State(initialValue: permissionsStore)
        _settings = State(initialValue: settings)
        _layoutStore = State(initialValue: layoutStore)
        _navigation = State(initialValue: AppNavigation(
            selection: AppNavigation.launchSelection(allPermissionsGranted: permissionsStore.allGranted)
        ))
        _secondRow = State(initialValue: SecondRowController(store: layoutStore, settings: settings))
    }

    var body: some Scene {
        // A single main window (not a group) so the menu bar reopens and focuses
        // the one window instead of spawning duplicates.
        Window(L10n.App.name, id: WindowID.main) {
            MainView(
                navigation: navigation,
                settings: settings,
                layoutStore: layoutStore,
                permissionsStore: permissionsStore,
                secondRow: secondRow
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
