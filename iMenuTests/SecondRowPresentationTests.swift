//
//  SecondRowPresentationTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// `SecondRowPresentation` decides whether iMenu's second row belongs on screen:
/// only when the user has it enabled *and* there are items to show.
struct SecondRowPresentationTests {

    @Test func showsWhenEnabledAndHasItems() {
        #expect(SecondRowPresentation.shouldShow(automaticEnabled: true, itemCount: 3))
    }

    @Test func hiddenWhenDisabled() {
        #expect(SecondRowPresentation.shouldShow(automaticEnabled: false, itemCount: 3) == false)
    }

    @Test func hiddenWhenNoItems() {
        #expect(SecondRowPresentation.shouldShow(automaticEnabled: true, itemCount: 0) == false)
    }
}
