//
//  SynthesizedMenuBarHider.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import CoreGraphics

/// The live `MenuBarHiding`: moves a real menu bar item to the correct side of the
/// separator — or parks the separator — by synthesizing a ⌘-drag.
///
/// It stitches the seams together: it reads where the item (or the separator) sits *right
/// now* (`MenuBarItemLocating` / `SeparatorControlling.frame`, re-read live because
/// positions shift as items move), asks `MenuBarItemDragGeometry` for the drop point just
/// past the separator's edge, and hands the source→destination drag to
/// `MenuBarItemRelocating`. Because it depends only on those injected seams and the pure
/// geometry, its logic is unit-testable with spies; the live AX read and CGEvent post
/// behind the seams are what ride with on-device validation.
///
/// Best-effort throughout: if a needed position can't be read, it logs and does nothing
/// rather than dragging to a wrong place.
final class SynthesizedMenuBarHider: MenuBarHiding {

    private let locator: MenuBarItemLocating
    private let relocator: MenuBarItemRelocating
    private let separator: SeparatorControlling

    init(locator: MenuBarItemLocating, relocator: MenuBarItemRelocating, separator: SeparatorControlling) {
        self.locator = locator
        self.relocator = relocator
        self.separator = separator
    }

    func moveToHidden(id: String) {
        guard let itemFrame = locator.frame(of: id), let separatorFrame = separator.frame else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return
        }
        let source = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
        relocator.dragItem(from: source, to: MenuBarItemDragGeometry.dropPoint(leftOf: separatorFrame))
        AppLogger.shared.info("Hid a real menu bar item", category: .menuBar)
    }

    func moveToVisible(id: String) {
        guard let itemFrame = locator.frame(of: id), let separatorFrame = separator.frame else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return
        }
        let source = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
        relocator.dragItem(from: source, to: MenuBarItemDragGeometry.dropPoint(rightOf: separatorFrame))
        AppLogger.shared.info("Showed a real menu bar item", category: .menuBar)
    }

    func positionSeparator(leftOfLeftmostOf visibleIDs: [String]) -> Bool {
        guard let separatorFrame = separator.frame else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return false
        }
        // The leftmost visible item is the boundary: dropping the separator just left of
        // it puts every visible item to the separator's right.
        guard let leftmost = visibleIDs.compactMap({ locator.frame(of: $0) }).min(by: { $0.minX < $1.minX }) else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return false
        }
        let source = CGPoint(x: separatorFrame.midX, y: separatorFrame.midY)
        relocator.dragItem(from: source, to: MenuBarItemDragGeometry.dropPoint(leftOf: leftmost))
        AppLogger.shared.info("Parked the menu bar separator left of the visible items", category: .menuBar)
        return true
    }
}
