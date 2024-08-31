import Observation
import SwiftUI

public struct Action: Identifiable, Equatable, Hashable {
  public init(
    icon: Image,
    name: String,
    color: Color? = nil,
    isEnabled: Bool = true,
    shortcut: KeyboardShortcut? = nil,
    action: @escaping () -> Void
  ) {
    self.icon = icon
    self.name = name
    self.color = color
    self.isEnabled = isEnabled
    self.action = action
    self.shortcut = shortcut
  }

  public init(
    systemName: String,
    name: String,
    color: Color? = nil,
    isEnabled: Bool = true,
    shortcut: KeyboardShortcut? = nil,
    action: @escaping () -> Void
  ) {
    self.init(
      icon: Image(systemName: systemName),
      name: name,
      color: color,
      isEnabled: isEnabled,
      shortcut: shortcut,
      action: action
    )
  }

  public var id: String { name }

  public static func == (lhs: Action, rhs: Action) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let icon: Image
  let name: String
  let color: Color?
  let isEnabled: Bool
  let shortcut: KeyboardShortcut?
  let action: () -> Void
}

public struct ActionSection: Identifiable {
  public init(name: String, actions: [Action]) {
    self.name = name
    self.actions = actions
  }

  public init(name: String, @ActionBuilder actions: () -> [Action]) {
    self.init(name: name, actions: actions())
  }

  public var id: String { name }

  let name: String
  let actions: [Action]

  func filter(_ query: String) -> ActionSection? {
    let filteredActions = actions.filter { action in
      action.name.localizedStandardContains(query)
    }
    if filteredActions.isEmpty {
      return nil
    } else {
      return ActionSection(name: name, actions: filteredActions)
    }
  }
}

@resultBuilder
enum ActionBuilder {
  static func buildBlock(_ actions: [Action]...) -> [Action] {
    actions.flatMap { $0 }
  }

  static func buildEither(first: [Action]) -> [Action] {
    first
  }

  static func buildEither(second: [Action]) -> [Action] {
    second
  }

  static func buildOptional(_ actions: [Action]?) -> [Action] {
    actions ?? []
  }

  static func buildArray(_ actions: [[Action]]) -> [Action] {
    actions.flatMap { $0 }
  }

  static func buildLimitedAvailability(_ actions: [Action]) -> [Action] {
    actions
  }

  static func buildExpression(_ action: Action) -> [Action] {
    [action]
  }

  static func buildExpression(_ action: [Action]) -> [Action] {
    action
  }
}

@resultBuilder
enum ActionSectionBuilder {
  static func buildBlock(_ sections: [ActionSection]...) -> [ActionSection] {
    sections.flatMap { $0 }
  }

  static func buildEither(first: [ActionSection]) -> [ActionSection] {
    first
  }

  static func buildEither(second: [ActionSection]) -> [ActionSection] {
    second
  }

  static func buildOptional(_ sections: [ActionSection]?) -> [ActionSection] {
    sections ?? []
  }

  static func buildArray(_ sections: [[ActionSection]]) -> [ActionSection] {
    sections.flatMap { $0 }
  }

  static func buildLimitedAvailability(_ sections: [ActionSection]) -> [ActionSection] {
    sections
  }

  static func buildExpression(_ section: ActionSection) -> [ActionSection] {
    [section]
  }

  static func buildExpression(_ section: [ActionSection]) -> [ActionSection] {
    section
  }
}

public struct ActionMenu {
  public init(
    sections: [ActionSection],
    queryActions: @escaping (String) -> [Action] = { _ in [] }
  ) {
    self.sections = sections
    self.queryActions = queryActions
  }

  public init(
    @ActionSectionBuilder sections: () -> [ActionSection],
    queryActions: @escaping (String) -> [Action] = { _ in [] }
  ) {
    self.init(sections: sections(), queryActions: queryActions)
  }

  let sections: [ActionSection]
  let queryActions: (String) -> [Action]

  var allActions: [Action] {
    sections.flatMap { $0.actions }
  }

  var actionsByShortcut: [KeyboardShortcut: Action] {
    allActions.reduce(into: [:]) { result, action in
      if let shortcut = action.shortcut {
        result[shortcut] = action
      }
    }
  }

  func filter(_ query: String) -> ActionMenu {
    guard !query.isEmpty else {
      return self
    }
    let filteredSections = sections.compactMap { section in
      section.filter(query)
    }
    let querySection = [ActionSection(
      name: "Query",
      actions: queryActions(query)
    )]
    return ActionMenu(sections: filteredSections + querySection)
  }
}

struct ActionPreferenceKey: PreferenceKey {
  static var defaultValue: [Action] = []

  static func reduce(value: inout [Action], nextValue: () -> [Action]) {
    value.append(contentsOf: nextValue())
  }
}

struct SelectedActionEnvironmentKey: EnvironmentKey {
  static var defaultValue: Action? = nil
}

extension EnvironmentValues {
  var selectedAction: Action? {
    get { self[SelectedActionEnvironmentKey.self] }
    set { self[SelectedActionEnvironmentKey.self] = newValue }
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

@Observable
final class ActionMenuViewModel {
  var query: String = ""
  var visibleActions: [Action] = []
  var selectedIndexPath: Int = 0
  var hoveringAction: Action?

  var selectedAction: Action? {
    visibleActions[safe: selectedIndexPath]
  }

  func changeSelectedIndex(_ delta: Int) {
    let nextIndex = selectedIndexPath + delta
    selectedIndexPath = min(max(nextIndex, 0), visibleActions.count - 1)
  }
}

public struct ActionMenuView: View {
  public init(
    actionMenu: ActionMenu,
    handleClose: @escaping () -> Void = {}
  ) {
    self.actionMenu = actionMenu
    self.handleClose = handleClose
  }

  public var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      ScrollViewReader { proxy in
        VStack(alignment: .leading, spacing: 0) {
          if filteredActionMenu.sections.isEmpty {
            Text("No results for *\"\(model.query)\"*")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding(12)
              .padding(.top, 8)
          } else {
            ForEach(filteredActionMenu.sections) { section in
              ActionSectionView(actionSection: section)
            }
          }
        }
        .onChange(of: model.selectedAction) {
          guard let selectedAction = model.selectedAction else {
            return
          }
          proxy.scrollTo(selectedAction)
        }
      }
    }
    .padding(.top, -8)
    .safeAreaPadding(.horizontal, 6)
    .safeAreaPadding(.bottom, 6)
    .frame(maxHeight: 200)
    .fixedSize(horizontal: false, vertical: true)
    .safeAreaInset(edge: .top) {
      TextField("Search...", text: $model.query)
        .textFieldStyle(.plain)
        .padding(12)
        .padding(.leading, 6)
        .overlay(alignment: .bottom) {
          Divider().opacity(0.5)
        }
        .background(.ultraThickMaterial)
        .onSubmit {
          if let selectedAction = model.selectedAction,
             selectedAction.isEnabled
          {
            selectedAction.action()
            handleClose()
          }
        }
        .onKeyPress(.escape) {
          handleClose()
          return .handled
        }
    }
    .onPreferenceChange(ActionPreferenceKey.self) { model.visibleActions = $0 }
    .environment(\.selectedAction, model.selectedAction)
    .onKeyPress(.downArrow) {
      model.changeSelectedIndex(1)
      return .handled
    }
    .onKeyPress(.upArrow) {
      model.changeSelectedIndex(-1)
      return .handled
    }
    .onChange(of: model.query) {
      model.selectedIndexPath = 0
    }
    .environment(model)
  }

  let actionMenu: ActionMenu
  var handleClose: () -> Void = {}

  @State private var model = ActionMenuViewModel()

  private var filteredActionMenu: ActionMenu {
    actionMenu.filter(model.query)
  }
}

public struct ActionSectionView: View {
  public init(actionSection: ActionSection) {
    self.actionSection = actionSection
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(actionSection.name)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)

      ForEach(actionSection.actions) { action in
        ActionView(action: action)
      }
    }
  }

  let actionSection: ActionSection
}

public struct ActionView: View {
  public init(action: Action) {
    self.action = action
  }

  public var body: some View {
    Button {
      action.action()
    } label: {
      HStack {
        action.icon
          .frame(width: 16)
          .padding(.trailing, 2)
        Text(action.name)

        Spacer()
        if let shortcut = action.shortcut {
          KeyboardShortcutView(shortcut: shortcut)
        }
      }
      .lineLimit(1)
      .foregroundColor(action.color)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .frame(height: 36)
      .preference(key: ActionPreferenceKey.self, value: [action])
      .background(
        RoundedRectangle(cornerRadius: 4)
          .fill(isSelected ? (action.color ?? .primary).opacity(0.08) : .clear)
      )
    }.buttonStyle(.plain)
      .disabled(!action.isEnabled)
      .id(action)
      .tag(action)
      .onHover {
        if $0 {
          model.selectedIndexPath = model.visibleActions.firstIndex(of: action) ?? 0
        }
      }
  }

  let action: Action

  @Environment(\.selectedAction) private var selectedAction
  @Environment(ActionMenuViewModel.self) private var model

  private var isSelected: Bool {
    action == selectedAction
  }
}

#if os(macOS)
  public struct ActionMenuShortcutsView: View {
    public init(actionMenu: ActionMenu) {
      self.actionMenu = actionMenu
    }

    public var body: some View {
      HotKeyGetterView { _ in } handleShortcut: { shortcut in
        if let action = actionMenu.allActions.first(where: { $0.shortcut == shortcut }),
           action.isEnabled
        {
          action.action()
          return .handled
        } else {
          return .ignored
        }
      }
    }

    var actionMenu: ActionMenu
  }
#endif

#Preview {
  let actionMenu = ActionMenu {
    ActionSection(name: "Actions") {
      Action(
        icon: Image(systemName: "play.fill"),
        name: "Run",
        shortcut: KeyboardShortcut(key: "r", modifiers: .command),
        action: {
          print("run")
        }
      )

      for i in [1, 2] {
        Action(
          icon: Image(systemName: "circle.fill"),
          name: "Number \(i)",
          action: {
            print("Number \(i)")
          }
        )
      }

      Action(
        icon: Image(systemName: "stop.fill"),
        name: "Stop",
        isEnabled: false,
        shortcut: KeyboardShortcut(key: "s", modifiers: .command),
        action: {
          print("stop")
        }
      )

      // REALLY LONG NAME
      Action(
        icon: Image(systemName: "questionmark.circle.fill"),
        name: "THIS IS A REALLY LONG NAME I MEAN REALLY LONG LIKE REALLY REALLY LONG",
        color: .purple,
        shortcut: KeyboardShortcut(key: .downArrow, modifiers: .command),
        action: {
          print("delete")
        }
      )

      Action(
        icon: Image(systemName: "trash.fill"),
        name: "Delete",
        color: .red,
        shortcut: KeyboardShortcut(key: .delete, modifiers: .command),
        action: {
          print("delete")
        }
      )
    }

    ActionSection(name: "Tools") {
      Action(
        icon: Image(systemName: "gearshape.fill"),
        name: "Settings",
        shortcut: KeyboardShortcut(key: ",", modifiers: [.command]),
        action: {}
      )
      Action(
        icon: Image(systemName: "questionmark.circle.fill"),
        name: "Help",
        shortcut: KeyboardShortcut(key: "/", modifiers: [.command]),
        action: {}
      )
    }
  } queryActions: { query in
    guard !query.isEmpty else {
      return []
    }
    return [Action(
      icon: Image(systemName: "magnifyingglass"),
      name: "Search \(query)", action: {}
    )]
  }

  return ActionMenuView(
    actionMenu: actionMenu,
    handleClose: {
      print("close")
    }
  )
  .background {
    #if os(macOS)
      ActionMenuShortcutsView(actionMenu: actionMenu)
    #endif
  }
  .background(.thinMaterial)
  .cornerRadius(8)
  .overlay {
    RoundedRectangle(cornerRadius: 8)
      .strokeBorder(.primary.opacity(0.1), lineWidth: 1)
  }
  .padding(24)
  .frame(height: 600, alignment: .top)
  .background(.background)
}
