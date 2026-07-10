//
//  MenuBarLayoutTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// Pins the small contracts the Layout page relies on: a descriptor's display
/// title falls back to its owning app, and the sample provider hands back a
/// stable, uniquely-identified set of items to arrange.
struct MenuBarLayoutTests {

    @Test func displayTitleUsesTitleWhenPresent() {
        let item = MenuBarItemDescriptor(id: "x", title: "Wi-Fi", ownerName: "System", systemSymbolName: "wifi")
        #expect(item.displayTitle == "Wi-Fi")
    }

    @Test func displayTitleFallsBackToOwnerWhenTitleEmpty() {
        let item = MenuBarItemDescriptor(id: "x", title: "", ownerName: "System", systemSymbolName: nil)
        #expect(item.displayTitle == "System")
    }

    @Test func sampleProviderReturnsUniquelyIdentifiedItems() throws {
        let items = try SampleMenuBarLayoutProvider().fetchItems()
        #expect(items.isEmpty == false)
        #expect(Set(items.map(\.id)).count == items.count)
    }
}
