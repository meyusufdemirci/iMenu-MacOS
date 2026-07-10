//
//  AboutView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The About page of the side menu.
///
/// Composes reusable components (`CardView`, `PrimaryButton`) and demonstrates
/// the full error-handling loop — the canonical pattern for a screen: wire
/// data, localization, logging, and `AppError` together while delegating
/// presentation to components.
struct AboutView: View {
    @State private var statusMessage = L10n.Home.ready

    var body: some View {
        CardView {
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text(L10n.Home.title)
                    .font(.title2.bold())

                Text(L10n.Home.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                PrimaryButton(L10n.Home.refresh, systemImage: "arrow.clockwise") {
                    refresh()
                }
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

    /// Demonstrates the full error-handling loop: attempt work, and on failure
    /// log the `AppError` and surface its localized description to the user.
    private func refresh() {
        AppLogger.shared.info("Refresh tapped", category: .ui)
        do {
            try performRefresh()
            statusMessage = L10n.Home.refreshed
        } catch let error as AppError {
            AppLogger.shared.error(error, category: .ui)
            statusMessage = error.errorDescription ?? L10n.Errors.unknown
        } catch {
            AppLogger.shared.error(.unexpected(error.localizedDescription), category: .ui)
            statusMessage = L10n.Errors.unknown
        }
    }

    /// Placeholder for real work; currently always succeeds. Swap in the actual
    /// menu-loading logic here and throw `AppError` on failure.
    private func performRefresh() throws {
        // e.g. throw AppError.notFound(resource: "Menu")
    }
}

#Preview {
    AboutView()
}
