//
//  SynthesizedMenuBarItemReorderer.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The live `MenuBarItemReordering`: moves a real menu bar item next to a neighbor by
/// synthesizing a ⌘-drag — the coordinator that turns a Layout reorder into a real one.
///
/// It stitches the seams together: it reads where the item and its target neighbor sit
/// *right now* (`MenuBarItemLocating`, re-read live because positions shift as items
/// move), asks `MenuBarItemDragGeometry` for the drop point just past the neighbor's
/// edge, and hands the source→destination drag to `MenuBarItemRelocating`. Because it
/// depends only on those injected seams and the pure geometry, its logic is
/// unit-testable with spies; the live AX read and CGEvent post behind the seams are
/// what ride with on-device validation.
///
/// Best-effort throughout: if the item's or the neighbor's position can't be read, it
/// logs and does nothing rather than dragging to a wrong place — a stuck item never
/// disrupts the Layout page.
final class SynthesizedMenuBarItemReorderer: MenuBarItemReordering {

    private let locator: MenuBarItemLocating
    private let relocator: MenuBarItemRelocating

    init(locator: MenuBarItemLocating, relocator: MenuBarItemRelocating) {
        self.locator = locator
        self.relocator = relocator
    }

    func move(id: String, to side: MenuBarItemDropSide) {
        guard let itemFrame = locator.frame(of: id) else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return
        }
        guard let neighborFrame = locator.frame(of: side.referenceID) else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return
        }

        let source = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
        let destination: CGPoint
        switch side {
        case .leftOf:
            destination = MenuBarItemDragGeometry.dropPoint(leftOf: neighborFrame)
        case .rightOf:
            destination = MenuBarItemDragGeometry.dropPoint(rightOf: neighborFrame)
        }

        relocator.dragItem(from: source, to: destination)
        AppLogger.shared.info("Reordered a real menu bar item", category: .menuBar)
    }
}
