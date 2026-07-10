//
//  SecondRowView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// iMenu's persistent **second row**: the menu bar items rendered as a bar
/// directly below the system menu bar, in the order set on the Layout page.
///
/// Presentation-only and deliberately thin. It reads the **shared** `LayoutStore`
/// — the very instance the Layout page reorders — so dragging an item there
/// re-renders this row immediately, because `LayoutStore` is `@Observable` and
/// both views observe the same `items`. No extra syncing is needed.
///
/// It shows every fetched item for now; overflow-only detection and
/// click-to-activate are separate, later concerns.
struct SecondRowView: View {

    /// The shared source of truth for the items and their order.
    let store: LayoutStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(store.items) { item in
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
