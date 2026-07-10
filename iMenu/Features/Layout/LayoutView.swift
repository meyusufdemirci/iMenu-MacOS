//
//  LayoutView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The Layout page of the side menu.
///
/// Fetches the current menu bar items through its `LayoutStore` and shows them in
/// a **horizontal row you can drag to reorder** — a preview of the menu bar, in
/// the order iMenu uses for its second row. Kept thin: it switches on the store's
/// load state and delegates the row to `ReorderableMenuBarRow`; the fetching,
/// ordering, and persistence live in the store.
struct LayoutView: View {

    /// The source of truth for the page's items, state, and reordering.
    let store: LayoutStore

    var body: some View {
        content
            .navigationTitle(L10n.Sidebar.layout)
            .toolbar {
                ToolbarItem {
                    Button {
                        store.load()
                    } label: {
                        Label(L10n.Layout.refresh, systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                AppLogger.shared.info("Layout screen appeared", category: .ui)
                if store.state == .idle {
                    store.load()
                }
            }
    }

    /// Routes the current load state to the right presentation.
    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView(L10n.Layout.loading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            errorView(error)

        case .loaded:
            if store.items.isEmpty {
                ContentUnavailableView(
                    L10n.Layout.emptyTitle,
                    systemImage: "menubar.rectangle",
                    description: Text(L10n.Layout.emptyDescription)
                )
            } else {
                loadedContent
            }
        }
    }

    /// The section title, the horizontal reorderable row, and the explanatory
    /// footnotes, laid out top-to-bottom.
    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Layout.itemsSection)
                .font(.headline)

            ReorderableMenuBarRow(items: store.items) { draggedID, targetID in
                store.move(id: draggedID, toPositionOf: targetID)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Layout.reorderHint)
                Text(L10n.Layout.sampleNotice)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// A failure state with the localized reason and a retry action.
    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label(error.errorDescription ?? L10n.Errors.unknown, systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.recoverySuggestion ?? L10n.Errors.recoveryGeneric)
        } actions: {
            Button(L10n.Layout.retry) { store.load() }
        }
    }
}

#Preview {
    let store = LayoutStore(defaults: UserDefaults(suiteName: "preview.layout")!)
    store.load()
    return LayoutView(store: store)
        .frame(width: 480, height: 420)
}
