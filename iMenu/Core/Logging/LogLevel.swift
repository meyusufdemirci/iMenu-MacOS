//
//  LogLevel.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation
import OSLog

/// Severity of a log message, ordered from least to most severe.
///
/// `Comparable` conformance lets `AppLogger` filter out everything below a
/// configured `minimumLevel`.
enum LogLevel: Int, Comparable, CustomStringConvertible {
    case debug = 0
    case info
    case warning
    case error

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }

    /// Maps onto Apple's unified logging severity used by `OSLogHandler`.
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
