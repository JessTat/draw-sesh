import SwiftUI

struct SettingsView: View {
  @ObservedObject var model: AppModel
  let palette: Palette
  let theme: AppTheme
  let onToggleTheme: () -> Void

  @State private var pendingAction: SettingsAction? = nil

  var body: some View {
    ZStack {
      HStack {
        Spacer()
        VStack(alignment: .leading, spacing: 12) {
          Text("Settings")
            .font(.system(size: 20, weight: .bold))

          VStack(alignment: .leading, spacing: 10) {
            Toggle("Prioritize choosing images that are drawn less", isOn: $model.prioritizeLowDraw)
          }

          VStack(alignment: .leading, spacing: 10) {
            Toggle("Light mode", isOn: Binding(
              get: { theme == .light },
              set: { _ in onToggleTheme() }
            ))
          }

          VStack(alignment: .leading, spacing: 18) {
            Toggle("Disable history (if you won't use it, just disable it)", isOn: Binding(
              get: { !model.historyEnabled },
              set: { newValue in model.setHistoryEnabled(!newValue) }
            ))
          }

          Divider()

          Text("About DrawSesh")
            .font(.system(size: 16, weight: .bold))

          VStack(alignment: .leading, spacing: 10) {
            Text("DrawSesh is for timed drawing sessions using your local folder of reference images. Right-click images for additional options. All images in sub-folders will be loaded. This app only supports .jpg, .png, and .webp.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)

            VStack(alignment: .leading, spacing: 4) {
              Text("Example 90-min figure drawing regiment:")
                .font(.system(size: 12, weight: .semibold))
              Text("- 1m x 10")
              Text("- 2m x 5")
              Text("- 3m x 5")
              Text("- 5m x 5")
              Text("- 10m x 3 or 15m x 2")
            }
            .font(.system(size: 12))
            .foregroundStyle(palette.muted)

            Text("Begin the short intervals by focusing on gesture. As the timer gets longer, introduce rhythms and structure, increasing detail and being intentional with proportions with more time. Take an eye and hand break between every session.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)

            Text("Create your own schedule that works for you. Date your drawings so you can refer back to them in the future.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
          }

          Divider()

          VStack(alignment: .leading, spacing: 10) {
            Text("Reset things if problems happen")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(palette.muted)

            HStack(spacing: 8) {
              BWButton(
                title: "Clear History Log",
                minHeight: 24,
                fillColor: palette.panelAlt,
                textColor: palette.muted,
                borderColor: palette.border,
                fontSize: 10
              ) {
                pendingAction = .clearHistory
              }
              BWButton(
                title: "Reset Draw Count",
                minHeight: 24,
                fillColor: palette.panelAlt,
                textColor: palette.muted,
                borderColor: palette.border,
                fontSize: 10
              ) {
                pendingAction = .resetDrawCount
              }
              BWButton(
                title: "Restore Defaults",
                minHeight: 24,
                fillColor: palette.panelAlt,
                textColor: palette.muted,
                borderColor: palette.border,
                fontSize: 10
              ) {
                pendingAction = .resetAll
              }
            }
          }
        }
        .padding(20)
        .background(palette.panel)
        .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
        .frame(width: 520)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        Spacer()
      }
      .padding(20)
      .background(palette.background)
      .frame(maxHeight: .infinity)

      if let action = pendingAction {
        ConfirmationModal(
          palette: palette,
          title: action.title,
          message: action.message,
          confirmTitle: action.confirmTitle,
          onCancel: { pendingAction = nil },
          onConfirm: {
            handleAction(action)
            pendingAction = nil
          }
        )
      }
    }
  }

  private func handleAction(_ action: SettingsAction) {
    switch action {
    case .clearHistory:
      model.clearHistory()
    case .resetDrawCount:
      model.clearDrawHistory()
    case .resetAll:
      model.resetEverything()
    }
  }
}

enum SettingsAction: String, Identifiable {
  case clearHistory
  case resetDrawCount
  case resetAll

  var id: String { rawValue }

  var title: String {
    switch self {
    case .clearHistory:
      return "Clear History?"
    case .resetDrawCount:
      return "Reset Draw Count?"
    case .resetAll:
      return "Restore Defaults?"
    }
  }

  var message: String {
    switch self {
    case .clearHistory:
      return "This will clear all the sessions logged."
    case .resetDrawCount:
      return "This will reset the draw count logged for every image. This information is used to weight the randomization of images towards the lesser-drawn images."
    case .resetAll:
      return "This will clear history, reset draw counts, remove the selected folder, and restore default settings."
    }
  }

  var confirmTitle: String {
    switch self {
    case .clearHistory:
      return "Clear History"
    case .resetDrawCount:
      return "Reset Draw Count"
    case .resetAll:
      return "Restore Defaults"
    }
  }
}

#Preview {
  SettingsView(model: AppModel(), palette: AppTheme.dark.palette, theme: .dark, onToggleTheme: {})
}
