//
//  LayoutView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The Layout page of the side menu.
///
/// Fetches the current menu bar items through its `LayoutStore` and splits them
/// into two sections you can **drag between**:
///
/// - **Visible** — items that stay in the system menu bar.
/// - **Hidden** — items iMenu surfaces in its second row below the menu bar.
///
/// Kept thin: it switches on the store's load state and delegates each section to
/// a `LayoutSectionView`, wiring the drops to the store's move actions; the
/// fetching, splitting, ordering, and persistence live in the store.
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

    /// The two drag-between sections and the explanatory footnotes, stacked and
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Layout.reorderHint)
                    Text(L10n.Layout.sampleNotice)
                }
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
