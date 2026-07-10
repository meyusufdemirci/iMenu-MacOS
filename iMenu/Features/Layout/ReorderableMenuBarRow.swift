//
//  ReorderableMenuBarRow.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A horizontal, drag-and-drop row of menu bar items for one Layout section.
///
/// Items can be dragged **within** the row to reorder, or dragged **in from the
/// other section** to move here. Two drop targets make that unambiguous:
///
/// - Dropping onto a chip inserts the dragged item **immediately before** it
///   (shown by the leading-edge insertion indicator).
/// - Dropping onto the trailing empty area appends it to the **end** of the row —
///   this is also the whole drop target when the section is empty, where it shows
///   the `emptyPrompt` instead.
///
/// Uses first-class drag-and-drop (`draggable`/`dropDestination`) since SwiftUI's
/// `onMove` only reorders a vertical `List`. It stays presentation-only and
/// section-agnostic: it reports the dragged and drop-target identifiers back
/// through its closures, and the caller decides which section the move targets;
/// the actual reordering and persistence live in the store.
struct ReorderableMenuBarRow: View {

    /// The items to show, in their current order.
    let items: [MenuBarItemDescriptor]

    /// What to show when the section has no items — a hint to drag some in.
    let emptyPrompt: String

    /// Called when `draggedID` is dropped onto the chip `targetID` (insert before).
    let onDropOnItem: (_ draggedID: String, _ targetID: String) -> Void

    /// Called when `draggedID` is dropped onto the trailing/empty area (append).
    let onDropAtEnd: (_ draggedID: String) -> Void

    /// The chip currently under the drag, used to draw an insertion indicator.
    @State private var dropTargetID: String?

    /// Whether the trailing "append" area is currently under the drag.
    @State private var isEndTargeted = false

    /// The chip the cursor is hovering, used to reveal its name. The tiles are
    /// icon-only, so this is how you tell which app a tile belongs to.
    @State private var hoveredID: String?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                chip(for: item)
            }

            endDropArea
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(background)
        .animation(.snappy, value: items)
        .animation(.easeInOut(duration: 0.12), value: hoveredID)
    }

    /// One draggable menu bar tile: the icon chip, its leading insertion
    /// indicator, the drop target that inserts before it, and the hover-revealed
    /// name label. Extracted from `body` so the row stays cheap to type-check.
    @ViewBuilder
    private func chip(for item: MenuBarItemDescriptor) -> some View {
        MenuBarItemChip(
            title: item.displayTitle,
            systemSymbolName: item.systemSymbolName,
            bundleIdentifier: item.bundleIdentifier,
            // `.primary` so the fallback glyph reads on the neutral section
            // background, like a real menu bar item in light/dark.
            fallbackColor: .primary
        )
            .overlay(alignment: .leading) { insertionIndicator(for: item) }
            .draggable(item.id)
            .dropDestination(for: String.self) { droppedIDs, _ in
                dropTargetID = nil
                guard let draggedID = droppedIDs.first else { return false }
                onDropOnItem(draggedID, item.id)
                return true
            } isTargeted: { isTargeted in
                if isTargeted {
                    dropTargetID = item.id
                } else if dropTargetID == item.id {
                    dropTargetID = nil
                }
            }
            .onHover { hovering in
                if hovering {
                    hoveredID = item.id
                } else if hoveredID == item.id {
                    hoveredID = nil
                }
            }
            .overlay(alignment: .top) { nameTooltip(for: item) }
            // Lift the hovered chip so its tooltip draws over later siblings.
            .zIndex(hoveredID == item.id ? 1 : 0)
    }

    /// The flexible trailing region that fills the rest of the row so the whole
    /// empty space is a drop target for appending, and hosts the empty prompt when
    /// the section has no chips.
    private var endDropArea: some View {
        ZStack {
            if items.isEmpty {
                Text(emptyPrompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: items.isEmpty ? .center : .leading)
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { droppedIDs, _ in
            isEndTargeted = false
            guard let draggedID = droppedIDs.first else { return false }
            onDropAtEnd(draggedID)
            return true
        } isTargeted: { isEndTargeted = $0 }
    }

    /// The section's rounded container, highlighted while the trailing area (or an
    /// empty section) is being targeted for a drop.
    private var background: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.quaternary)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: isEndTargeted ? 2 : 0)
            }
    }

    /// A floating label with the item's name, revealed above the chip while the
    /// cursor rests on it — the tiles are icon-only, so this is how you identify
    /// one. Purely informational: it never intercepts the drag, and it stays
    /// hidden while a drag is over the row so it doesn't compete with the
    /// insertion indicator.
    @ViewBuilder
    private func nameTooltip(for item: MenuBarItemDescriptor) -> some View {
        let isDraggingOver = dropTargetID != nil || isEndTargeted
        Text(item.displayTitle)
            .font(.caption)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(.quaternary, lineWidth: 1) }
            .shadow(radius: 3, y: 1)
            .offset(y: -30)
            .opacity(hoveredID == item.id && !isDraggingOver ? 1 : 0)
            .allowsHitTesting(false)
    }

    /// A thin accent bar at the leading edge of the chip being hovered, so the
    /// drop position (insert before) is legible while dragging.
    @ViewBuilder
    private func insertionIndicator(for item: MenuBarItemDescriptor) -> some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 3)
            .padding(.vertical, 2)
            .offset(x: -7)
            .opacity(dropTargetID == item.id ? 1 : 0)
    }
}

#Preview("Populated") {
    let items = (try? SampleMenuBarLayoutProvider().fetchItems()) ?? []
    return ReorderableMenuBarRow(items: items, emptyPrompt: "Drag items here") { _, _ in } onDropAtEnd: { _ in }
        .frame(width: 520)
        .padding()
}

#Preview("Empty") {
    ReorderableMenuBarRow(items: [], emptyPrompt: "Drag items here to show them in the second row.") { _, _ in } onDropAtEnd: { _ in }
        .frame(width: 520)
        .padding()
}
