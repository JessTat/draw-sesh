import SwiftUI
import AppKit

struct SummaryView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  private let columns = [
    GridItem(.adaptive(minimum: 140), spacing: 12)
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Session Summary")
        .font(.system(size: 22, weight: .bold))

      Text("Here are the drawings you completed this session.")
        .font(.system(size: 13))
        .foregroundStyle(palette.muted)

      HStack(spacing: 20) {
        SummaryStat(title: "Completed Drawings", value: "\(model.session?.completed ?? 0)")
        SummaryStat(title: "Skipped", value: "\(model.session?.skipped ?? 0)")
        SummaryStat(title: "Per Image", value: "\(model.minutes) min")
      }

      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(completedImages, id: \.id) { image in
            ZStack {
              Rectangle()
                .fill(palette.panelAlt)
              if let nsImage = NSImage(contentsOfFile: image.path) {
                Image(nsImage: nsImage)
                  .resizable()
                  .scaledToFit()
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              Rectangle().stroke(palette.border, lineWidth: 1)
            }
            .frame(height: 180)
          }
        }
        .padding(.top, 8)
      }
      .padding(.trailing, -12)
      .thinScrollIndicators()
      .frame(maxHeight: 320)
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))

      HStack(spacing: 10) {
        BWButton(title: "Finished", minHeight: 40, isSelected: true, expand: true) {
          model.resetToSetup()
        }
      }

      Spacer()
    }
    .padding(24)
    .background(palette.panel)
    .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
    .padding(20)
  }

  private var completedImages: [ImageItem] {
    guard let session = model.session else { return [] }
    let ids = Set(session.completedImages)
    return model.images.filter { ids.contains($0.id) }
  }
}

struct SummaryStat: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(value)
        .font(.system(size: 20, weight: .bold))
      Text(title)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  SummaryView(model: AppModel(), palette: AppTheme.dark.palette)
}
