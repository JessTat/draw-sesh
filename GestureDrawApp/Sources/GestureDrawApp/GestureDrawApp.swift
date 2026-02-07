import SwiftUI
import AppKit

@main
struct GestureDrawApp: App {
  init() {
    NSLog("GestureDrawApp started")
    NSApplication.shared.setActivationPolicy(.regular)
    NSApplication.shared.activate(ignoringOtherApps: true)
    applyAppIcon()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .onAppear {
          NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
  }

  private func applyAppIcon() {
    let fallbackPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("Sources/GestureDrawApp/Resources/AppIcon-1024.png")

    let candidates: [URL] = [
      Bundle.main.url(forResource: "AppIcon-1024", withExtension: "png"),
      Bundle.main.resourceURL?.appendingPathComponent("AppIcon-1024.png"),
      fallbackPath
    ].compactMap { $0 }

    for url in candidates {
      if let icon = NSImage(contentsOf: url) {
        NSApplication.shared.applicationIconImage = icon
        return
      }
    }
  }
}
