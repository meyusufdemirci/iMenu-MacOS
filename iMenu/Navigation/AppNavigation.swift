//
//  AppNavigation.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Observation

/// Shared source of truth for which page the main window displays.
///
/// The window and the menu bar both bind to the same `AppNavigation`, so a
/// "Settings" or "About" click from the menu bar routes the already-open (or
/// about-to-open) window to that page. It's `@Observable` so the sidebar
/// selection stays in sync, and it holds **only** selection state — opening and
/// activating the window are AppKit side effects that live in the view layer,
/// keeping this type pure and unit-testable.
@Observable
final class AppNavigation {

    /// The page the main window should show. Layout is the default landing page
    /// and the sidebar's first item.
    var selection: SidebarItem

    /// - Parameter selection: The initially selected page. Defaults to Layout.
    init(selection: SidebarItem = .layout) {
        self.selection = selection
    }

    /// The page the window should land on at launch. Sends the user straight to
    /// **Permissions** when any required permission is still missing (so they can
    /// grant it), otherwise starts on **Layout**.
    ///
    /// - Parameter allPermissionsGranted: Whether every permission iMenu needs is
    ///   granted (see `PermissionsStore.allGranted`).
    static func launchSelection(allPermissionsGranted: Bool) -> SidebarItem {
        allPermissionsGranted ? .layout : .permissions
    }

    /// Route the main window to `page`. Call this *before* opening/activating the
    /// window so it appears already on the requested page.
    func show(_ page: SidebarItem) {
        selection = page
    }
}
