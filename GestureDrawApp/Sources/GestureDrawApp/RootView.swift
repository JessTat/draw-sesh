import SwiftUI
import AppKit

enum Screen: String, CaseIterable {
  case setup = "Setup"
  case session = "Session"
  case history = "History"
}

struct RootView: View {
  @StateObject private var model = AppModel()
  @AppStorage("gd-theme") private var themeRawValue: String = AppTheme.dark.rawValue

  private var theme: AppTheme {
    AppTheme(rawValue: themeRawValue) ?? .dark
  }

  private var palette: Palette {
    theme.palette
  }

  var body: some View {
    VStack(spacing: 0) {
      if model.screen != .session {
        TopBar(screen: $model.screen, theme: theme, palette: palette, onToggleTheme: toggleTheme)
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 12)

        Divider()
      }

      Group {
        switch model.screen {
        case .setup:
          SetupView(model: model, palette: palette)
        case .session:
          SessionView(model: model, palette: palette)
        case .history:
          HistoryView(model: model, palette: palette)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(minWidth: 1100, minHeight: 760)
    .background(palette.background)
    .preferredColorScheme(theme.colorScheme)
  }

  private func toggleTheme() {
    themeRawValue = (theme == .dark ? AppTheme.light.rawValue : AppTheme.dark.rawValue)
  }
}

struct TopBar: View {
  @Binding var screen: Screen
  let theme: AppTheme
  let palette: Palette
  let onToggleTheme: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Timed Drawing Session")
          .font(.system(size: 18, weight: .bold))
      }

      Spacer()

      TopTabButton(title: "Session", isSelected: screen == .setup, background: palette.background) {
        screen = .setup
      }

      TopTabButton(title: "History", isSelected: screen == .history, background: palette.background) {
        screen = .history
      }

      BWButton(
        title: theme.label,
        fillColor: palette.background,
        borderColor: Color.clear,
        systemImage: theme == .dark ? "sun.max" : "moon",
        action: onToggleTheme
      )
    }
  }
}

struct TopTabButton: View {
  let title: String
  let isSelected: Bool
  let background: Color
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text(title)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle((isSelected || isHovering) ? Color.primary : Color.secondary)

        Rectangle()
          .frame(height: 1)
          .foregroundStyle(Color.primary)
          .opacity(isSelected ? 1 : 0)
      }
      .frame(width: 100)
      .padding(.horizontal, 2)
      .padding(.vertical, 2)
      .background(background)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}

struct BWButton: View {
  let title: String
  let isPrimary: Bool
  let minWidth: CGFloat?
  let minHeight: CGFloat?
  let fillColor: Color?
  let textColor: Color?
  let borderColor: Color?
  let systemImage: String?
  let action: () -> Void
  let isSelected: Bool
  let expand: Bool
  let fontSize: CGFloat?
  let fontWeight: Font.Weight?

  init(
    title: String,
    isPrimary: Bool = false,
    minWidth: CGFloat? = nil,
    minHeight: CGFloat? = nil,
    fillColor: Color? = nil,
    textColor: Color? = nil,
    borderColor: Color? = nil,
    systemImage: String? = nil,
    isSelected: Bool = false,
    expand: Bool = false,
    fontSize: CGFloat? = nil,
    fontWeight: Font.Weight? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.isPrimary = isPrimary
    self.minWidth = minWidth
    self.minHeight = minHeight
    self.fillColor = fillColor
    self.textColor = textColor
    self.borderColor = borderColor
    self.systemImage = systemImage
    self.isSelected = isSelected
    self.expand = expand
    self.fontSize = fontSize
    self.fontWeight = fontWeight
    self.action = action
  }

  @Environment(\.colorScheme) private var scheme
  @State private var isHovering = false

  var body: some View {
    let baseFill = fillColor ?? (scheme == .dark ? Color.black : Color(white: 0.2))
    let selectedFill = scheme == .dark ? Color(white: 0.85) : (fillColor ?? Color(white: 0.2))
    let unselectedFill = scheme == .dark ? baseFill : (fillColor ?? Color(white: 0.75))
    let background = isSelected ? selectedFill : unselectedFill
    let foreground = textColor ?? {
      if scheme == .dark {
        return isSelected ? Color.black : Color(white: 0.9)
      }
      if fillColor != nil {
        return Color.black
      }
      return isSelected ? Color.white : Color.black
    }()
    let stroke = borderColor ?? background
    let hoverOverlay = scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)

    let resolvedFontSize = fontSize ?? 13
    let resolvedWeight = fontWeight ?? .medium

    Button(action: action) {
      Group {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: resolvedFontSize, weight: resolvedWeight))
        } else {
          Text(title)
            .font(.system(size: resolvedFontSize, weight: resolvedWeight))
        }
      }
      .frame(minWidth: minWidth, minHeight: minHeight)
      .frame(maxWidth: expand ? .infinity : nil)
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
      .background(background)
      .overlay(Rectangle().fill(hoverOverlay).opacity(isHovering ? 1 : 0).allowsHitTesting(false))
      .foregroundStyle(foreground)
      .overlay(Rectangle().stroke(stroke, lineWidth: 1).allowsHitTesting(false))
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}

#Preview {
  RootView()
}
