//
//  WindowID.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// Stable identifiers for the app's windows.
///
/// The app has a single main `Window`; giving it a fixed id lets the menu bar
/// reopen and focus that one window via `openWindow(id:)` instead of spawning
/// duplicates.
enum WindowID {

    /// The one main window (side-menu split view).
    static let main = "main"
}
