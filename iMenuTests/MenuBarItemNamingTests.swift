//
//  MenuBarItemNamingTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `MenuBarItemNaming.resolveTitle` picks the best human-readable label for a menu
/// bar item from its raw Accessibility attributes: the item's own title, else its
/// accessibility description with any live status stripped — so Control Center
/// extras (whose title is empty) stop reading as a wall of identical owner names.
/// The expected strings mirror the real attributes captured from a live menu bar.
struct MenuBarItemNamingTests {

    // MARK: - Priority order

    @Test func prefersTitleWhenPresent() {
        let name = MenuBarItemNaming.resolveTitle(title: "Dropbox", description: "Syncing, 3 files")
        #expect(name == "Dropbox")
    }

    @Test func fallsBackToDescriptionWhenTitleEmpty() {
        let name = MenuBarItemNaming.resolveTitle(title: "", description: "Bluetooth")
        #expect(name == "Bluetooth")
    }

    @Test func returnsEmptyWhenNothingUsable() {
        #expect(MenuBarItemNaming.resolveTitle(title: nil, description: nil) == "")
        #expect(MenuBarItemNaming.resolveTitle(title: "", description: "") == "")
    }

    // MARK: - Stripping live status from the description

    @Test func stripsLiveStatusAfterFirstComma() {
        #expect(MenuBarItemNaming.resolveTitle(title: nil, description: "Wi-Fi, connected, 3 bars") == "Wi-Fi")
        #expect(MenuBarItemNaming.resolveTitle(title: nil, description: "Control Center, Screen Recording is in use") == "Control Center")
    }

    @Test func keepsDescriptionsWithoutAComma() {
        #expect(MenuBarItemNaming.resolveTitle(title: nil, description: "Battery") == "Battery")
        #expect(MenuBarItemNaming.resolveTitle(title: nil, description: "Audio and Video Controls") == "Audio and Video Controls")
    }

    // MARK: - Placeholder titles

    @Test func ignoresGenericPlaceholderTitles() {
        // DeepL titles its status item "StatusItem" — worse than falling back to the owner.
        #expect(MenuBarItemNaming.resolveTitle(title: "StatusItem", description: nil) == "")
        // A real description still wins over a placeholder title.
        #expect(MenuBarItemNaming.resolveTitle(title: "Item-0", description: "Now Playing") == "Now Playing")
    }

    // MARK: - Whitespace handling

    @Test func treatsWhitespaceOnlyValuesAsEmpty() {
        let name = MenuBarItemNaming.resolveTitle(title: "  \n ", description: " Battery ")
        #expect(name == "Battery")
    }

    @Test func trimsTheChosenValue() {
        let name = MenuBarItemNaming.resolveTitle(title: "  1Password  ", description: nil)
        #expect(name == "1Password")
    }
}
