//
//  ScreenRecordingAuthorizing.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit
import CoreGraphics

/// Reads and requests the Screen Recording permission iMenu needs to capture how
/// other apps' menu bar items look, so it can mirror their icons in the second row.
///
/// Behind a protocol so `PermissionsStore` can be unit-tested with a stub instead
/// of touching the real system state.
protocol ScreenRecordingAuthorizing {
    /// Whether the app is currently trusted for Screen Recording.
    func isScreenRecordingTrusted() -> Bool

    /// Prompts the system to request access (shows the standard dialog once).
    func requestAccess()

    /// Opens System Settings at the Screen Recording pane.
    func openSystemSettings()
}

/// The production authorizer, backed by the Core Graphics screen-capture APIs and
/// System Settings.
struct SystemScreenRecordingAuthorizer: ScreenRecordingAuthorizing {

    func isScreenRecordingTrusted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestAccess() {
        _ = CGRequestScreenCaptureAccess()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
}
