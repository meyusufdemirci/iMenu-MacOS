//
//  MenuBarItemPlacer.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// Parks a chosen menu bar item to the **left** of iMenu's divider by synthesizing a
/// ⌘-drag — the per-item auto-placement that turns "move to Hidden" into hiding *that*
/// item, without the user dragging by hand (milestones 0.5 path (a)).
///
/// It's the coordinator that stitches the three seams together: it reads where the item
/// sits now (`MenuBarItemLocating`), reads where the divider sits (`dividerFrame`), asks
/// `MenuBarItemDragGeometry` for the drop point just left of the divider, and hands the
/// source→destination drag to `MenuBarItemRelocating`. Because it depends only on those
/// injected seams and the pure geometry, its logic is unit-testable with spies; the live
/// AX-reading and CGEvent-posting behind the seams are what ride with on-device
/// validation (milestone 0.9).
///
/// > The synthesized ⌘-drag itself is the milestone's remaining fragile unknown, so this
/// > is currently wired only to a **debug trigger** (`debugParkRightmostItem(among:)`),
/// > mirroring how the divider-collapse primitive was proven by hand before being trusted
/// > in `LayoutStore`. Once a synthesized drag is shown to reliably move real items, the
/// > Layout "move to Hidden" flow calls `park(id:)` directly.
///
/// Parking must happen while the divider is at its natural width (on-screen); a collapsed
/// divider is off-screen and has no valid drop point.
///
/// Main-actor: it drives status-item/`CGEvent` work whose callers are already on the main
/// actor.
@MainActor
final class MenuBarItemPlacer {

    private let locator: MenuBarItemLocating
    private let relocator: MenuBarItemRelocating

    /// Reads iMenu's divider's current frame; only its `minX` is used, as the anchor to
    /// drop items just to the left of. A closure so the placer stays decoupled from the
    /// `NSStatusItem`-owning collapser.
    private let dividerFrame: () -> CGRect?

    init(locator: MenuBarItemLocating,
         relocator: MenuBarItemRelocating,
         dividerFrame: @escaping () -> CGRect?) {
        self.locator = locator
        self.relocator = relocator
        self.dividerFrame = dividerFrame
    }

    /// Parks the item with `id` just left of the divider (into the hidden zone) by
    /// synthesizing a ⌘-drag from its current position. Best-effort: if the item's
    /// position or the divider can't be read, it logs and does nothing rather than
    /// dragging to a wrong place.
    func park(id: String) {
        guard let itemFrame = locator.frame(of: id) else {
            AppLogger.shared.error(AppError.menuBarItemPlacementFailed, category: .menuBar)
            return
        }
        guard let divider = dividerFrame() else {
            AppLogger.shared.error(AppError.menuBarItemPlacementFailed, category: .menuBar)
            return
        }

        let source = CGPoint(x: itemFrame.midX, y: itemFrame.midY)
        let destination = MenuBarItemDragGeometry.dropPoint(leftOfDividerMinX: divider.minX,
                                                            itemCenter: source)
        relocator.dragItem(from: source, to: destination)
        AppLogger.shared.info("Parked a menu bar item past the divider", category: .menuBar)
    }

    // MARK: - Debug

    /// DEBUG (milestones 0.5): parks the **rightmost item currently to the right of the
    /// divider** — the clearest, most-visible candidate to drag across — so the
    /// synthesized ⌘-drag can be exercised on real hardware. `ids` are the candidate
    /// item ids (the Layout page's known items); anything not to the right of the divider
    /// is skipped because it's already parked or unreadable. Removed once the mechanic is
    /// proven and `park(id:)` is wired into the real Layout flow.
    func debugParkRightmostItem(among ids: [String]) {
        guard let divider = dividerFrame() else {
            AppLogger.shared.error(AppError.menuBarItemPlacementFailed, category: .menuBar)
            return
        }

        let parkable = ids.compactMap { id -> (id: String, frame: CGRect)? in
            guard let frame = locator.frame(of: id), frame.minX > divider.minX else { return nil }
            return (id, frame)
        }
        guard let target = parkable.max(by: { $0.frame.midX < $1.frame.midX }) else {
            AppLogger.shared.info("Debug park: no item found to the right of the divider", category: .menuBar)
            return
        }

        AppLogger.shared.info(
            "Debug parking rightmost item at x=\(Int(target.frame.midX)) past divider x=\(Int(divider.minX))",
            category: .menuBar
        )
        park(id: target.id)
    }
}
