//
//  AccessibilityAuthorizing.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit
import ApplicationServices

/// Reads and requests the Accessibility permission iMenu needs to inspect other
/// apps' menu bar items.
///
/// Behind a protocol so `PermissionsStore` can be unit-tested with a stub instead
/// of touching the real system state.
protocol AccessibilityAuthorizing {
    /// Whether the app is currently trusted for Accessibility.
    func isAccessTrusted() -> Bool

    /// Prompts the system to request access (shows the standard dialog once).
    func requestAccess()

    /// Opens System Settings at the Accessibility pane.
    func openSystemSettings()
}

/// The production authorizer, backed by the Accessibility API and System Settings.
struct SystemAccessibilityAuthorizer: AccessibilityAuthorizing {

    func isAccessTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccess() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
