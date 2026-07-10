//
//  LayoutStore.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import Observation
import SwiftUI // for `Array.move(fromOffsets:toOffset:)`, matching the view's `.onMove`

/// The source of truth for the Layout page.
///
/// It's `@Observable` so the view reacts to load state and reordering, fetches
/// items through an **injected** `MenuBarLayoutProviding` (so tests use a stub),
/// and persists the user's chosen order to an **injected** `UserDefaults`. The
/// saved order is the durable *intent*: it's applied on every load, so a menu bar
/// item keeps its place across launches, and items that appear later are appended
/// after the ones the user has already arranged.
///
/// Note: the order set here is the order iMenu uses for its own second row — it
/// does not (and cannot, via public API) rearrange the system menu bar itself.
@Observable
final class LayoutStore {

    /// What the Layout page is currently showing.
    nonisolated enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(AppError)
    }

    /// The items to arrange, in the user's chosen order.
    private(set) var items: [MenuBarItemDescriptor] = []

    /// The current load state the view switches on.
    private(set) var state: LoadState = .idle

    @ObservationIgnored private let provider: MenuBarLayoutProviding
    @ObservationIgnored private let defaults: UserDefaults

    /// - Parameters:
    ///   - provider: Where items come from. Defaults to the sample provider;
    ///     tests inject a stub.
    ///   - defaults: Where the chosen order is persisted. Defaults to `.standard`;
    ///     tests inject an isolated suite.
    init(provider: MenuBarLayoutProviding = SampleMenuBarLayoutProvider(), defaults: UserDefaults = .standard) {
        self.provider = provider
        self.defaults = defaults
    }

    /// Fetches the current items and applies the saved order. Failures surface as
    /// an `AppError` in `state` and are logged; they never crash the page.
    func load() {
        state = .loading
        do {
            let fetched = try provider.fetchItems()
            items = applyingSavedOrder(to: fetched)
            state = .loaded
            AppLogger.shared.info("Loaded \(items.count) menu bar items", category: .menuBar)
        } catch let error as AppError {
            items = []
            state = .failed(error)
            AppLogger.shared.error(error, category: .menuBar)
        } catch {
            let appError = AppError.unexpected(String(describing: error))
            items = []
            state = .failed(appError)
            AppLogger.shared.error(appError, category: .menuBar)
        }
    }

    /// Reorders the items and persists the new order. Mirrors SwiftUI's
    /// `onMove(perform:)` signature so the view can hand it straight through.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        persistOrder()
        AppLogger.shared.info("Reordered menu bar items", category: .menuBar)
    }

    /// Moves the item identified by `draggedID` so it lands at the current
    /// position of `targetID`. A convenience over `move(fromOffsets:toOffset:)`
    /// for the horizontal drag-and-drop row, which knows the dragged and
    /// drop-target items only by their identifiers. Unknown or identical ids are
    /// a no-op.
    func move(id draggedID: String, toPositionOf targetID: String) {
        guard draggedID != targetID,
              let from = items.firstIndex(where: { $0.id == draggedID }),
              let target = items.firstIndex(where: { $0.id == targetID })
        else { return }

        // `move(fromOffsets:toOffset:)` inserts *before* the original destination
        // index, so shift by one when dragging an item rightward.
        let destination = target > from ? target + 1 : target
        move(fromOffsets: IndexSet(integer: from), toOffset: destination)
    }

    /// Persists the current order as the list of item identifiers.
    private func persistOrder() {
        defaults.set(items.map(\.id), forKey: Keys.order)
    }

    /// Sorts `fetched` by the saved order: known items by their saved rank,
    /// newcomers kept in fetch order after everything already arranged. The
    /// ordering is total (ties broken by fetch position), so the result is
    /// deterministic regardless of the sort's stability.
    private func applyingSavedOrder(to fetched: [MenuBarItemDescriptor]) -> [MenuBarItemDescriptor] {
        guard let saved = defaults.array(forKey: Keys.order) as? [String], saved.isEmpty == false else {
            return fetched
        }

        var rank: [String: Int] = [:]
        for (index, id) in saved.enumerated() where rank[id] == nil {
            rank[id] = index
        }

        return fetched.enumerated().sorted { lhs, rhs in
            switch (rank[lhs.element.id], rank[rhs.element.id]) {
            case let (left?, right?): return left < right   // both saved: by saved rank
            case (_?, nil): return true                     // saved before newcomer
            case (nil, _?): return false                    // newcomer after saved
            case (nil, nil): return lhs.offset < rhs.offset // both new: keep fetch order
            }
        }.map(\.element)
    }

    private enum Keys {
        static let order = "layout.itemOrder"
    }
}
