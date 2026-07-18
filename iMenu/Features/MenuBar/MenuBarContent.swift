//
//  MenuBarContent.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI
import AppKit

/// The menu shown when the user clicks iMenu's menu bar icon.
///
/// Four actions: **Open** brings up the main window on its current page;
/// **Settings** and **About** open it routed to that page; **Quit** terminates
/// the app. Page routing goes through the shared `AppNavigation`; opening and
/// terminating are the only AppKit touches and are intentionally confined to this
/// view rather than the (unit-tested) navigation model.
struct MenuBarContent: View {

    /// Shared navigation state the menu routes the main window through.
    let navigation: AppNavigation

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(L10n.MenuBar.open) { openMainWindow() }
        Button(L10n.MenuBar.settings) { openMainWindow(to: .settings) }
        Button(L10n.MenuBar.about) { openMainWindow(to: .about) }

        Divider()

        Button(L10n.MenuBar.quit) { quit() }
            .keyboardShortcut("q")
    }

    /// Routes to `page` (when provided), opens the single main window, and brings
    /// the app to the foreground.
    private func openMainWindow(to page: SidebarItem? = nil) {
        if let page {
            navigation.show(page)
        }
        AppLogger.shared.info("Menu bar opened main window", category: .ui)
        openWindow(id: WindowID.main)
        NSApplication.shared.activate()
    }

    /// Quits the app entirely.
    private func quit() {
        AppLogger.shared.info("Menu bar quit requested", category: .lifecycle)
        NSApplication.shared.terminate(nil)
    }
}
