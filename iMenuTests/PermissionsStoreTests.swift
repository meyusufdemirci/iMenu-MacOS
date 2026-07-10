//
//  PermissionsStoreTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// `PermissionsStore` reflects the Accessibility and Screen Recording state read
/// through injected authorizers, re-reads them on `refresh()`, and routes a grant
/// request to the matching authorizer. These tests drive it with stubs so they
/// never touch the real system permissions or open System Settings.
struct PermissionsStoreTests {

    /// A controllable Accessibility authorizer that records what the store asked it to do.
    private final class StubAccessibilityAuthorizer: AccessibilityAuthorizing {
        var trusted: Bool
        private(set) var requestCount = 0
        private(set) var openSettingsCount = 0

        init(trusted: Bool) { self.trusted = trusted }

        func isAccessTrusted() -> Bool { trusted }
        func requestAccess() { requestCount += 1 }
        func openSystemSettings() { openSettingsCount += 1 }
    }

    /// A controllable Screen Recording authorizer that records what the store asked it to do.
    private final class StubScreenRecordingAuthorizer: ScreenRecordingAuthorizing {
        var trusted: Bool
        private(set) var requestCount = 0
        private(set) var openSettingsCount = 0

        init(trusted: Bool) { self.trusted = trusted }

        func isScreenRecordingTrusted() -> Bool { trusted }
        func requestAccess() { requestCount += 1 }
        func openSystemSettings() { openSettingsCount += 1 }
    }

    /// Builds a store wired to stubs with the given granted states.
    private func makeStore(
        accessibility: Bool,
        screenRecording: Bool
    ) -> (store: PermissionsStore, accessibility: StubAccessibilityAuthorizer, screenRecording: StubScreenRecordingAuthorizer) {
        let accessibilityAuthorizer = StubAccessibilityAuthorizer(trusted: accessibility)
        let screenRecordingAuthorizer = StubScreenRecordingAuthorizer(trusted: screenRecording)
        let store = PermissionsStore(
            accessibilityAuthorizer: accessibilityAuthorizer,
            screenRecordingAuthorizer: screenRecordingAuthorizer
        )
        return (store, accessibilityAuthorizer, screenRecordingAuthorizer)
    }

    @Test func readsInitialStateFromAuthorizers() {
        let granted = makeStore(accessibility: true, screenRecording: true).store
        #expect(granted.accessibilityGranted == true)
        #expect(granted.screenRecordingGranted == true)

        let denied = makeStore(accessibility: false, screenRecording: false).store
        #expect(denied.accessibilityGranted == false)
        #expect(denied.screenRecordingGranted == false)
    }

    @Test func allGrantedIsTrueOnlyWhenEveryPermissionIsGranted() {
        #expect(makeStore(accessibility: true, screenRecording: true).store.allGranted == true)
        #expect(makeStore(accessibility: true, screenRecording: false).store.allGranted == false)
        #expect(makeStore(accessibility: false, screenRecording: true).store.allGranted == false)
        #expect(makeStore(accessibility: false, screenRecording: false).store.allGranted == false)
    }

    @Test func refreshPicksUpAGrantedAccessibilityPermission() {
        let (store, accessibility, _) = makeStore(accessibility: false, screenRecording: true)
        #expect(store.accessibilityGranted == false)

        accessibility.trusted = true
        store.refresh()
        #expect(store.accessibilityGranted == true)
    }

    @Test func refreshPicksUpARevokedAccessibilityPermission() {
        let (store, accessibility, _) = makeStore(accessibility: true, screenRecording: true)

        accessibility.trusted = false
        store.refresh()
        #expect(store.accessibilityGranted == false)
    }

    @Test func refreshPicksUpAGrantedScreenRecordingPermission() {
        let (store, _, screenRecording) = makeStore(accessibility: true, screenRecording: false)
        #expect(store.screenRecordingGranted == false)

        screenRecording.trusted = true
        store.refresh()
        #expect(store.screenRecordingGranted == true)
    }

    @Test func refreshPicksUpARevokedScreenRecordingPermission() {
        let (store, _, screenRecording) = makeStore(accessibility: true, screenRecording: true)

        screenRecording.trusted = false
        store.refresh()
        #expect(store.screenRecordingGranted == false)
    }

    @Test func requestAccessPromptsAndOpensAccessibilitySettings() {
        let (store, accessibility, screenRecording) = makeStore(accessibility: false, screenRecording: false)

        store.requestAccess()

        #expect(accessibility.requestCount == 1)
        #expect(accessibility.openSettingsCount == 1)
        // The Accessibility request must not touch the Screen Recording authorizer.
        #expect(screenRecording.requestCount == 0)
        #expect(screenRecording.openSettingsCount == 0)
    }

    @Test func requestScreenRecordingAccessPromptsAndOpensScreenRecordingSettings() {
        let (store, accessibility, screenRecording) = makeStore(accessibility: false, screenRecording: false)

        store.requestScreenRecordingAccess()

        #expect(screenRecording.requestCount == 1)
        #expect(screenRecording.openSettingsCount == 1)
        // The Screen Recording request must not touch the Accessibility authorizer.
        #expect(accessibility.requestCount == 0)
        #expect(accessibility.openSettingsCount == 0)
    }
}
