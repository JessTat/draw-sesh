import SwiftUI

enum AppTheme: String, CaseIterable {
  case dark
  case light

  var label: String {
    switch self {
    case .dark: return "Light mode"
    case .light: return "Dark mode"
    }
  }

  var colorScheme: ColorScheme {
    switch self {
    case .dark: return .dark
    case .light: return .light
    }
  }

  var palette: Palette {
    switch self {
    case .dark:
      return Palette(
        background: .black,
        panel: Color(white: 0.07),
        panelAlt: Color(white: 0.04),
        previewBackground: Color(white: 0.18),
        border: Color(white: 0.16),
        text: .white,
        muted: Color(white: 0.7)
      )
    case .light:
      return Palette(
        background: Color(white: 0.86),
        panel: Color(white: 0.86),
        panelAlt: Color(white: 0.84),
        previewBackground: Color(white: 0.8),
        border: Color(white: 0.78),
        text: .black,
        muted: Color(white: 0.35)
      )
    }
  }
}

struct Palette {
  let background: Color
  let panel: Color
  let panelAlt: Color
  let previewBackground: Color
  let border: Color
  let text: Color
  let muted: Color
}
