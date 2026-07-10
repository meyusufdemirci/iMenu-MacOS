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
/// It's `@Observable` so the view reflects the current permission state, and it
/// reads/requests each permission through an **injected** authorizer so it's
/// unit-testable with stubs. Permissions can be toggled in System Settings while
/// iMenu runs, so the view calls `refresh()` when it appears and when the app is
/// reactivated.
@Observable
final class PermissionsStore {

    /// Whether iMenu currently has Accessibility permission.
    private(set) var accessibilityGranted: Bool

    /// Whether iMenu currently has Screen Recording permission.
    private(set) var screenRecordingGranted: Bool

    /// Whether **every** permission iMenu requires is granted. The window lands on
    /// the Permissions page at launch when this is `false`, otherwise on Layout.
    /// New permissions get `&&`-ed in here.
    var allGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    @ObservationIgnored private let accessibilityAuthorizer: AccessibilityAuthorizing
    @ObservationIgnored private let screenRecordingAuthorizer: ScreenRecordingAuthorizing

    /// - Parameters:
    ///   - accessibilityAuthorizer: Reads/requests Accessibility. Defaults to the
    ///     system authorizer; tests inject a stub.
    ///   - screenRecordingAuthorizer: Reads/requests Screen Recording. Defaults to
    ///     the system authorizer; tests inject a stub.
    init(
        accessibilityAuthorizer: AccessibilityAuthorizing = SystemAccessibilityAuthorizer(),
        screenRecordingAuthorizer: ScreenRecordingAuthorizing = SystemScreenRecordingAuthorizer()
    ) {
        self.accessibilityAuthorizer = accessibilityAuthorizer
        self.screenRecordingAuthorizer = screenRecordingAuthorizer
        self.accessibilityGranted = accessibilityAuthorizer.isAccessTrusted()
        self.screenRecordingGranted = screenRecordingAuthorizer.isScreenRecordingTrusted()
    }

    /// Re-reads the current permission state.
    func refresh() {
        let accessibility = accessibilityAuthorizer.isAccessTrusted()
        if accessibility != accessibilityGranted {
            accessibilityGranted = accessibility
            AppLogger.shared.info("Accessibility permission is now \(accessibility ? "granted" : "denied")", category: .permissions)
        }

        let screenRecording = screenRecordingAuthorizer.isScreenRecordingTrusted()
        if screenRecording != screenRecordingGranted {
            screenRecordingGranted = screenRecording
            AppLogger.shared.info("Screen Recording permission is now \(screenRecording ? "granted" : "denied")", category: .permissions)
        }
    }

    /// Prompts for Accessibility access and opens System Settings so the user can grant it.
    func requestAccess() {
        AppLogger.shared.info("Requested Accessibility permission", category: .permissions)
        accessibilityAuthorizer.requestAccess()
        accessibilityAuthorizer.openSystemSettings()
    }

    /// Prompts for Screen Recording access and opens System Settings so the user can grant it.
    func requestScreenRecordingAccess() {
        AppLogger.shared.info("Requested Screen Recording permission", category: .permissions)
        screenRecordingAuthorizer.requestAccess()
        screenRecordingAuthorizer.openSystemSettings()
    }
}
