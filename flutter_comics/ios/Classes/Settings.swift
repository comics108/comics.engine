//
//  Settings.swift
//  flutter_comics
//
//  Simple settings storage for comics rendering
//

import Foundation

enum Language: Int {
    case first = 0
    case second = 1
    case third = 2
    case fourth = 3
}

class Settings {
    static let shared = Settings()

    var language: Language = .first
    var soundOff: Bool = false

    private init() {}
}
