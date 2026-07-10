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
/// `SidebarItem`) and whose detail shows the selected page. Settings is the
/// first item and the default selection. Kept thin: it owns the shared
/// `SettingsStore`, drives selection, and routes to a page view — each page
/// composes its own components.
struct MainView: View {
    @State private var selection: SidebarItem = .settings
    @State private var settings = SettingsStore()

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
            .navigationTitle(L10n.App.name)
        } detail: {
            detail(for: selection)
        }
        .onAppear {
            AppLogger.shared.info("Main view appeared", category: .ui)
        }
    }

    /// Routes the current sidebar selection to its page view.
    @ViewBuilder
    private func detail(for item: SidebarItem) -> some View {
        switch item {
        case .settings:
            SettingsView(settings: settings)
        case .about:
            AboutView()
        }
    }
}

#Preview {
    MainView()
}
