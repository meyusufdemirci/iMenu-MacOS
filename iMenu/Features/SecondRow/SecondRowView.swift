//
//  SecondRowView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// iMenu's persistent **second row**: the **Hidden** menu bar items rendered as a
/// bar directly below the system menu bar, in the order set on the Layout page.
///
/// Presentation-only and deliberately thin. It reads the **shared** `LayoutStore`
/// — the very instance the Layout page edits — so moving an item into (or out of)
/// the Hidden section, or reordering it, re-renders this row immediately, because
/// `LayoutStore` is `@Observable` and both views observe the same `hiddenItems`.
/// No extra syncing is needed.
///
/// Each tile is a button: clicking it asks the store to open the real menu bar
/// item behind it (PRD FR3 / US2). It shows exactly the items the user has moved
/// to Hidden.
struct SecondRowView: View {

    /// The shared source of truth for the hidden items, their order, and the
    /// activation action.
    let store: LayoutStore

    /// The tile under the cursor, used to hint that tiles are clickable.
    @State private var hoveredID: String?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(store.hiddenItems) { item in
                tile(for: item)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(.bar, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .fixedSize()
    }

    /// One clickable tile: pressing it opens the real menu bar item; hovering
    /// highlights it so the affordance reads on the otherwise flat row.
    private func tile(for item: MenuBarItemDescriptor) -> some View {
        Button {
            store.activate(id: item.id)
        } label: {
            MenuBarItemChip(
                title: item.displayTitle,
                systemSymbolName: item.systemSymbolName,
                bundleIdentifier: item.bundleIdentifier,
                // `.primary` so the fallback glyph adapts to light/dark like a
                // real menu bar item, unlike the accent-backed Layout row.
                fallbackColor: .primary
            )
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(hoveredID == item.id ? 0.12 : 0))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                hoveredID = item.id
            } else if hoveredID == item.id {
                hoveredID = nil
            }
        }
        .accessibilityHint(L10n.SecondRow.activateHint)
    }
}

#Preview {
    let store = LayoutStore(
        provider: SampleMenuBarLayoutProvider(),
        defaults: UserDefaults(suiteName: "preview.secondRow")!
    )
    store.load()
    return SecondRowView(store: store)
        .padding(40)
}
