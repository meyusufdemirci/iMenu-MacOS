//
//  SocialLinkTests.swift
//  iMenuTests
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Testing
@testable import iMenu

/// `SocialLink.developerLinks` is the single source of truth for the profile
/// links shown on the About page. These tests pin the contract the UI relies
/// on: a stable set of well-formed `https` URLs, unique identities, and
/// presentable metadata for every link.
struct SocialLinkTests {

    @Test func exposesTheThreeDeveloperProfiles() {
        let ids = Set(SocialLink.developerLinks.map(\.id))
        #expect(ids == ["linkedin", "x", "github"])
    }

    @Test func everyLinkHasPresentableMetadata() {
        for link in SocialLink.developerLinks {
            #expect(link.title.isEmpty == false)
            #expect(link.systemImage.isEmpty == false)
        }
    }

    @Test func everyURLIsWellFormedHTTPS() {
        for link in SocialLink.developerLinks {
            #expect(link.url.scheme == "https")
            #expect(link.url.host?.isEmpty == false)
        }
    }

    @Test func linksPointAtTheExpectedProfiles() {
        let byID = Dictionary(
            uniqueKeysWithValues: SocialLink.developerLinks.map { ($0.id, $0.url.absoluteString) }
        )
        #expect(byID["linkedin"] == "https://linkedin.com/in/meyusufdemirci")
        #expect(byID["x"] == "https://x.com/meyusufdemirci")
        #expect(byID["github"] == "https://github.com/meyusufdemirci")
    }

    @Test func identitiesAreUnique() {
        let ids = SocialLink.developerLinks.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
