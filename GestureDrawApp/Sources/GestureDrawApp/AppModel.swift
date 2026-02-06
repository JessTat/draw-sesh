import SwiftUI
import AppKit

final class AppModel: ObservableObject {
  @Published var screen: Screen = .setup
  @Published var images: [ImageItem] = []
  @Published var folderPath: String = "/Users/jess/Projects/26-01 Figure Drawing/Gestures"
  @Published var minutes: Int = 1
  @Published var count: Int = 10
  @Published var infinite: Bool = false
  @Published var prioritizeLowDraw: Bool = true
  @Published var session: SessionState? = nil

  private let defaultsKey = "gd-folder-path"
  private let allowedExtensions: Set<String> = ["jpg", "jpeg", "png", "webp"]

  init() {
    if let savedPath = UserDefaults.standard.string(forKey: defaultsKey) {
      folderPath = savedPath
    }
    loadImages(from: folderPath)
  }

  var includedImages: [ImageItem] {
    images.filter { $0.included }
  }

  var activeImage: ImageItem? {
    guard let session else { return nil }
    let id = session.sequence[session.index]
    return images.first(where: { $0.id == id })
  }

  func pickFolder() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.begin { [weak self] response in
      guard response == .OK, let url = panel.url else { return }
      self?.setFolder(url.path)
    }
  }

  func setFolder(_ path: String) {
    folderPath = path
    UserDefaults.standard.set(path, forKey: defaultsKey)
    loadImages(from: path)
  }

  func toggleInclude(for imageId: String, included: Bool) {
    guard let index = images.firstIndex(where: { $0.id == imageId }) else { return }
    images[index].included = included
    saveMetadata()
  }

  func setAllIncluded(_ included: Bool) {
    images = images.map { item in
      var updated = item
      updated.included = included
      return updated
    }
    saveMetadata()
  }

  func clearDrawHistory() {
    images = images.map { item in
      var updated = item
      updated.drawnCount = 0
      return updated
    }
    saveMetadata()
  }

  func adjustCount(_ value: Int) {
    count = min(20, max(2, value))
  }

  func startSession() {
    let pool = includedImages
    guard !pool.isEmpty else { return }

    let target: SessionTarget = infinite ? .infinite : .count(count)
    let sequence = buildSequence(from: pool, target: target)

    session = SessionState(
      status: .running,
      sequence: sequence,
      index: 0,
      remainingSec: minutes * 60,
      completed: 0,
      skipped: 0,
      target: target,
      minutesPerImage: minutes,
      completedImages: [],
      isTimed: minutes > 0
    )
    screen = .session
  }

  func startSession(with imageId: String) {
    guard images.contains(where: { $0.id == imageId }) else { return }
    infinite = true
    let target: SessionTarget = .infinite

    session = SessionState(
      status: .running,
      sequence: [imageId],
      index: 0,
      remainingSec: minutes * 60,
      completed: 0,
      skipped: 0,
      target: target,
      minutesPerImage: minutes,
      completedImages: [],
      isTimed: false
    )
    screen = .session
  }

  func tick() {
    guard var current = session, current.status == .running else { return }
    guard current.isTimed else { return }
    if current.remainingSec > 1 {
      current.remainingSec -= 1
      session = current
      return
    }
    advance(countCurrent: true)
  }

  func advance(countCurrent: Bool) {
    guard var current = session else { return }
    let currentId = current.sequence[current.index]

    if countCurrent {
      current.completed += 1
      current.completedImages.append(currentId)
      incrementDrawCount(for: currentId)
    } else {
      current.skipped += 1
    }

    if case .count(let limit) = current.target, current.completed >= limit {
      current.status = .paused
      current.remainingSec = 0
      session = nil
      screen = .setup
      return
    }

    current.index += 1
    if current.index >= current.sequence.count {
      let nextId = pickRandomIncludedId() ?? currentId
      current.sequence.append(nextId)
    }
    current.remainingSec = current.minutesPerImage * 60
    session = current
  }

  func previous() {
    guard var current = session else { return }
    if current.index == 0 { return }
    current.index -= 1
    current.remainingSec = current.minutesPerImage * 60
    session = current
  }

  func togglePause() {
    guard var current = session else { return }
    current.status = current.status == .running ? .paused : .running
    session = current
  }

  func stopSession() {
    session = nil
    screen = .setup
  }

  func resetToSetup() {
    session = nil
    screen = .setup
  }

  private func incrementDrawCount(for imageId: String) {
    guard let index = images.firstIndex(where: { $0.id == imageId }) else { return }
    images[index].drawnCount += 1
    saveMetadata()
  }

  private func pickRandomIncludedId() -> String? {
    let pool = includedImages
    guard !pool.isEmpty else { return nil }
    return pickFromPool(pool).id
  }

  private func buildSequence(from pool: [ImageItem], target: SessionTarget) -> [String] {
    switch target {
    case .count(let limit):
      let initialCount = min(limit, pool.count)
      var remaining = pool
      var sequence: [String] = []
      while sequence.count < initialCount {
        let pick = pickFromPool(remaining)
        sequence.append(pick.id)
        remaining.removeAll { $0.id == pick.id }
      }
      while sequence.count < limit {
        if let next = pickRandomIncludedId() {
          sequence.append(next)
        } else {
          break
        }
      }
      return sequence
    case .infinite:
      return [pickFromPool(pool).id]
    }
  }

  private func pickFromPool(_ pool: [ImageItem]) -> ImageItem {
    if prioritizeLowDraw {
      return weightedPick(from: pool)
    }
    return pool.randomElement() ?? pool[0]
  }

  private func weightedPick(from pool: [ImageItem]) -> ImageItem {
    let weights = pool.map { 1.0 / Double(max(0, $0.drawnCount) + 1) }
    let total = weights.reduce(0, +)
    let r = Double.random(in: 0..<total)
    var cumulative: Double = 0
    for (index, weight) in weights.enumerated() {
      cumulative += weight
      if r <= cumulative {
        return pool[index]
      }
    }
    return pool.last ?? pool[0]
  }

  private func loadImages(from folder: String) {
    let urls = scanImages(in: folder)
    let metadata = loadMetadata()

    images = urls.map { url in
      let path = url.path
      let record = metadata[path]
      return ImageItem(
        path: path,
        included: record?.included ?? true,
        drawnCount: record?.drawnCount ?? 0
      )
    }

    saveMetadata()
  }

  private func scanImages(in folder: String) -> [URL] {
    let folderURL = URL(fileURLWithPath: folder)
    guard let enumerator = FileManager.default.enumerator(
      at: folderURL,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else {
      return []
    }

    var results: [URL] = []
    for case let url as URL in enumerator {
      let ext = url.pathExtension.lowercased()
      if allowedExtensions.contains(ext) {
        results.append(url)
      }
    }

    return results.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
  }

  private func metadataURL() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let dir = base.appendingPathComponent("GestureDrawApp", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir.appendingPathComponent("metadata.json")
  }

  private func loadMetadata() -> [String: ImageRecord] {
    let url = metadataURL()
    guard let data = try? Data(contentsOf: url) else { return [:] }
    guard let records = try? JSONDecoder().decode([ImageRecord].self, from: data) else { return [:] }
    return Dictionary(uniqueKeysWithValues: records.map { ($0.path, $0) })
  }

  private func saveMetadata() {
    let records = images.map {
      ImageRecord(path: $0.path, included: $0.included, drawnCount: $0.drawnCount)
    }
    guard let data = try? JSONEncoder().encode(records) else { return }
    try? data.write(to: metadataURL(), options: .atomic)
  }
}
