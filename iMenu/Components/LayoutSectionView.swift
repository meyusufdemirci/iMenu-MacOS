//
//  LayoutSectionView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// One section of the Layout page — a titled group (Visible or Hidden) with a
/// short description and its reorderable, drag-to-move row of menu bar items.
///
/// A thin, reusable wrapper: it lays out the header and count, and delegates the
/// row and its drop behavior to `ReorderableMenuBarRow`, passing the move actions
/// straight through. It's section-agnostic — the caller supplies the labels and
/// the closures, so the same view renders both Visible and Hidden.
struct LayoutSectionView: View {

    /// The section's heading (e.g. "Visible").
    let title: String

    /// A one-line explanation of what belonging to this section means.
    let subtitle: String

    /// The items in this section, in order.
    let items: [MenuBarItemDescriptor]

    /// Placeholder shown inside the row when the section is empty.
    let emptyPrompt: String

    /// Forwarded to the row: `draggedID` dropped onto chip `targetID` (insert before).
    let onDropOnItem: (_ draggedID: String, _ targetID: String) -> Void

    /// Forwarded to the row: `draggedID` dropped onto the trailing/empty area (append).
    let onDropAtEnd: (_ draggedID: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text("\(items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            ReorderableMenuBarRow(
                items: items,
                emptyPrompt: emptyPrompt,
                onDropOnItem: onDropOnItem,
                onDropAtEnd: onDropAtEnd
            )
        }
    }
}

#Preview {
    let items = (try? SampleMenuBarLayoutProvider().fetchItems()) ?? []
    return VStack(spacing: 20) {
        LayoutSectionView(
            title: "Visible",
            subtitle: "These stay in your menu bar.",
            items: items,
            emptyPrompt: "Drag items here to keep them in the menu bar.",
            onDropOnItem: { _, _ in },
            onDropAtEnd: { _ in }
        )
        LayoutSectionView(
            title: "Hidden",
            subtitle: "Items you’ve set aside here.",
            items: [],
            emptyPrompt: "Drag items here.",
            onDropOnItem: { _, _ in },
            onDropAtEnd: { _ in }
        )
    }
    .padding()
    .frame(width: 520)
}
