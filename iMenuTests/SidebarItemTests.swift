//
//  SidebarItemTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Testing
@testable import iMenu

/// The side menu is driven by `SidebarItem`. These tests pin the contract the
/// UI relies on: a stable ordering (Layout first), presentable metadata for
/// every page, and unique identities so `List` selection behaves.
struct SidebarItemTests {

    @Test func layoutIsTheFirstPage() {
        #expect(SidebarItem.allCases.first == .layout)
    }

    @Test func pagesAppearInTheExpectedOrder() {
        #expect(SidebarItem.allCases == [.layout, .permissions, .settings, .about])
    }

    @Test func everyItemHasATitleAndIcon() {
        for item in SidebarItem.allCases {
            #expect(item.title.isEmpty == false)
            #expect(item.systemImage.isEmpty == false)
        }
    }

    @Test func itemsAreUniquelyIdentified() {
        let ids = SidebarItem.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
