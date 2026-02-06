import SwiftUI
import AppKit

@main
struct GestureDrawApp: App {
  init() {
    NSLog("GestureDrawApp started")
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .onAppear {
          NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
  }
}
