//
//  SecondRowController.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import AppKit
import SwiftUI
import Observation

/// Owns iMenu's second-row panel and keeps it in sync with the app's state.
///
/// A borderless, **non-activating** `NSPanel` hosts `SecondRowView`, floating just
/// below the system menu bar. Because it hosts a view bound to the **shared**
/// `LayoutStore`, reordering on the Layout page updates the row live — the store
/// is `@Observable` and both surfaces read the same `items`. This controller's job
/// is only the AppKit shell: create the panel, decide *whether* it should show
/// (via `SecondRowPresentation`), and place it (via `SecondRowPlacement`).
///
/// It observes the store and settings itself (not through a SwiftUI view) so the
/// row lives independently of the main window — it stays correct even while that
/// window is closed. The pure show/hide and geometry rules are unit tested; this
/// glue, like `MenuBarContent`, is not.
///
/// The row is display-only for now (`ignoresMouseEvents`): clicking an item to
/// activate the real menu bar extra is a later, harder concern.
@MainActor
final class SecondRowController {

    private let store: LayoutStore
    private let settings: SettingsStore

    private var panel: NSPanel?
    private var hostingView: NSHostingView<SecondRowView>?
    private var hasStarted = false

    /// `nonisolated` so the app can build the controller in its initializer; all
    /// AppKit work is deferred to `start()`, which runs on the main actor.
    nonisolated init(store: LayoutStore, settings: SettingsStore) {
        self.store = store
        self.settings = settings
    }

    /// Begins loading items (if needed), observing state, and showing the row.
    /// Idempotent: safe to call from a view's lifecycle that may fire repeatedly.
    func start() {
        guard hasStarted == false else { return }
        hasStarted = true

        // Populate the row even if the Layout page is never opened.
        if store.state == .idle {
            store.load()
        }

        observe()
        apply()
    }

    // MARK: - Observation

    /// Re-runs `apply()` whenever the show/hide inputs change. `withObservation
    /// Tracking` fires once and must be re-armed; the `onChange` hop reads the
    /// fresh values on the next main-actor tick.
    private func observe() {
        withObservationTracking {
            _ = settings.showSecondRowAutomatically
            _ = store.items
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.apply()
                self.observe()
            }
        }
    }

    /// Shows and positions the panel when it should be visible, hides it otherwise.
    private func apply() {
        let shouldShow = SecondRowPresentation.shouldShow(
            automaticEnabled: settings.showSecondRowAutomatically,
            itemCount: store.items.count
        )
        if shouldShow {
            showAndPosition()
        } else {
            panel?.orderOut(nil)
        }
    }

    // MARK: - Panel

    private func showAndPosition() {
        let panel = ensurePanel()
        guard let hostingView, let screen = NSScreen.main else { return }

        // Lay out the SwiftUI content so its size reflects the current items.
        hostingView.layoutSubtreeIfNeeded()
        let contentSize = hostingView.fittingSize

        let frame = SecondRowPlacement.frame(
            contentSize: contentSize,
            screenFrame: screen.frame,
            menuBarHeight: Self.menuBarHeight(for: screen)
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
        AppLogger.shared.info("Second row shown with \(store.items.count) items", category: .menuBar)
    }

    /// Lazily builds the panel + hosting view on first show.
    private func ensurePanel() -> NSPanel {
        if let panel { return panel }

        let hostingView = NSHostingView(rootView: SecondRowView(store: store))
        hostingView.sizingOptions = [.intrinsicContentSize]

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true // display-only for now
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView
        return panel
    }

    /// Height of the system menu bar on `screen`: the gap between the full frame's
    /// top and the visible frame's top, falling back to the status bar thickness.
    private static func menuBarHeight(for screen: NSScreen) -> CGFloat {
        let inset = screen.frame.maxY - screen.visibleFrame.maxY
        return inset > 0 ? inset : NSStatusBar.system.thickness
    }
}
