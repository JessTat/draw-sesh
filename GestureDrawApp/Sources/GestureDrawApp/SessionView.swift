import SwiftUI
import AppKit

struct SessionView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @State private var keyMonitor: Any?
  @State private var mouseMonitor: Any?
  @State private var lastMouseMove: Date = Date()
  @State private var controlsVisible: Bool = true

  var body: some View {
    ZStack(alignment: .bottom) {
      palette.background
        .ignoresSafeArea()

      if let image = model.activeImage, let nsImage = NSImage(contentsOfFile: image.path) {
        Image(nsImage: nsImage)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(palette.background)
          .ignoresSafeArea()
      } else {
        Rectangle()
          .fill(palette.background)
          .ignoresSafeArea()
      }

      VStack {
        Spacer()
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(timerLabel)
              .font(.system(size: 22, weight: .bold))
            Text(model.activeImage?.name ?? "")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
            Text(progressLabel)
              .font(.system(size: 11))
              .foregroundStyle(palette.muted)
          }

          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
      }

      HStack {
        Spacer()
        HStack(spacing: 10) {
          ActionButton(title: "Previous", keyLabel: "Left", palette: palette) {
            model.previous()
          }
          ActionButton(title: model.session?.status == .running ? "Pause" : "Resume", keyLabel: "Space", palette: palette) {
            model.togglePause()
          }
          ActionButton(title: "Next", keyLabel: "Right", palette: palette) {
            model.advance(countCurrent: true)
          }
          ActionButton(title: "Skip", keyLabel: "S", palette: palette) {
            model.advance(countCurrent: false)
          }
          ActionButton(title: "Full Screen", keyLabel: "F", palette: palette) {
            NSApplication.shared.keyWindow?.toggleFullScreen(nil)
          }
          ActionButton(title: "Stop", keyLabel: "Esc", palette: palette) {
            model.stopSession()
          }
        }
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(palette.background.opacity(0.9))
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
      .opacity(controlsVisible ? 1 : 0)
      .allowsHitTesting(controlsVisible)
      .animation(.easeInOut(duration: 0.3), value: controlsVisible)
    }
    .onReceive(timer) { _ in
      model.tick()
      updateControlsVisibility()
    }
    .onAppear {
      installKeyMonitor()
      installMouseMonitor()
    }
    .onDisappear {
      removeKeyMonitor()
      removeMouseMonitor()
    }
  }

  private var timerLabel: String {
    if model.session?.isTimed == false {
      return "∞"
    }
    return timeString(model.session?.remainingSec ?? 0)
  }

  private func timeString(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return String(format: "%02d:%02d", minutes, remainder)
  }

  private var progressLabel: String {
    guard let session = model.session else { return "" }
    let current = max(1, session.completed + 1)
    switch session.target {
    case .count(let limit):
      return "Image \(current) of \(limit)"
    case .infinite:
      return "Image \(current) of ∞"
    }
  }

  private func installKeyMonitor() {
    guard keyMonitor == nil else { return }
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      handleKey(event)
      return nil
    }
  }

  private func removeKeyMonitor() {
    if let monitor = keyMonitor {
      NSEvent.removeMonitor(monitor)
      keyMonitor = nil
    }
  }

  private func installMouseMonitor() {
    guard mouseMonitor == nil else { return }
    mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
      registerMouseMove()
      return event
    }
  }

  private func removeMouseMonitor() {
    if let monitor = mouseMonitor {
      NSEvent.removeMonitor(monitor)
      mouseMonitor = nil
    }
  }

  private func registerMouseMove() {
    lastMouseMove = Date()
    if !controlsVisible {
      controlsVisible = true
    }
  }

  private func updateControlsVisibility() {
    if Date().timeIntervalSince(lastMouseMove) > 3 {
      if controlsVisible {
        controlsVisible = false
      }
    }
  }

  private func handleKey(_ event: NSEvent) {
    switch event.keyCode {
    case 49: // Space
      model.togglePause()
    case 123: // Left arrow
      model.previous()
    case 124: // Right arrow
      model.advance(countCurrent: true)
    case 53: // Escape
      model.stopSession()
    default:
      break
    }

    if let key = event.charactersIgnoringModifiers?.lowercased() {
      switch key {
      case "s":
        model.advance(countCurrent: false)
      case "f":
        NSApplication.shared.keyWindow?.toggleFullScreen(nil)
      default:
        break
      }
    }
  }
}

private struct ActionButton: View {
  let title: String
  let keyLabel: String
  let palette: Palette
  let action: () -> Void

  var body: some View {
    VStack(spacing: 4) {
      Keycap(label: keyLabel, palette: palette)
      BWButton(title: title) {
        action()
      }
    }
  }
}

private struct Keycap: View {
  let label: String
  let palette: Palette

  var body: some View {
    Text(label)
      .font(.system(size: 9, weight: .semibold))
      .foregroundStyle(palette.muted)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
  }
}

#Preview {
  SessionView(model: AppModel(), palette: AppTheme.dark.palette)
}
