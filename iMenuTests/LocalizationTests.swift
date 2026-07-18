//
//  LocalizationTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// Localization is English-only for now, but strings must always flow
/// through `L10n` / `String(localized:)` so adding a language later is a
/// data change, not a code change.
struct LocalizationTests {

    @Test func homeStringsResolveToNonEmptyValues() {
        #expect(L10n.Home.title.isEmpty == false)
        #expect(L10n.Home.subtitle.isEmpty == false)
        #expect(L10n.Home.refresh.isEmpty == false)
    }

    @Test func homeTitleUsesTheEnglishSourceValue() {
        #expect(L10n.Home.title == "Welcome to iMenu")
    }

    @Test func errorStringsInterpolateTheirArguments() {
        #expect(L10n.Errors.notFound("Menu").contains("Menu"))
        #expect(L10n.Errors.invalidInput("email").contains("email"))
    }

    @Test func sidebarAndSettingsStringsResolveToNonEmptyValues() {
        #expect(L10n.App.name.isEmpty == false)
        #expect(L10n.Sidebar.settings.isEmpty == false)
        #expect(L10n.Sidebar.layout.isEmpty == false)
        #expect(L10n.Sidebar.about.isEmpty == false)
        #expect(L10n.Settings.generalSection.isEmpty == false)
        #expect(L10n.Settings.launchAtLogin.isEmpty == false)
        #expect(L10n.Settings.launchAtLoginDetail.isEmpty == false)
    }

    @Test func layoutStringsResolveToNonEmptyValues() {
        #expect(L10n.Layout.visibleSection.isEmpty == false)
        #expect(L10n.Layout.visibleSectionDetail.isEmpty == false)
        #expect(L10n.Layout.visibleEmpty.isEmpty == false)
        #expect(L10n.Layout.hiddenSection.isEmpty == false)
        #expect(L10n.Layout.hiddenSectionDetail.isEmpty == false)
        #expect(L10n.Layout.hiddenEmpty.isEmpty == false)
        #expect(L10n.Layout.reorderHint.isEmpty == false)
        #expect(L10n.Layout.loading.isEmpty == false)
        #expect(L10n.Layout.refresh.isEmpty == false)
        #expect(L10n.Layout.emptyTitle.isEmpty == false)
        #expect(L10n.Layout.emptyDescription.isEmpty == false)
    }

    @Test func permissionsStringsResolveToNonEmptyValues() {
        #expect(L10n.Permissions.accessibilitySection.isEmpty == false)
        #expect(L10n.Permissions.accessibility.isEmpty == false)
        #expect(L10n.Permissions.accessibilityDetail.isEmpty == false)
        #expect(L10n.Permissions.accessibilityFooter.isEmpty == false)
        #expect(L10n.Permissions.screenRecordingSection.isEmpty == false)
        #expect(L10n.Permissions.screenRecording.isEmpty == false)
        #expect(L10n.Permissions.screenRecordingDetail.isEmpty == false)
        #expect(L10n.Permissions.screenRecordingFooter.isEmpty == false)
        #expect(L10n.Permissions.granted.isEmpty == false)
        #expect(L10n.Permissions.notGranted.isEmpty == false)
        #expect(L10n.Permissions.openSystemSettings.isEmpty == false)
    }

    @Test func aboutStringsResolveToNonEmptyValues() {
        #expect(L10n.About.author.isEmpty == false)
        #expect(L10n.About.role.isEmpty == false)
        #expect(L10n.About.free.isEmpty == false)
        #expect(L10n.About.madeWithLove.isEmpty == false)
        #expect(L10n.About.linkedIn.isEmpty == false)
        #expect(L10n.About.x.isEmpty == false)
        #expect(L10n.About.github.isEmpty == false)
    }
}
