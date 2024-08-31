//
//  OmenActionsExampleApp.swift
//  OmenActionsExample
//
//  Created by Kit Langton on 12/19/23.
//

import Observation
import SwiftData
import SwiftUI

#if os(macOS)
  @Observable
  final class MacActionMenuModel: ObservableObject {
    static let shared = MacActionMenuModel()

    var rect: CGRect?
  }

  struct WindowGetter: NSViewRepresentable {
    class Coordinator: NSObject, NSWindowDelegate {
      init(_ windowGetter: WindowGetter) {
        self.windowGetter = windowGetter
      }

      var windowGetter: WindowGetter

      func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
          return
        }
        Task { @MainActor in
          windowGetter.windowFrame = window.frame
        }
      }

      func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
          return
        }
        Task { @MainActor in
          windowGetter.windowFrame = window.frame
        }
      }
    }

    @Binding var windowFrame: CGRect?

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    func makeNSView(context: Context) -> NSView {
      let view = NSView()

      Task { @MainActor in
        guard let window = view.window else {
          return
        }
        self.windowFrame = window.frame
        window.delegate = context.coordinator
      }

      return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
  }

  struct MacActionMenuRectViewModifier: ViewModifier {
    @Environment(MacActionMenuModel.self) var model
    @State var windowFrame: CGRect?

    func body(content: Content) -> some View {
      content
        .background(WindowGetter(windowFrame: $windowFrame))
        .background(
          GeometryReader { geometry in
            let frame = geometry.frame(in: .global)

            let windowRect = windowFrame ?? .zero
            let screenSize = NSScreen.main?.frame ?? .zero
            let windowY = screenSize.height - (windowRect.origin.y + windowRect.height)
            let y = windowY + frame.origin.y

            let rect = CGRect(
              x: windowRect.origin.x + frame.origin.x,
              y: y,
              width: frame.width,
              height: frame.height
            )

            Color.clear.onChange(of: rect, initial: true) {
              model.rect = rect
            }
          }
        )
    }
  }

  extension View {
    func macActionMenuRect() -> some View {
      modifier(MacActionMenuRectViewModifier())
    }
  }

  extension NSScreen {
    var menuBarHeight: CGFloat {
      return frame.height - visibleFrame.height
    }
  }

  struct MacActionMenuPositionOutlineView: View {
    @Environment(MacActionMenuModel.self) var model

    // draw a blue stroke around the rect
    var body: some View {
      if let rect = model.rect {
        RoundedRectangle(cornerRadius: 2)
          .inset(by: -4)
          .fill(.blue.gradient.opacity(0.2))
          .strokeBorder(Color.blue, lineWidth: 1)
          .frame(width: rect.width, height: rect.height)
          .offset(x: rect.minX, y: rect.minY - (NSScreen.main?.menuBarHeight ?? 0))
          .animation(.spring(duration: 0.4), value: rect)
      }
    }
  }

  class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
      let contentView = MacActionMenuPositionOutlineView()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(MacActionMenuModel.shared)

      let screensize = NSScreen.main!.frame
      let frame = NSRect(x: 0, y: 0, width: screensize.width, height: screensize.height)
      window = InvisibleWindow()
      window.setFrame(frame, display: true)
      window.center()
      window.contentView = NSHostingView(rootView: contentView)
      window.makeKeyAndOrderFront(nil)
    }
  }
#endif

@main
struct OmenActionsExampleApp: App {
  #if os(macOS)
    @State var macActionMenuModel = MacActionMenuModel.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Item.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
    #if os(macOS)
    .environment(macActionMenuModel)
    #endif
  }
}
