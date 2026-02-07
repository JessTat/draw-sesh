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

final class ThumbnailCache {
  static let shared = ThumbnailCache()
  private let cache = NSCache<NSString, NSImage>()

  private init() {}

  func image(for path: String, size: CGFloat) -> NSImage? {
    cache.object(forKey: cacheKey(path: path, size: size))
  }

  func set(_ image: NSImage, for path: String, size: CGFloat) {
    cache.setObject(image, forKey: cacheKey(path: path, size: size))
  }

  private func cacheKey(path: String, size: CGFloat) -> NSString {
    "\(path)#\(Int(size))" as NSString
  }
}
