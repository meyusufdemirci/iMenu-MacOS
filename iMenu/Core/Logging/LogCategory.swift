//
//  LogCategory.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import Foundation

/// A stable, finite set of subsystems used to group log messages.
///
/// Using an enum (instead of free-form strings) keeps categories greppable in
/// Console.app and prevents typo-driven fragmentation of the log stream.
enum LogCategory: String {
    case general
    case ui
    case network
    case persistence
    case lifecycle
    case menuBar
}
