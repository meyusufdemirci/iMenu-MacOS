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
/// two sections you can **drag between**:
///
/// - **Visible** — where every item starts.
/// - **Hidden** — where you can park items.
///
/// Reordering within **Visible** edits your real macOS menu bar (the store synthesizes
/// a ⌘-drag to move the real item); moving between **Visible** and **Hidden** only
/// regroups this local list. Kept thin: it switches on the store's load state and
/// delegates each section to a `LayoutSectionView`, wiring the drops to the store's
/// move actions.
struct LayoutView: View {

    /// The source of truth for the page's items, state, and reordering.
    let store: LayoutStore

    var body: some View {
        content
            .navigationTitle(L10n.Sidebar.layout)
            .toolbar {
                ToolbarItem {
                    Button {
                        // Re-sync to the real menu bar: adopt its current order and
                        // save it, rather than restoring the previously saved order.
                        store.refresh()
                    } label: {
                        Label(L10n.Layout.refresh, systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                AppLogger.shared.info("Layout screen appeared", category: .ui)
                // Re-fetch on every visit unless we already have items — so newly
                // granted Accessibility permission (from the Permissions page) is
                // reflected without a manual refresh.
                if store.state != .loaded {
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
            if store.visibleItems.isEmpty && store.hiddenItems.isEmpty {
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

    /// The two drag-between sections and the explanatory footnote, stacked and
    /// scrollable so both fit on smaller windows.
    private var loadedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LayoutSectionView(
                    title: L10n.Layout.visibleSection,
                    subtitle: L10n.Layout.visibleSectionDetail,
                    items: store.visibleItems,
                    emptyPrompt: L10n.Layout.visibleEmpty,
                    onDropOnItem: { store.move(id: $0, toPositionOf: $1) },
                    onDropAtEnd: { store.move(id: $0, toEndOf: .visible) }
                )

                LayoutSectionView(
                    title: L10n.Layout.hiddenSection,
                    subtitle: L10n.Layout.hiddenSectionDetail,
                    items: store.hiddenItems,
                    emptyPrompt: L10n.Layout.hiddenEmpty,
                    onDropOnItem: { store.move(id: $0, toPositionOf: $1) },
                    onDropAtEnd: { store.move(id: $0, toEndOf: .hidden) }
                )

                Text(L10n.Layout.reorderHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
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
    let store = LayoutStore(
        provider: SampleMenuBarLayoutProvider(),
        defaults: UserDefaults(suiteName: "preview.layout")!
    )
    store.load()
    return LayoutView(store: store)
        .frame(width: 480, height: 420)
}
