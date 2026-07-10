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
/// the app. Page routing goes through the shared `AppNavigation`; opening,
/// activating, and terminating are the only AppKit touches and are intentionally
/// confined to this view rather than the (unit-tested) navigation model.
struct MenuBarContent: View {

    /// Shared navigation state the menu routes the main window through.
    let navigation: AppNavigation

    /// DEBUG (milestones 0.5): the divider collapser, exposed here so the hide
    /// primitive can be toggled by hand while it's being validated on real
    /// hardware. Reliable click target even when the divider is collapsed. Removed
    /// once the mechanic is proven.
    let collapser: DividerMenuBarCollapser

    /// DEBUG (milestones 0.5): auto-places a chosen item past the divider via a
    /// synthesized ⌘-drag, exposed here to exercise per-item hiding on real hardware.
    /// Removed once the drag mechanic is proven.
    let placer: MenuBarItemPlacer

    /// DEBUG (milestones 0.5): the loaded items, so the auto-park trigger has real
    /// candidate ids to hand the placer.
    let layoutStore: LayoutStore

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(L10n.MenuBar.open) { openMainWindow() }
        Button(L10n.MenuBar.settings) { openMainWindow(to: .settings) }
        Button(L10n.MenuBar.about) { openMainWindow(to: .about) }

        Divider()

        // DEBUG (milestones 0.5): exercise the divider-collapse primitive by hand.
        Button(L10n.MenuBar.toggleHiddenZoneDebug) {
            collapser.setCollapsed(!collapser.isCollapsed)
        }

        // DEBUG (milestones 0.5): exercise the synthesized ⌘-drag by auto-parking the
        // rightmost item past the divider. Keep the divider expanded (uncollapsed)
        // first — a collapsed divider has no on-screen drop point.
        Button(L10n.MenuBar.autoParkItemDebug) {
            placer.debugParkRightmostItem(among: layoutStore.visibleItems.map(\.id))
        }

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
