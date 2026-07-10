//
//  SocialLinkButton.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A bordered button that opens an external link (e.g. a social profile).
///
/// Wraps SwiftUI's `Link` in one place so every outbound link shares the same
/// styling — restyle here and every link updates. Takes its data via `init`
/// and reads no global state.
struct SocialLinkButton: View {
    private let title: String
    private let systemImage: String
    private let url: URL

    init(title: String, systemImage: String, url: URL) {
        self.title = title
        self.systemImage = systemImage
        self.url = url
    }

    var body: some View {
        Link(destination: url) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(title)
    }
}

#Preview {
    SocialLinkButton(
        title: "GitHub",
        systemImage: "chevron.left.forwardslash.chevron.right",
        url: URL(string: "https://github.com/meyusufdemirci")!
    )
    .padding()
    .frame(width: 240)
}
