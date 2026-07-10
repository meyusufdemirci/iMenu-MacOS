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
}
