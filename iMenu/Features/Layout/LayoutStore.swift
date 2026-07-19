//
//  LayoutStore.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Observation

/// The source of truth for the Layout page.
///
/// It's `@Observable` so the view reacts to load state and edits, fetches items
/// through an **injected** `MenuBarLayoutProviding` (so tests use a stub), and
/// splits them into two sections:
///
/// - **Visible** — where every fetched item starts.
/// - **Hidden** — where the user can park items.
///
/// Reordering an item **within Visible** edits the real macOS menu bar: the store hands
/// the move to an **injected** `MenuBarItemReordering`, which synthesizes a ⌘-drag to
/// physically relocate the real item next to its new neighbor (best-effort — some system
/// items can't be moved). Moving an item **between Visible and Hidden** also drives the
/// real bar, through an **injected** `MenuBarHiding`: the item is dragged to the hidden
/// side of iMenu's separator (or back to the visible side), so the menu bar toggle can
/// push the hidden ones off-screen. Both effects are best-effort and unproven items are
/// simply left in place.
///
/// Both the section assignment and the order are persisted to an **injected**
/// `UserDefaults`. The saved arrangement is the durable *intent*: it's applied on every
/// `load()`, so an item keeps its section and place across launches. Items that appear
/// later default to **Visible** and are appended after the ones already arranged.
/// `refresh()` goes the other way — it re-adopts the real menu bar's current order and
/// saves that as the new arrangement.
@Observable
final class LayoutStore {

    /// What the Layout page is currently showing.
    nonisolated enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(AppError)
    }

    /// One of the two Layout sections an item can live in.
    nonisolated enum Section: Equatable, Sendable {
        case visible
        case hidden
    }

    /// Items in the Visible section, in the user's chosen order.
    private(set) var visibleItems: [MenuBarItemDescriptor] = []

    /// Items in the Hidden section, in the user's chosen order.
    private(set) var hiddenItems: [MenuBarItemDescriptor] = []

    /// The current load state the view switches on.
    private(set) var state: LoadState = .idle

    @ObservationIgnored private let provider: MenuBarLayoutProviding
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let reorderer: MenuBarItemReordering
    @ObservationIgnored private var hider: MenuBarHiding

    /// Whether the separator has been parked left of the visible items yet this session.
    /// Done once, on the first hide, so the default arrangement is "everything visible".
    @ObservationIgnored private var didParkSeparator = false

    /// - Parameters:
    ///   - provider: Where items come from. Defaults to the real Accessibility
    ///     provider; previews use the sample provider and tests inject a stub.
    ///   - defaults: Where the chosen split/order is persisted. Defaults to
    ///     `.standard`; tests inject an isolated suite.
    ///   - reorderer: Applies a Visible reorder to the real menu bar. Defaults to a
    ///     synthesized ⌘-drag when the provider can locate live items (the real
    ///     Accessibility provider); otherwise a no-op, so a store over sample/stub data
    ///     stays a purely local list. Tests inject a spy.
    ///   - hider: Applies a Visible↔Hidden move to the real menu bar (dragging the item
    ///     across the separator). Defaults to a no-op; the app injects the live hider via
    ///     `attachHider(_:)` once the separator exists after launch. Tests inject a spy.
    init(
        provider: MenuBarLayoutProviding = AccessibilityMenuBarProvider(),
        defaults: UserDefaults = .standard,
        reorderer: MenuBarItemReordering? = nil,
        hider: MenuBarHiding = NullMenuBarHiding()
    ) {
        self.provider = provider
        self.defaults = defaults
        self.hider = hider
        if let reorderer {
            self.reorderer = reorderer
        } else if let locator = provider as? MenuBarItemLocating {
            self.reorderer = SynthesizedMenuBarItemReorderer(
                locator: locator,
                relocator: SynthesizedMenuBarItemRelocator()
            )
        } else {
            self.reorderer = NullMenuBarItemReordering()
        }
    }

    /// Injects the live `MenuBarHiding` after construction — used by the app, which can
    /// only build it once the menu bar separator exists (created after launch). Tests
    /// inject their spy through `init` instead.
    func attachHider(_ hider: MenuBarHiding) {
        self.hider = hider
    }

    /// Fetches the current items and applies the **saved** split and order, so the
    /// user's arrangement is restored. Used on appear, retry, and launch. Failures
    /// surface as an `AppError` in `state` and are logged; they never crash the
    /// page.
    func load() {
        fetch { fetched in
            applyPartition(to: fetched)
            AppLogger.shared.info("Loaded \(visibleItems.count + hiddenItems.count) menu bar items", category: .menuBar)
        }
    }

    /// Re-syncs to the real menu bar: fetches the current items, keeps the saved
    /// visible/hidden split, but **adopts the real menu bar's current left-to-right
    /// order** — discarding any previously saved manual order — and **persists** it.
    /// This is the refresh action: unlike `load()`, it makes the saved arrangement
    /// match how the items are actually ordered in the menu bar right now. Failures
    /// surface as an `AppError` in `state` and are logged; they never crash the page.
    func refresh() {
        fetch { fetched in
            adoptRealOrder(of: fetched)
            persist()
            AppLogger.shared.info("Refreshed \(visibleItems.count + hiddenItems.count) menu bar items from the real menu bar", category: .menuBar)
        }
    }

    /// Shared fetch + state-transition + error handling for `load()`/`refresh()`.
    /// On success runs `apply` (which arranges the sections and logs); on failure
    /// clears both sections, records the `AppError` in `state`, and logs it.
    private func fetch(_ apply: (_ fetched: [MenuBarItemDescriptor]) -> Void) {
        state = .loading
        do {
            let fetched = try provider.fetchItems()
            apply(fetched)
            state = .loaded
        } catch let error as AppError {
            visibleItems = []
            hiddenItems = []
            state = .failed(error)
            AppLogger.shared.error(error, category: .menuBar)
        } catch {
            let appError = AppError.unexpected(String(describing: error))
            visibleItems = []
            hiddenItems = []
            state = .failed(appError)
            AppLogger.shared.error(appError, category: .menuBar)
        }
    }

    // MARK: - Moving items

    /// Moves the item identified by `draggedID` so it lands **immediately before**
    /// `targetID`, in whichever section the target lives in — reordering within a
    /// section or moving across sections, depending on where the two items are.
    /// Unknown or identical ids are a no-op.
    func move(id draggedID: String, toPositionOf targetID: String) {
        guard draggedID != targetID,
              contains(draggedID),
              let targetSection = section(of: targetID)
        else { return }

        let sourceSection = section(of: draggedID)
        let visibleOrderBefore = visibleItems.map(\.id)

        // Validated above, so the removal always succeeds and the target — a
        // different id — is still present afterwards.
        guard let dragged = removeItem(draggedID) else { return }
        let targetIndex = index(of: targetID, in: targetSection) ?? self[targetSection].count
        insert(dragged, at: targetIndex, in: targetSection)
        persist()
        AppLogger.shared.info("Moved a menu bar item", category: .menuBar)

        applyRealEffect(movedID: draggedID, sourceSection: sourceSection, visibleOrderBefore: visibleOrderBefore)
    }

    /// Moves the item identified by `draggedID` to the **end** of `section` —
    /// used when dropping onto a section's empty area (including an empty section).
    /// If the item is already in that section it's moved to the end. Unknown ids
    /// are a no-op.
    func move(id draggedID: String, toEndOf section: Section) {
        let sourceSection = self.section(of: draggedID)
        let visibleOrderBefore = visibleItems.map(\.id)

        guard let dragged = removeItem(draggedID) else { return }
        append(dragged, to: section)
        persist()
        AppLogger.shared.info("Moved a menu bar item", category: .menuBar)

        applyRealEffect(movedID: draggedID, sourceSection: sourceSection, visibleOrderBefore: visibleOrderBefore)
    }

    // MARK: - Reflecting a move onto the real menu bar

    /// Routes a completed move to its real-menu-bar effect, based on where the item came
    /// from and where it landed:
    ///
    /// - **Visible → Visible** — a reorder: nudge the real item next to its new neighbor.
    /// - **Visible → Hidden** — a hide: park the separator (once) and drag the real item
    ///   to the separator's left, so a toggle pushes it off-screen.
    /// - **Hidden → Visible** — a show: drag the real item back to the separator's right.
    /// - **Hidden → Hidden** and unknown ids — left local; the real bar is untouched.
    private func applyRealEffect(movedID: String, sourceSection: Section?, visibleOrderBefore: [String]) {
        switch (sourceSection, section(of: movedID)) {
        case (.visible, .visible):
            applyVisibleReorderIfNeeded(movedID: movedID, visibleOrderBefore: visibleOrderBefore)
        case (.visible, .hidden):
            parkSeparatorIfNeeded()
            hider.moveToHidden(id: movedID)
        case (.hidden, .visible):
            hider.moveToVisible(id: movedID)
        default:
            break
        }
    }

    /// Mirrors a reorder **within the Visible section** onto the real menu bar by asking
    /// the `reorderer` to move the real item next to its new neighbor. Only fires when the
    /// Visible order actually changed.
    ///
    /// The move is expressed relative to the neighbor the item now sits beside: dropped
    /// **left of** the item now to its right, or — when it's become the rightmost Visible
    /// item — **right of** the item now to its left. A lone Visible item has no neighbor
    /// to anchor to, so nothing is moved.
    private func applyVisibleReorderIfNeeded(movedID: String, visibleOrderBefore: [String]) {
        guard visibleItems.map(\.id) != visibleOrderBefore else { return }
        guard let index = visibleItems.firstIndex(where: { $0.id == movedID }) else { return }

        if index + 1 < visibleItems.count {
            reorderer.move(id: movedID, to: .leftOf(visibleItems[index + 1].id))
        } else if index >= 1 {
            reorderer.move(id: movedID, to: .rightOf(visibleItems[index - 1].id))
        }
    }

    /// Parks the separator immediately left of the leftmost still-visible item, once per
    /// session — so before any hide the default is "everything visible" (all items to the
    /// separator's right), and hidden items then accumulate to its left.
    private func parkSeparatorIfNeeded() {
        guard didParkSeparator == false else { return }
        didParkSeparator = true
        hider.positionSeparator(leftOfLeftmostOf: visibleItems.map(\.id))
    }

    // MARK: - Persistence

    /// Persists both sections as ordered lists of item identifiers.
    private func persist() {
        defaults.set(visibleItems.map(\.id), forKey: Keys.visibleOrder)
        defaults.set(hiddenItems.map(\.id), forKey: Keys.hiddenOrder)
    }

    /// Splits `fetched` into the two sections using the saved assignment, ordering
    /// each section by its saved rank. Items whose id isn't in either saved list
    /// are newcomers: they default to **Visible** and keep their fetch order after
    /// everything already arranged.
    private func applyPartition(to fetched: [MenuBarItemDescriptor]) {
        let hiddenOrder = defaults.array(forKey: Keys.hiddenOrder) as? [String] ?? []
        let visibleOrder = defaults.array(forKey: Keys.visibleOrder) as? [String] ?? []
        let hiddenIDs = Set(hiddenOrder)

        var hidden: [MenuBarItemDescriptor] = []
        var visible: [MenuBarItemDescriptor] = []
        for item in fetched {
            if hiddenIDs.contains(item.id) {
                hidden.append(item)
            } else {
                visible.append(item)
            }
        }

        hiddenItems = ordered(hidden, by: hiddenOrder)
        visibleItems = ordered(visible, by: visibleOrder)
    }

    /// Splits `fetched` into the two sections using the **saved** visible/hidden
    /// assignment (read from persistence, so it survives a prior failed load that
    /// cleared the in-memory sections), but orders each section by the **fetch
    /// order** — i.e. the real menu bar's current left-to-right order — discarding
    /// any saved manual rank. Used by `refresh()` to re-sync to the live menu bar.
    private func adoptRealOrder(of fetched: [MenuBarItemDescriptor]) {
        let hiddenIDs = Set(defaults.array(forKey: Keys.hiddenOrder) as? [String] ?? [])

        var hidden: [MenuBarItemDescriptor] = []
        var visible: [MenuBarItemDescriptor] = []
        for item in fetched {
            if hiddenIDs.contains(item.id) {
                hidden.append(item)
            } else {
                visible.append(item)
            }
        }

        hiddenItems = hidden
        visibleItems = visible
    }

    /// Sorts `items` by `savedOrder`: known items by their saved rank, newcomers
    /// kept in fetch order after everything already arranged. The ordering is
    /// total (ties broken by fetch position), so the result is deterministic
    /// regardless of the sort's stability.
    private func ordered(_ items: [MenuBarItemDescriptor], by savedOrder: [String]) -> [MenuBarItemDescriptor] {
        guard savedOrder.isEmpty == false else { return items }

        var rank: [String: Int] = [:]
        for (index, id) in savedOrder.enumerated() where rank[id] == nil {
            rank[id] = index
        }

        return items.enumerated().sorted { lhs, rhs in
            switch (rank[lhs.element.id], rank[rhs.element.id]) {
            case let (left?, right?): return left < right   // both saved: by saved rank
            case (_?, nil): return true                     // saved before newcomer
            case (nil, _?): return false                    // newcomer after saved
            case (nil, nil): return lhs.offset < rhs.offset // both new: keep fetch order
            }
        }.map(\.element)
    }

    // MARK: - Section access

    /// The items in `section`.
    private subscript(section: Section) -> [MenuBarItemDescriptor] {
        switch section {
        case .visible: return visibleItems
        case .hidden: return hiddenItems
        }
    }

    private func contains(_ id: String) -> Bool {
        section(of: id) != nil
    }

    /// Which section, if any, currently holds the item with `id`.
    private func section(of id: String) -> Section? {
        if visibleItems.contains(where: { $0.id == id }) { return .visible }
        if hiddenItems.contains(where: { $0.id == id }) { return .hidden }
        return nil
    }

    private func index(of id: String, in section: Section) -> Int? {
        self[section].firstIndex(where: { $0.id == id })
    }

    /// Removes and returns the item with `id` from whichever section holds it.
    @discardableResult
    private func removeItem(_ id: String) -> MenuBarItemDescriptor? {
        if let index = visibleItems.firstIndex(where: { $0.id == id }) {
            return visibleItems.remove(at: index)
        }
        if let index = hiddenItems.firstIndex(where: { $0.id == id }) {
            return hiddenItems.remove(at: index)
        }
        return nil
    }

    private func insert(_ item: MenuBarItemDescriptor, at index: Int, in section: Section) {
        switch section {
        case .visible: visibleItems.insert(item, at: min(index, visibleItems.count))
        case .hidden: hiddenItems.insert(item, at: min(index, hiddenItems.count))
        }
    }

    private func append(_ item: MenuBarItemDescriptor, to section: Section) {
        switch section {
        case .visible: visibleItems.append(item)
        case .hidden: hiddenItems.append(item)
        }
    }

    private enum Keys {
        static let visibleOrder = "layout.visibleOrder"
        static let hiddenOrder = "layout.hiddenOrder"
    }
}
