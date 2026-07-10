//
//  LogEntry.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// A single, fully-formed log record.
///
/// It is a plain value type so it can be forwarded to any `LogHandler`
/// (the real one writes to the unified log; tests capture it in memory).
struct LogEntry: Equatable {
    let level: LogLevel
    let message: String
    let category: String
    let file: String
    let function: String
    let line: Int

    /// The short file name (without the full path) for readable output.
    var fileName: String {
        (file as NSString).lastPathComponent
    }
}
