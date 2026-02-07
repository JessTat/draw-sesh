import SwiftUI
import AppKit

struct SetupView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  @State private var thumbnailSize: CGFloat = 160
  @State private var customMinutesText: String = "1"

  private let presetMinutes = [1, 2, 3, 5, 10, 15]

  private var gridColumns: [GridItem] {
    [GridItem(.adaptive(minimum: thumbnailSize), spacing: 14)]
  }

  private var thumbnailHeight: CGFloat {
    thumbnailSize * 1.33
  }

  var body: some View {
    HStack(alignment: .top, spacing: 20) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Image Library")
              .font(.system(size: 20, weight: .bold))
            Spacer()
            Text("\(model.includedImages.count)/\(model.images.count) images selected")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(palette.muted)
          }

          HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
              Text(model.folderPath)
                .font(.system(size: 12))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 40)
                .background(palette.panelAlt)
                .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
            }
            BWButton(title: "Choose Folder", isPrimary: true, minHeight: 28) {
              model.pickFolder()
            }
          }

          HStack(spacing: 10) {
            BWButton(title: "Select All", minHeight: 24) {
              model.setAllIncluded(true)
            }
            BWButton(title: "Deselect All", minHeight: 24) {
              model.setAllIncluded(false)
            }
            Spacer()
            BWButton(title: "Smaller", minHeight: 24, systemImage: "minus.magnifyingglass") {
              thumbnailSize = max(120, thumbnailSize - 20)
            }
            BWButton(title: "Larger", minHeight: 24, systemImage: "plus.magnifyingglass") {
              thumbnailSize = min(240, thumbnailSize + 20)
            }
          }
        }

        if model.images.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("No images found in this folder.")
              .font(.system(size: 14, weight: .semibold))
            Text("Choose a folder containing the images you wish to randomly cycle through in this drawing session. This app only supports JPG, PNG, and WEBP files.")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
          }
          .padding(.top, 8)
        } else {
          ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 14) {
              ForEach(model.images) { image in
                ImageCard(
                  image: image,
                  palette: palette,
                  height: thumbnailHeight,
                  onIncludeToggle: { isIncluded in
                    model.toggleInclude(for: image.id, included: isIncluded)
                  },
                  onStartSession: {
                    model.startSession(with: image.id)
                  }
                )
              }
            }
            .padding(.top, 8)
          }
          .thinScrollIndicators()
          .frame(maxHeight: .infinity)
          .padding(.trailing, -8)
        }
      }
      .padding(20)
      .background(palette.panel)
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
      .frame(maxHeight: .infinity, alignment: .top)

      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("Settings")
            .font(.system(size: 20, weight: .bold))
          Spacer()
        }

        VStack(alignment: .leading, spacing: 10) {
          Text("Timer")
            .font(.system(size: 13, weight: .semibold))

          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(presetMinutes, id: \.self) { minute in
              BWButton(
                title: "\(minute) min",
                minWidth: 76,
                minHeight: 32,
                isSelected: model.minutes == minute
              ) {
                model.minutes = minute
                customMinutesText = "\(minute)"
              }
            }
          }

          HStack(spacing: 10) {
            Text("Custom")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
            NoSelectTextField(text: $customMinutesText, placeholder: "min")
              .padding(8)
              .frame(width: 36)
              .background(palette.panelAlt)
              .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
            Text("min")
              .font(.system(size: 12))
              .foregroundStyle(palette.muted)
            BWButton(title: "No Timer", minHeight: 32, isSelected: model.minutes == 0) {
              model.minutes = 0
              customMinutesText = "0"
            }
          }
        }

        VStack(alignment: .leading, spacing: 10) {
          Text("Image Count")
            .font(.system(size: 13, weight: .semibold))
          HStack(spacing: 10) {
            BWButton(title: "-", minWidth: 24, minHeight: 24) { model.adjustCount(model.count - 1) }
            Text(model.infinite ? "∞" : "\(model.count)")
              .font(.system(size: 14, weight: .semibold))
            BWButton(title: "+", minWidth: 24, minHeight: 24) { model.adjustCount(model.count + 1) }
            BWButton(title: "Infinite", minHeight: 24, isSelected: model.infinite) {
              model.infinite.toggle()
            }
          }
        }

        Divider()

        VStack(alignment: .leading, spacing: 10) {
          Text("Additional Settings")
            .font(.system(size: 13, weight: .semibold))
          Toggle("Prioritize lesser-drawn images", isOn: $model.prioritizeLowDraw)
            .toggleStyle(.checkbox)
            .tint(Color(white: 0.6))
            .accentColor(Color(white: 0.6))
        }

        Spacer()

        BWButton(title: "Start Session", minHeight: 44, isSelected: true, expand: true, fontSize: 20, fontWeight: .bold) {
          model.startSession()
        }
        Text("Double click on any image to start a session with only that image.")
          .font(.system(size: 11))
          .foregroundStyle(palette.muted)
          .frame(maxWidth: .infinity)
          .multilineTextAlignment(.center)
      }
      .padding(20)
      .background(palette.panel)
      .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
      .frame(width: 360)
    }
    .padding(20)
    .background(palette.background)
    .frame(maxHeight: .infinity)
    .onAppear {
      customMinutesText = "\(model.minutes)"
    }
    .onChange(of: customMinutesText) { newValue in
      let filtered = newValue.filter { $0.isNumber }
      let limited = String(filtered.prefix(3))
      if limited != newValue {
        customMinutesText = limited
        return
      }
      if let value = Int(limited) {
        model.minutes = value
      }
    }
  }
}

struct ImageCard: View {
  let image: ImageItem
  let palette: Palette
  let height: CGFloat
  let onIncludeToggle: (Bool) -> Void
  let onStartSession: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ZStack {
        Rectangle()
          .fill(palette.previewBackground)
        ThumbnailView(path: image.path)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(height: height)
      .onHover { hovering in
        if hovering {
          NSCursor.pointingHand.set()
        } else {
          NSCursor.arrow.set()
        }
      }
      .gesture(
        ExclusiveGesture(
          TapGesture(count: 2).onEnded { onStartSession() },
          TapGesture(count: 1).onEnded { onIncludeToggle(!image.included) }
        )
      )

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(image.name)
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)
            .truncationMode(.tail)
          Spacer()
          Toggle("", isOn: Binding(
            get: { image.included },
            set: { onIncludeToggle($0) }
          ))
          .labelsHidden()
          .toggleStyle(.checkbox)
          .tint(Color(white: 0.6))
          .accentColor(Color(white: 0.6))
        }

        if image.drawnCount > 0 {
          Text("Drawn \(image.drawnCount)x")
            .font(.system(size: 11))
            .foregroundStyle(palette.muted)
        } else {
          Text(" ")
            .font(.system(size: 11))
            .foregroundStyle(.clear)
        }
      }
      .frame(minHeight: 32)
    }
    .padding(8)
    .background(palette.panelAlt)
    .opacity(image.included ? 1 : 0.45)
  }
}

struct NoSelectTextField: NSViewRepresentable {
  @Binding var text: String
  let placeholder: String

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  func makeNSView(context: Context) -> NSTextField {
    let field = NSTextField(string: text)
    field.isBordered = false
    field.isBezeled = false
    field.drawsBackground = false
    field.focusRingType = .none
    field.usesSingleLineMode = true
    field.cell?.wraps = false
    field.cell?.isScrollable = true
    field.placeholderString = placeholder
    field.delegate = context.coordinator
    return field
  }

  func updateNSView(_ nsView: NSTextField, context: Context) {
    if nsView.stringValue != text {
      nsView.stringValue = text
    }
  }

  class Coordinator: NSObject, NSTextFieldDelegate {
    @Binding var text: String

    init(text: Binding<String>) {
      _text = text
    }

    func controlTextDidChange(_ obj: Notification) {
      guard let field = obj.object as? NSTextField else { return }
      text = field.stringValue
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
      guard let field = obj.object as? NSTextField else { return }
      if let editor = field.currentEditor() {
        editor.selectedRange = NSRange(location: editor.string.count, length: 0)
      }
    }
  }
}

struct ThumbnailView: View {
  let path: String

  var body: some View {
    if let image = NSImage(contentsOfFile: path) {
      Image(nsImage: image)
        .resizable()
        .scaledToFit()
    } else {
      Color.clear
    }
  }
}

#Preview {
  SetupView(model: AppModel(), palette: AppTheme.dark.palette)
}
