//
//  File.swift
//
//
//  Created by Kit Langton on 12/11/23.
//


#if os(macOS)

  import Magnet
  import Sauce
  import SwiftUI

  struct HotKeyGetterView: View {
    var handleModifiers: (EventModifiers) -> Void = { _ in }
    var handleShortcut: (KeyboardShortcut) -> KeyPress.Result = { _ in .ignored }

    var body: some View {
      KeyGetter { event in
        let (modifiers, key) = self.getKeyAndModifiers(event: event)
        handleModifiers(modifiers)

        if let key {
          let shortcut = KeyboardShortcut(key: key, modifiers: modifiers)
          return handleShortcut(shortcut)
        } else {
          return .ignored
        }
      }
    }

    private func getKeyAndModifiers(event: NSEvent) -> (EventModifiers, KeyEquivalent?) {
      let modifiers = EventModifiers.fromCocoa(event.modifierFlags)
      
      switch event.type {
      case .flagsChanged:
        return (modifiers, nil)
      case .keyDown:
        // Handle special keys
        if event.specialKey == .delete {
          return (modifiers, .delete)
        }
        
        if let char = Sauce.shared.currentASCIICapableCharacter(for: Int(event.keyCode), cocoaModifiers: [])?.first {
          let key = KeyEquivalent(char)
          return (modifiers, key)
        }
      default:
        break
      }
      
      return (modifiers, nil)
    }
  }

  #Preview {
    HotKeyGetterView()
  }

  class KeyGettingViewController: NSViewController {
    deinit {
      monitors.compactMap { $0 }.forEach {
        NSEvent.removeMonitor($0)
      }
    }

    var onKeyDown: (NSEvent) -> KeyPress.Result = { _ in .ignored }

    var monitors = [Any?]()

    override var acceptsFirstResponder: Bool { true }

    func setup() {
      monitors.append(NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        if self?.onKeyDown(event) == .handled {
          return nil
        } else {
          return event
        }
      })

      monitors.append(NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
        if self?.onKeyDown(event) == .handled {
          return nil
        } else {
          return event
        }
      })
    }

    override func flagsChanged(with event: NSEvent) {
      let _ = onKeyDown(event)
    }

    override func keyDown(with event: NSEvent) {
      let _ = onKeyDown(event)
    }
  }

  struct KeyGetter: NSViewControllerRepresentable {
    var onKeyDown: (NSEvent) -> KeyPress.Result

    func makeNSViewController(context _: Context) -> NSViewController {
      let controller = KeyGettingViewController()
      controller.onKeyDown = onKeyDown
      controller.view = NSView()
      Task { @MainActor in
        controller.becomeFirstResponder()
        controller.setup()
      }
      return controller
    }

    func updateNSViewController(_: NSViewController, context _: Context) {}
  }

  extension KeyGetter {
    struct Preview: View {
      @State var key: String = ""
      @State var modifiers: NSEvent.ModifierFlags = []
      @State var string: String = ""
      @State var eventType: NSEvent.EventType = .leftMouseDown

      var modifiersDescription: String {
        modifiers.rawValue.description
      }

      var body: some View {
        VStack {
          Text("Event Type: \(eventType.rawValue)")
          Text("Key: \(key)")
          Text("Modifiers: \(modifiersDescription)")
          Text("String: \(string)")
          KeyGetter { event in
            eventType = event.type
            modifiers = event.modifierFlags
            
            if event.type == .flagsChanged {
              key = "Modifier key"
              string = ""
            } else {
              key = event.charactersIgnoringModifiers ?? ""
              string = event.characters ?? ""
            }
            
            return .ignored
          }
        }
      }
    }
  }

  #Preview {
    KeyGetter.Preview()
  }
#endif
