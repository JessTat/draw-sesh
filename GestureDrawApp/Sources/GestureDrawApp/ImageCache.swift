import AppKit

final class ImageCache {
  static let shared = ImageCache()
  private let cache = NSCache<NSString, NSImage>()

  private init() {}

  func image(for path: String) -> NSImage? {
    cache.object(forKey: path as NSString)
  }

  func set(_ image: NSImage, for path: String) {
    cache.setObject(image, forKey: path as NSString)
  }
}
