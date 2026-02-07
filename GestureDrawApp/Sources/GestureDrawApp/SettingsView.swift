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
        VStack(alignment: .leading, spacing: 16) {
          Text("Settings")
            .font(.system(size: 20, weight: .bold))

          VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(palette.muted)

            BWButton(
              title: "Toggle Light/Dark",
              minHeight: 24,
              fillColor: palette.panelAlt,
              textColor: palette.muted,
              borderColor: palette.border,
              fontSize: 10
            ) {
              onToggleTheme()
            }
          }

          VStack(alignment: .leading, spacing: 10) {
            Text("History Actions")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(palette.muted)

            HStack(spacing: 8) {
              BWButton(
                title: "Clear History",
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
                title: "Reset All",
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

          VStack(alignment: .leading, spacing: 10) {
            Text("Additional Settings")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(palette.muted)

            Toggle("Prioritize lesser-drawn images", isOn: $model.prioritizeLowDraw)
              .toggleStyle(.checkbox)
              .tint(Color(white: 0.6))
              .accentColor(Color(white: 0.6))
          }

          Divider()

          VStack(alignment: .leading, spacing: 10) {
            Text("How to Use")
              .font(.system(size: 16, weight: .bold))

            Text("This app is for timed drawing sessions using your local library of reference images.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)

            VStack(alignment: .leading, spacing: 4) {
              Text("90min figure drawing session example:")
                .font(.system(size: 12, weight: .semibold))
              Text("1m x 10")
              Text("2m x 5")
              Text("3m x 5")
              Text("5m x 5")
              Text("10m x 3 or 15m x 2")
            }
            .font(.system(size: 12))
            .foregroundStyle(palette.text)

            Text("Begin this session focusing on gestures that capture the action. As the sessions get longer, introduce intentional rhythms and eventually carving out anatomical structures.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
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
      return "Reset All?"
    }
  }

  var message: String {
    switch self {
    case .clearHistory:
      return "This will clear all the sessions logged."
    case .resetDrawCount:
      return "This will reset the draw count logged for every image. This information is used to weight the randomization of images towards the lesser-drawn images."
    case .resetAll:
      return "This will clear history, reset draw counts, and remove the selected folder."
    }
  }

  var confirmTitle: String {
    switch self {
    case .clearHistory:
      return "Clear History"
    case .resetDrawCount:
      return "Reset Draw Count"
    case .resetAll:
      return "Reset All"
    }
  }
}

#Preview {
  SettingsView(model: AppModel(), palette: AppTheme.dark.palette, theme: .dark, onToggleTheme: {})
}
