//
//  SocialLink.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// One of the developer's external profile links shown on the About page.
///
/// A plain value type so the set of links is trivial to assert in tests. Like
/// `SidebarItem`, the display `title` is sourced from `L10n`, keeping the links
/// localizable while the `id` stays a stable, English-agnostic key.
struct SocialLink: Identifiable, Hashable {
    /// Stable identifier used for `ForEach` and in tests (never localized).
    let id: String
    /// Localized, human-readable label (also the accessibility label).
    let title: String
    /// SF Symbol shown alongside the title.
    let systemImage: String
    /// Destination opened when the link is tapped.
    let url: URL
}

extension SocialLink {
    /// The developer's public profiles, in display order. The single source of
    /// truth for the About page's links.
    static var developerLinks: [SocialLink] {
        [
            SocialLink(
                id: "linkedin",
                title: L10n.About.linkedIn,
                systemImage: "briefcase.fill",
                url: URL(string: "https://linkedin.com/in/meyusufdemirci")!
            ),
            SocialLink(
                id: "x",
                title: L10n.About.x,
                systemImage: "at",
                url: URL(string: "https://x.com/meyusufdemirci")!
            ),
            SocialLink(
                id: "github",
                title: L10n.About.github,
                systemImage: "chevron.left.forwardslash.chevron.right",
                url: URL(string: "https://github.com/meyusufdemirci")!
            )
        ]
    }
}
