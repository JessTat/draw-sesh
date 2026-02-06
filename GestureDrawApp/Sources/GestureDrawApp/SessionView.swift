import SwiftUI
import AppKit

struct SessionView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @State private var keyMonitor: Any?

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

        HStack(spacing: 10) {
          BWButton(title: "Previous") {
            model.previous()
          }
          BWButton(title: model.session?.status == .running ? "Pause" : "Resume") {
            model.togglePause()
          }
          BWButton(title: "Next") {
            model.advance(countCurrent: true)
          }
          BWButton(title: "Skip") {
            model.advance(countCurrent: false)
          }
          BWButton(title: "Stop") {
            model.stopSession()
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(palette.background.opacity(0.9))
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
    }
    .onReceive(timer) { _ in
      model.tick()
    }
    .onAppear {
      installKeyMonitor()
    }
    .onDisappear {
      removeKeyMonitor()
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

#Preview {
  SessionView(model: AppModel(), palette: AppTheme.dark.palette)
}
