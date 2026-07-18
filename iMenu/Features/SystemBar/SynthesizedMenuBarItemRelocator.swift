//
//  SynthesizedMenuBarItemRelocator.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import CoreGraphics

/// The live `MenuBarItemRelocating`: posts a synthesized ⌘-drag with `CGEvent` to
/// physically move a status item along the real menu bar (the mechanic behind editing
/// the real menu bar's order from the Layout page).
///
/// The gesture mirrors what a user does by hand — hold ⌘, press on the item, drag it,
/// release — as a sequence of posted events:
///
/// 1. Command key **down** (so the menu bar enters item-rearrange mode).
/// 2. Warp the cursor to the item and post `leftMouseDown` with the ⌘ flag.
/// 3. Post `leftMouseDragged` along `MenuBarItemDragGeometry.interpolatedPath`, with a
///    short pause between steps so the WindowServer reads it as a drag.
/// 4. `leftMouseUp` at the destination, then Command key **up**.
///
/// **This is the fragile bet.** Whether macOS honors a *synthesized* ⌘-drag for every
/// third-party item is unproven and expected to need on-device tuning — the step
/// count, the per-step pause, and whether the explicit Command key events help or hurt
/// are the knobs (`stepCount` / `stepDelayMilliseconds`). It moves the real cursor by
/// design, so it runs on a user-initiated action (a Layout drop), not silently.
/// Untested here like the other AppKit/CGEvent glue; it rides with on-device validation.
final class SynthesizedMenuBarItemRelocator: MenuBarItemRelocating {

    /// Virtual key code for the left Command key (`kVK_Command`).
    private static let commandKeyCode: CGKeyCode = 0x37

    private let stepCount: Int
    private let stepDelay: useconds_t

    /// - Parameters:
    ///   - stepCount: how many drag steps to break the motion into (tuning knob).
    ///   - stepDelayMilliseconds: pause between drag steps so the drag registers.
    init(stepCount: Int = MenuBarItemDragGeometry.defaultStepCount,
         stepDelayMilliseconds: UInt32 = 12) {
        self.stepCount = stepCount
        self.stepDelay = stepDelayMilliseconds * 1000
    }

    func dragItem(from source: CGPoint, to destination: CGPoint) {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            AppLogger.shared.error(AppError.menuBarItemReorderFailed, category: .menuBar)
            return
        }

        let path = MenuBarItemDragGeometry.interpolatedPath(from: source, to: destination, steps: stepCount)

        // Command held down for the whole gesture so the menu bar enters rearrange
        // mode; paired with the ⌘ flag on every mouse event. No early return exists
        // between here and the matching key-up, so ⌘ is never left stuck down.
        postKey(Self.commandKeyCode, down: true, source: eventSource)

        CGWarpMouseCursorPosition(source)
        postMouse(.mouseMoved, at: source, source: eventSource)
        postMouse(.leftMouseDown, at: source, source: eventSource)
        for point in path {
            postMouse(.leftMouseDragged, at: point, source: eventSource)
            usleep(stepDelay)
        }
        postMouse(.leftMouseUp, at: destination, source: eventSource)

        postKey(Self.commandKeyCode, down: false, source: eventSource)

        AppLogger.shared.info(
            "Synthesized a menu bar ⌘-drag over \(path.count) steps",
            category: .menuBar
        )
    }

    // MARK: - Event posting

    /// Posts one mouse event at `point` with the Command flag set, so each drag
    /// sample carries the modifier the rearrange gesture watches for.
    private func postMouse(_ type: CGEventType, at point: CGPoint, source: CGEventSource) {
        guard let event = CGEvent(mouseEventSource: source,
                                  mouseType: type,
                                  mouseCursorPosition: point,
                                  mouseButton: .left) else { return }
        event.flags = .maskCommand
        event.post(tap: .cghidEventTap)
    }

    /// Posts a Command key up/down so the modifier state is real, not merely a flag on
    /// the mouse events.
    private func postKey(_ keyCode: CGKeyCode, down: Bool, source: CGEventSource) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else { return }
        event.flags = down ? .maskCommand : []
        event.post(tap: .cghidEventTap)
    }
}
