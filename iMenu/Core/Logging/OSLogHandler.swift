//
//  OSLogHandler.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import OSLog

/// The production `LogHandler`: writes to Apple's unified logging system so
/// messages show up in Console.app and `log` captures, grouped by category.
struct OSLogHandler: LogHandler {

    /// The subsystem string surfaced in Console.app; defaults to the app's
    /// bundle identifier so log filtering matches the product.
    private let subsystem: String

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.nefarius.iMenu") {
        self.subsystem = subsystem
    }

    func handle(_ entry: LogEntry) {
        let logger = Logger(subsystem: subsystem, category: entry.category)
        // Developer-authored messages are safe to mark public; associated user
        // data should never be interpolated into the `message` string upstream.
        logger.log(
            level: entry.level.osLogType,
            "[\(entry.fileName, privacy: .public):\(entry.line, privacy: .public)] \(entry.function, privacy: .public) — \(entry.message, privacy: .public)"
        )
    }
}
