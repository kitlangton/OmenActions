import SwiftUI

public struct KeyboardShortcutView: View {
  public init(shortcut: KeyboardShortcut) {
    self.shortcut = shortcut
  }

  public var body: some View {
    HStack(spacing: 4) {
      ForEach(shortcut.strings, id: \.self) { string in
        Text(string)
          .foregroundStyle(.primary.opacity(0.75))
          .foregroundColor(.primary)
          .padding(4)
          .frame(width: 24)
          .background(.tertiary.opacity(0.25))
          .cornerRadius(4)
      }
    }
  }

  private let shortcut: KeyboardShortcut
}

#Preview {
  KeyboardShortcutView(
    shortcut: .init(key: .escape, modifiers: .command)
  )
  .padding(24)
  .background(.background)
}
