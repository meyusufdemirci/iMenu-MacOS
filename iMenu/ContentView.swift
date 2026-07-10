//
//  ContentView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The home screen.
///
/// Deliberately thin: it *composes* reusable components (`CardView`,
/// `PrimaryButton`) and delegates strings to `L10n`, logging to `AppLogger`,
/// and failures to `AppError`. This is the pattern to follow for new screens.
struct ContentView: View {
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
        .onAppear {
            AppLogger.shared.info("Home screen appeared", category: .ui)
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
    ContentView()
}
