//
//  AboutView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The About page of the side menu.
///
/// Introduces the app and its author, links out to the author's profiles, and
/// notes that iMenu is free. Kept thin: it wires data and localization together
/// and delegates presentation to `CardView` and `SocialLinkButton`.
struct AboutView: View {
    private let links = SocialLink.developerLinks

    var body: some View {
        CardView {
            VStack(spacing: 20) {
                header

                VStack(spacing: 8) {
                    ForEach(links) { link in
                        SocialLinkButton(
                            title: link.title,
                            systemImage: link.systemImage,
                            url: link.url
                        )
                    }
                }

                Text(L10n.About.free)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Label(L10n.About.madeWithLove, systemImage: "heart.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.pink)
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: 320)
        .padding()
        .navigationTitle(L10n.Sidebar.about)
        .onAppear {
            AppLogger.shared.info("About screen appeared", category: .ui)
        }
    }

    /// App mark, name, and author attribution.
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text(L10n.App.name)
                .font(.title2.bold())

            VStack(spacing: 2) {
                Text(L10n.About.author)
                    .font(.subheadline.weight(.medium))
                Text(L10n.About.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AboutView()
}
