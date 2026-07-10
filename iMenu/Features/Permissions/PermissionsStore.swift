//
//  PermissionsStore.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Observation

/// The source of truth for the Permissions page.
///
/// It's `@Observable` so the view reflects the current Accessibility state, and
/// it reads/requests that state through an **injected** `AccessibilityAuthorizing`
/// so it's unit-testable with a stub. Accessibility can be toggled in System
/// Settings while iMenu runs, so the view calls `refresh()` when it appears and
/// when the app is reactivated.
@Observable
final class PermissionsStore {

    /// Whether iMenu currently has Accessibility permission.
    private(set) var accessibilityGranted: Bool

    /// Whether **every** permission iMenu requires is granted. The window lands on
    /// the Permissions page at launch when this is `false`, otherwise on Layout.
    /// (Accessibility is the only one today; new permissions get `&&`-ed in here.)
    var allGranted: Bool {
        accessibilityGranted
    }

    @ObservationIgnored private let authorizer: AccessibilityAuthorizing

    /// - Parameter authorizer: Reads/requests the permission. Defaults to the
    ///   system authorizer; tests inject a stub.
    init(authorizer: AccessibilityAuthorizing = SystemAccessibilityAuthorizer()) {
        self.authorizer = authorizer
        self.accessibilityGranted = authorizer.isAccessTrusted()
    }

    /// Re-reads the current permission state.
    func refresh() {
        let granted = authorizer.isAccessTrusted()
        if granted != accessibilityGranted {
            accessibilityGranted = granted
            AppLogger.shared.info("Accessibility permission is now \(granted ? "granted" : "denied")", category: .permissions)
        }
    }

    /// Prompts for access and opens System Settings so the user can grant it.
    func requestAccess() {
        AppLogger.shared.info("Requested Accessibility permission", category: .permissions)
        authorizer.requestAccess()
        authorizer.openSystemSettings()
    }
}
