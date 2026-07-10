//
//  PermissionsStoreTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// `PermissionsStore` reflects the Accessibility state read through an injected
/// authorizer, re-reads it on `refresh()`, and routes a grant request to the
/// authorizer. These tests drive it with a stub so they never touch the real
/// system permission or open System Settings.
struct PermissionsStoreTests {

    /// A controllable authorizer that records what the store asked it to do.
    private final class StubAuthorizer: AccessibilityAuthorizing {
        var trusted: Bool
        private(set) var requestCount = 0
        private(set) var openSettingsCount = 0

        init(trusted: Bool) { self.trusted = trusted }

        func isAccessTrusted() -> Bool { trusted }
        func requestAccess() { requestCount += 1 }
        func openSystemSettings() { openSettingsCount += 1 }
    }

    @Test func readsInitialStateFromAuthorizer() {
        #expect(PermissionsStore(authorizer: StubAuthorizer(trusted: true)).accessibilityGranted == true)
        #expect(PermissionsStore(authorizer: StubAuthorizer(trusted: false)).accessibilityGranted == false)
    }

    @Test func allGrantedIsTrueOnlyWhenEveryPermissionIsGranted() {
        #expect(PermissionsStore(authorizer: StubAuthorizer(trusted: true)).allGranted == true)
        #expect(PermissionsStore(authorizer: StubAuthorizer(trusted: false)).allGranted == false)
    }

    @Test func refreshPicksUpAGrantedPermission() {
        let authorizer = StubAuthorizer(trusted: false)
        let store = PermissionsStore(authorizer: authorizer)
        #expect(store.accessibilityGranted == false)

        authorizer.trusted = true
        store.refresh()
        #expect(store.accessibilityGranted == true)
    }

    @Test func refreshPicksUpARevokedPermission() {
        let authorizer = StubAuthorizer(trusted: true)
        let store = PermissionsStore(authorizer: authorizer)

        authorizer.trusted = false
        store.refresh()
        #expect(store.accessibilityGranted == false)
    }

    @Test func requestAccessPromptsAndOpensSettings() {
        let authorizer = StubAuthorizer(trusted: false)
        let store = PermissionsStore(authorizer: authorizer)

        store.requestAccess()

        #expect(authorizer.requestCount == 1)
        #expect(authorizer.openSettingsCount == 1)
    }
}
