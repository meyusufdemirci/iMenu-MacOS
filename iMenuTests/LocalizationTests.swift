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
        #expect(L10n.Settings.showSecondRow.isEmpty == false)
        #expect(L10n.Settings.showSecondRowDetail.isEmpty == false)
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
