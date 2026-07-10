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
/// - **Visible** — items that stay in the system menu bar.
/// - **Hidden** — items iMenu surfaces in its persistent second row below the
///   menu bar.
///
/// Items can move within a section (reorder) or between sections (show/hide), and
/// both the section assignment and the order are persisted to an **injected**
/// `UserDefaults`. That saved split is the durable *intent*: it's applied on every
/// load, so an item keeps its section and place across launches. Items that appear
/// later default to **Visible** and are appended after the ones already arranged.
///
/// Note: the split set here is iMenu's own — it drives which items iMenu renders
/// in its second row; it does not (and cannot, via public API) rearrange or clip
/// the system menu bar itself.
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
        /// Stays in the system menu bar.
        case visible
        /// Surfaced in iMenu's second row.
        case hidden
    }

    /// Items that stay in the menu bar, in the user's chosen order.
    private(set) var visibleItems: [MenuBarItemDescriptor] = []

    /// Items surfaced in the second row, in the user's chosen order.
    private(set) var hiddenItems: [MenuBarItemDescriptor] = []

    /// The current load state the view switches on.
    private(set) var state: LoadState = .idle

    @ObservationIgnored private let provider: MenuBarLayoutProviding
    @ObservationIgnored private let defaults: UserDefaults

    /// - Parameters:
    ///   - provider: Where items come from. Defaults to the real Accessibility
    ///     provider; previews use the sample provider and tests inject a stub.
    ///   - defaults: Where the chosen split/order is persisted. Defaults to
    ///     `.standard`; tests inject an isolated suite.
    init(provider: MenuBarLayoutProviding = AccessibilityMenuBarProvider(), defaults: UserDefaults = .standard) {
        self.provider = provider
        self.defaults = defaults
    }

    /// Fetches the current items and applies the saved split and order. Failures
    /// surface as an `AppError` in `state` and are logged; they never crash the
    /// page.
    func load() {
        state = .loading
        do {
            let fetched = try provider.fetchItems()
            applyPartition(to: fetched)
            state = .loaded
            AppLogger.shared.info("Loaded \(visibleItems.count + hiddenItems.count) menu bar items", category: .menuBar)
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

        // Validated above, so the removal always succeeds and the target — a
        // different id — is still present afterwards.
        guard let dragged = removeItem(draggedID) else { return }
        let targetIndex = index(of: targetID, in: targetSection) ?? self[targetSection].count
        insert(dragged, at: targetIndex, in: targetSection)
        persist()
        AppLogger.shared.info("Moved a menu bar item", category: .menuBar)
    }

    /// Moves the item identified by `draggedID` to the **end** of `section` —
    /// used when dropping onto a section's empty area (including an empty section).
    /// If the item is already in that section it's moved to the end. Unknown ids
    /// are a no-op.
    func move(id draggedID: String, toEndOf section: Section) {
        guard let dragged = removeItem(draggedID) else { return }
        append(dragged, to: section)
        persist()
        AppLogger.shared.info("Moved a menu bar item", category: .menuBar)
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
