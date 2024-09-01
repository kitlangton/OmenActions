//
//  KeyboardShortuct.swift
//
//
//  Created by Kit Langton on 12/19/23.
//

import SwiftUI

public struct KeyboardShortcut: Equatable, Hashable {
  public init(key: KeyEquivalent, modifiers: EventModifiers = []) {
    self.key = key
    self.modifiers = modifiers
  }

  public let key: KeyEquivalent
  public let modifiers: EventModifiers
}

extension KeyboardShortcut {
  var strings: [String] {
    var strings: [String] = modifiers.strings
    strings.append(key.toString)
    return strings
  }
}



// MARK: - EventModifiers Extensions

extension EventModifiers: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
  
  var strings: [String] {
    var strings: [String] = []
    if contains(.command) {
      strings.append("⌘")
    }
    if contains(.control) {
      strings.append("⌃")
    }
    if contains(.option) {
      strings.append("⌥")
    }
    if contains(.shift) {
      strings.append("⇧")
    }
    return strings
  }
}

#if os(macOS)
extension EventModifiers {
  static func fromCocoa(_ cocoa: NSEvent.ModifierFlags) -> EventModifiers {
    var modifiers: EventModifiers = []
    if cocoa.contains(.command) {
      modifiers.insert(.command)
    }
    if cocoa.contains(.option) {
      modifiers.insert(.option)
    }
    if cocoa.contains(.control) {
      modifiers.insert(.control)
    }
    if cocoa.contains(.shift) {
      modifiers.insert(.shift)
    }
    return modifiers
  }
}
#endif

// MARK: - KeyEquivalent Extensions

extension KeyEquivalent {
  var toString: String {
    switch self {
    case .delete: "⌫"
    case .upArrow: "↑"
    case .downArrow: "↓"
    case .leftArrow: "←"
    case .rightArrow: "→"
    case .deleteForward: "⌦"
    case .space: "␣"
    case .escape: "⎋"
    default: String(character.uppercased())
    }
  }
}

