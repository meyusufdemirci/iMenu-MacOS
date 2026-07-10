//
//  AppLogger.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// The app's single entry point for logging.
///
/// Usage:
/// ```swift
/// AppLogger.shared.info("Home appeared", category: .ui)
/// ```
///
/// The logger decides *whether* a message clears `minimumLevel`, builds a
/// `LogEntry`, and forwards it to its `LogHandler`. Because the handler is
/// injected, the whole pipeline is unit-testable (see `LoggingTests`).
final class AppLogger {

    /// Shared instance for app-wide use.
    static let shared = AppLogger()

    private let handler: LogHandler
    private let minimumLevel: LogLevel

    /// - Parameters:
    ///   - handler: Where records are written. Defaults to the unified log.
    ///   - minimumLevel: Records below this severity are dropped. Defaults to
    ///     `.debug` in DEBUG builds and `.info` otherwise.
    init(handler: LogHandler = OSLogHandler(), minimumLevel: LogLevel = AppLogger.defaultMinimumLevel) {
        self.handler = handler
        self.minimumLevel = minimumLevel
    }

    private static var defaultMinimumLevel: LogLevel {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }

    // MARK: - Convenience API

    func debug(_ message: @autoclosure () -> String, category: LogCategory = .general, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.debug, message(), category: category, file: file, function: function, line: line)
    }

    func info(_ message: @autoclosure () -> String, category: LogCategory = .general, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.info, message(), category: category, file: file, function: function, line: line)
    }

    func warning(_ message: @autoclosure () -> String, category: LogCategory = .general, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.warning, message(), category: category, file: file, function: function, line: line)
    }

    func error(_ message: @autoclosure () -> String, category: LogCategory = .general, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.error, message(), category: category, file: file, function: function, line: line)
    }

    /// Logs an `AppError` at `.error` severity using its localized description.
    func error(_ error: AppError, category: LogCategory = .general, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.error, error.errorDescription ?? String(describing: error), category: category, file: file, function: function, line: line)
    }

    // MARK: - Core

    private func log(_ level: LogLevel, _ message: @autoclosure () -> String, category: LogCategory, file: String, function: String, line: Int) {
        guard level >= minimumLevel else { return }

        let entry = LogEntry(
            level: level,
            message: message(),
            category: category.rawValue,
            file: file,
            function: function,
            line: line
        )
        handler.handle(entry)
    }
}
