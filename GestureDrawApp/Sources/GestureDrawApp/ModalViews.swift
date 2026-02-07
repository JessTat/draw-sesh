import SwiftUI

struct MissingImageInfo: Identifiable {
  let id = UUID()
  let path: String

  var fileName: String {
    URL(fileURLWithPath: path).lastPathComponent
  }

  var folderPath: String {
    URL(fileURLWithPath: path).deletingLastPathComponent().path
  }

  var message: String {
    "The image file could not be found.\n\nFile: \(fileName)\nFolder: \(folderPath)"
  }
}

struct InfoModal: View {
  let palette: Palette
  let title: String
  let message: String
  let buttonTitle: String
  let onDismiss: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.6)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 12) {
        Text(title)
          .font(.system(size: 16, weight: .bold))

        Text(message)
          .font(.system(size: 12))
          .foregroundStyle(palette.muted)

        HStack {
          BWButton(title: buttonTitle, minHeight: 28, fontSize: 11) {
            onDismiss()
          }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 16)
      }
      .padding(16)
      .frame(maxWidth: 360)
      .background(palette.panel)
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
    }
  }
}
