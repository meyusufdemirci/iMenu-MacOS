//
//  AppNavigationTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// `AppNavigation` is the shared source of truth for which page the main window
/// shows. The menu bar routes through it, so these tests pin the contract the
/// UI relies on: it defaults to Layout and `show(_:)` moves the selection.
struct AppNavigationTests {

    @Test func defaultsToLayout() {
        #expect(AppNavigation().selection == .layout)
    }

    @Test func showRoutesToTheRequestedPage() {
        let navigation = AppNavigation()
        navigation.show(.about)
        #expect(navigation.selection == .about)
    }

    @Test func showRoutesBackToSettings() {
        let navigation = AppNavigation(selection: .about)
        navigation.show(.settings)
        #expect(navigation.selection == .settings)
    }

    @Test func launchLandsOnLayoutWhenAllPermissionsGranted() {
        #expect(AppNavigation.launchSelection(allPermissionsGranted: true) == .layout)
    }

    @Test func launchLandsOnPermissionsWhenAnyPermissionMissing() {
        #expect(AppNavigation.launchSelection(allPermissionsGranted: false) == .permissions)
    }
}
