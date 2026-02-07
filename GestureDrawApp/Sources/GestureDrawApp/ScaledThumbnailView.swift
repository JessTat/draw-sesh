import SwiftUI
import AppKit

struct ScaledThumbnailView: View {
  let path: String
  let maxSize: CGFloat
  @State private var image: NSImage? = nil
  @State private var isMissing: Bool = false

  var body: some View {
    Group {
      if let image {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
      } else if isMissing {
        Image(systemName: "questionmark.square.dashed")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Color.secondary)
      } else {
        Color.clear
      }
    }
    .onAppear {
      loadImage()
    }
    .onChange(of: path) { _ in
      loadImage()
    }
    .onChange(of: maxSize) { _ in
      loadImage()
    }
  }

  private func loadImage() {
    if let cached = ThumbnailCache.shared.image(for: path, size: maxSize) {
      image = cached
      isMissing = false
      return
    }

    isMissing = false
    DispatchQueue.global(qos: .userInitiated).async {
      let loaded = NSImage(contentsOfFile: path)
      let scaled = loaded.map { downscale($0, maxSize: maxSize) }
      if let scaled {
        ThumbnailCache.shared.set(scaled, for: path, size: maxSize)
      }
      DispatchQueue.main.async {
        image = scaled
        isMissing = scaled == nil
      }
    }
  }

  private func downscale(_ image: NSImage, maxSize: CGFloat) -> NSImage {
    let original = image.size
    let ratio = min(maxSize / original.width, maxSize / original.height, 1)
    let newSize = NSSize(width: original.width * ratio, height: original.height * ratio)
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: newSize),
               from: NSRect(origin: .zero, size: original),
               operation: .copy,
               fraction: 1)
    newImage.unlockFocus()
    return newImage
  }
}
