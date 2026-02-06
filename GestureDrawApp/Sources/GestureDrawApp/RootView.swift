import SwiftUI

enum Screen: String, CaseIterable {
  case setup = "Setup"
  case session = "Session"
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
        TopBar(screen: $model.screen, theme: theme, onToggleTheme: toggleTheme)
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
  let onToggleTheme: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Timed Drawing Session")
          .font(.system(size: 18, weight: .bold))
        Text("For timed figure drawing sessions")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Spacer()

      BWButton(
        title: theme.label,
        systemImage: theme == .dark ? "sun.max" : "moon",
        action: onToggleTheme
      )
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

  var body: some View {
    let baseFill = fillColor ?? (scheme == .dark ? Color.black : Color(white: 0.2))
    let selectedFill = scheme == .dark ? Color(white: 0.85) : Color(white: 0.75)
    let background = isSelected ? selectedFill : baseFill
    let foreground = textColor ?? (isSelected ? Color.black : Color(white: 0.9))
    let stroke = borderColor ?? background

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
      .foregroundStyle(foreground)
      .overlay(Rectangle().stroke(stroke, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  RootView()
}
