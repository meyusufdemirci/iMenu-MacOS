//
//  WindowActions.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Observation

/// A bridge for opening the main window from AppKit.
///
/// SwiftUI's `openWindow` is only reachable from a view's environment, but the menu-bar
/// control lives in AppKit (`MenuBarStatusItemController`). The SwiftUI layer captures
/// `openWindow` once (see the root view) and stores a closure here; the AppKit menu calls
/// it. Holding a closure — rather than the environment action directly — keeps AppKit code
/// free of any SwiftUI dependency.
@Observable
final class WindowActions {

    /// Routes the main window to `page` (when given), opens it, and activates the app.
    /// `nil` until the SwiftUI layer wires it up on first appearance.
    var open: ((SidebarItem?) -> Void)?
}
