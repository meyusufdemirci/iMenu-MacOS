//
//  iMenuApp.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI
import AppKit

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

    /// The Accessibility provider, shared so the Layout store reads items through the
    /// same instance the hider locates their live positions through.
    @State private var provider: AccessibilityMenuBarProvider

    /// Bridge that lets the AppKit menu open/route the SwiftUI window.
    @State private var windowActions = WindowActions()

    /// Owns the menu bar chevron toggle, which doubles as the hidden/visible divider
    /// (replaces `MenuBarExtra`).
    @State private var menuBar = MenuBarStatusItemController()

    init() {
        // Land on Permissions at launch when any required permission is still
        // missing, so the user is taken straight to granting it; otherwise Layout.
        let permissionsStore = PermissionsStore()
        let settings = SettingsStore()
        // The Accessibility provider reads other apps' menu bar items and locates their
        // live positions; shared between the Layout store and the hider.
        let provider = AccessibilityMenuBarProvider()
        let layoutStore = LayoutStore(provider: provider)

        _permissionsStore = State(initialValue: permissionsStore)
        _settings = State(initialValue: settings)
        _provider = State(initialValue: provider)
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
            .modifier(WindowActionsBinder(actions: windowActions, navigation: navigation))
            // Create the menu bar status item once, after launch, when the status
            // bar is ready. `start` is idempotent, so re-appearance is a no-op.
            .task {
                let didStart = menuBar.start(menuActions: MenuBarStatusItemController.MenuActions(
                    open: { windowActions.open?(nil) },
                    openSettings: { windowActions.open?(.settings) },
                    openAbout: { windowActions.open?(.about) },
                    quit: { NSApplication.shared.terminate(nil) }
                ))
                // On the first start, let the Layout store drive hide/show on the same
                // chevron divider, locating items through the same provider it reads
                // them from.
                if didStart, let separator = menuBar.separator {
                    layoutStore.attachHider(SynthesizedMenuBarHider(
                        locator: provider,
                        relocator: SynthesizedMenuBarItemRelocator(),
                        separator: separator
                    ))
                    // Before any expand, park the divider at the hidden/visible
                    // boundary — a fresh item sits rightmost, where expanding would
                    // swallow the visible items too. Load first so the boundary is
                    // computable, then restore the persisted hide state through the
                    // same parking path.
                    menuBar.hideController?.willExpand = { layoutStore.prepareDividerForHiding() }
                    layoutStore.load()
                    menuBar.hideController?.applyPersistedState()
                }
            }
        }
    }
}

/// Captures SwiftUI's `openWindow` once the root view exists and hands it to
/// `WindowActions`, so the AppKit menu can open and route the window without any
/// SwiftUI dependency of its own.
private struct WindowActionsBinder: ViewModifier {

    let actions: WindowActions
    let navigation: AppNavigation

    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onAppear {
            actions.open = { page in
                if let page { navigation.show(page) }
                openWindow(id: WindowID.main)
                NSApplication.shared.activate()
            }
        }
    }
}
