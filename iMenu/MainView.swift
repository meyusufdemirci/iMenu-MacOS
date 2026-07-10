//
//  MainView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The main window.
///
/// A `NavigationSplitView` whose sidebar is the app's **side menu** (driven by
/// `SidebarItem`) and whose detail shows the selected page. Layout is the
/// first item and the default selection. Kept thin: it binds to the shared
/// `AppNavigation` and `SettingsStore` (owned by the app so they persist across
/// the window closing and stay in sync with the menu bar), drives selection,
/// and routes to a page view — each page composes its own components.
struct MainView: View {

    /// Shared page selection, also driven by the menu bar.
    @Bindable var navigation: AppNavigation

    /// Shared user preferences.
    let settings: SettingsStore

    /// Shared Layout state (menu bar items and their order).
    let layoutStore: LayoutStore

    /// Shared permission state (Accessibility).
    let permissionsStore: PermissionsStore

    /// Owns the second-row panel; started here so it's running once the app's UI
    /// is up. Its observation outlives this window, so a later window close/reopen
    /// leaves the row untouched (`start()` is idempotent).
    let secondRow: SecondRowController

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $navigation.selection) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
            .navigationTitle(L10n.App.name)
        } detail: {
            detail(for: navigation.selection)
        }
        .onAppear {
            AppLogger.shared.info("Main view appeared", category: .ui)
            secondRow.start()
        }
    }

    /// Routes the current sidebar selection to its page view.
    @ViewBuilder
    private func detail(for item: SidebarItem) -> some View {
        switch item {
        case .settings:
            SettingsView(settings: settings)
        case .layout:
            LayoutView(store: layoutStore)
        case .permissions:
            PermissionsView(store: permissionsStore)
        case .about:
            AboutView()
        }
    }
}

#Preview {
    let settings = SettingsStore()
    let layoutStore = LayoutStore()
    return MainView(
        navigation: AppNavigation(),
        settings: settings,
        layoutStore: layoutStore,
        permissionsStore: PermissionsStore(),
        secondRow: SecondRowController(store: layoutStore, settings: settings)
    )
}
