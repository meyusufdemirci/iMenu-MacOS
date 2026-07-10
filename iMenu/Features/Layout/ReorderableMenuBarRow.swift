//
//  ReorderableMenuBarRow.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A horizontal, drag-to-reorder row of menu bar items — a preview of the menu
/// bar itself, where each item can be dragged left or right to a new position.
/// Items are **trailing-aligned**, mirroring the real menu bar (which fills from
/// the right).
///
/// Uses first-class drag-and-drop (`draggable`/`dropDestination`) since SwiftUI's
/// `onMove` only reorders a vertical `List`. It stays presentation-only: it takes
/// the items and a move action via `init` and calls back with the dragged and
/// drop-target identifiers; the actual reordering and persistence live in the
/// store.
struct ReorderableMenuBarRow: View {

    /// The items to show, in their current order.
    let items: [MenuBarItemDescriptor]

    /// Called when the user drops `draggedID` onto `targetID`.
    let onMove: (_ draggedID: String, _ targetID: String) -> Void

    /// The item currently under the drag, used to draw an insertion indicator.
    @State private var dropTargetID: String?

    var body: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            ForEach(items) { item in
                MenuBarItemChip(
                    title: item.displayTitle,
                    systemSymbolName: item.systemSymbolName,
                    bundleIdentifier: item.bundleIdentifier
                )
                    .overlay(alignment: .leading) { insertionIndicator(for: item) }
                    .draggable(item.id)
                    .dropDestination(for: String.self) { droppedIDs, _ in
                        dropTargetID = nil
                        guard let draggedID = droppedIDs.first else { return false }
                        onMove(draggedID, item.id)
                        return true
                    } isTargeted: { isTargeted in
                        if isTargeted {
                            dropTargetID = item.id
                        } else if dropTargetID == item.id {
                            dropTargetID = nil
                        }
                    }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.snappy, value: items)
    }

    /// A thin accent bar shown at the leading edge of the chip being hovered, so
    /// the drop position is legible while dragging.
    @ViewBuilder
    private func insertionIndicator(for item: MenuBarItemDescriptor) -> some View {
        Capsule()
            .fill(.white)
            .frame(width: 3)
            .padding(.vertical, 2)
            .offset(x: -7)
            .opacity(dropTargetID == item.id ? 1 : 0)
    }
}

#Preview {
    let items = (try? SampleMenuBarLayoutProvider().fetchItems()) ?? []
    return ReorderableMenuBarRow(items: items) { _, _ in }
        .frame(width: 520)
        .padding()
}
