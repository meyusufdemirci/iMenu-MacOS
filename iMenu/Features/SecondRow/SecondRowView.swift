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
/// It shows exactly the items the user has moved to Hidden; click-to-activate is a
/// separate, later concern.
struct SecondRowView: View {

    /// The shared source of truth for the hidden items and their order.
    let store: LayoutStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(store.hiddenItems) { item in
                MenuBarItemChip(
                    title: item.displayTitle,
                    systemSymbolName: item.systemSymbolName,
                    bundleIdentifier: item.bundleIdentifier,
                    // `.primary` so the fallback glyph adapts to light/dark like a
                    // real menu bar item, unlike the accent-backed Layout row.
                    fallbackColor: .primary
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(.bar, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .fixedSize()
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
