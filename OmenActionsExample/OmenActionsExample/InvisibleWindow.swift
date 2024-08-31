//
//  InvisibleWindow.swift
//  OmenActionsExample
//
//  Created by Kit Langton on 12/19/23.
//

#if os(macOS)
import Foundation
import Cocoa

public class InvisibleWindow: NSPanel, NSWindowDelegate {
  override init(
    contentRect: NSRect,
    styleMask style: NSWindow.StyleMask,
    backing backingStoreType: NSWindow.BackingStoreType,
    defer flag: Bool
  ) {
    super.init(contentRect: contentRect, styleMask: [
      .nonactivatingPanel,
      .borderless,
    ], backing: .buffered, defer: true)
    level = .floating
    isReleasedWhenClosed = false
    showsResizeIndicator = false
    standardWindowButton(.zoomButton)?.isEnabled = false
    collectionBehavior = [.canJoinAllSpaces]
//    titleVisibility = .hidden
//    titlebarAppearsTransparent = true
    backgroundColor = .clear
    delegate = self
    isMovableByWindowBackground = false
    hasShadow = false
//        movable
  }

  override public var canBecomeKey: Bool { true }
  override public var canBecomeMain: Bool { true }
  override public var isZoomable: Bool { false }

  public func windowDidResignKey(_: Notification) {
    handleClose()
  }

  var handleClose: () -> Void = {}
}
#endif
