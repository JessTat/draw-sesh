import SwiftUI

struct ImageItem: Identifiable, Hashable {
  let id: String
  let path: String
  var included: Bool
  var drawnCount: Int

  init(path: String, included: Bool = true, drawnCount: Int = 0) {
    self.path = path
    self.id = path
    self.included = included
    self.drawnCount = drawnCount
  }

  var name: String {
    URL(fileURLWithPath: path).lastPathComponent
  }
}

struct ImageRecord: Codable {
  var path: String
  var included: Bool
  var drawnCount: Int
}

enum SessionStatus {
  case running
  case paused
}

enum SessionTarget: Hashable {
  case count(Int)
  case infinite

  var label: String {
    switch self {
    case .count(let value):
      return String(value)
    case .infinite:
      return "∞"
    }
  }
}

struct SessionState {
  var status: SessionStatus
  var sequence: [String]
  var index: Int
  var remainingSec: Int
  var completed: Int
  var skipped: Int
  var target: SessionTarget
  var minutesPerImage: Int
  var completedImages: [String]
  var isTimed: Bool
  var startedAt: Date
  var shownImages: [String]
}

struct SessionLog: Identifiable, Codable {
  let id: UUID
  let start: Date
  let end: Date
  let minutesPerImage: Int
  let targetCount: Int?
  let isInfinite: Bool
  let isTimed: Bool
  let imageIds: [String]
}
