import SwiftUI
import AppKit

struct HistoryView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  @State private var pendingDeleteId: UUID? = nil
  @State private var pendingDeleteInfo: String = ""
  @State private var sectionOffsets: [Date: CGFloat] = [:]
  @State private var logScrollView: NSScrollView? = nil

  private let grid = [GridItem(.adaptive(minimum: 60), spacing: 10)]
  private let calendar = Calendar.current
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }()
  private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()

  private var sections: [HistorySection] {
    let logs = model.history.sorted { $0.start > $1.start }
    let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.start) }
    let dates = grouped.keys.sorted(by: >)

    return dates.map { date in
      let logsForDate = (grouped[date] ?? []).sorted { $0.start > $1.start }
      let totalSeconds = logsForDate.reduce(0.0) { $0 + max(0, $1.end.timeIntervalSince($1.start)) }
      let entries = logsForDate.map { log in
        HistoryEntry(
          id: log.id,
          time: timeFormatter.string(from: log.start),
          sessionLength: sessionLengthLabel(for: log),
          timer: timerLabel(for: log),
          count: countLabel(for: log),
          imagePaths: imagePaths(for: log)
        )
      }
      return HistorySection(
        id: date,
        date: date,
        label: dateFormatter.string(from: date),
        totalLabel: sessionLengthLabel(forSeconds: totalSeconds),
        entries: entries
      )
    }
  }

  var body: some View {
    ZStack {
      HStack(alignment: .top, spacing: 20) {
        VStack(alignment: .leading, spacing: 16) {
          Text("Log")
            .font(.system(size: 20, weight: .bold))

          ScrollView {
          ScrollViewFinder { scrollView in
            logScrollView = scrollView
          }
          .frame(height: 0)

            if sections.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("No sessions yet.")
                  .font(.system(size: 14, weight: .semibold))
                Text("Complete a session to see it listed here.")
                  .font(.system(size: 12))
                  .foregroundStyle(palette.muted)
                Spacer(minLength: 0)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
              .padding(.top, 8)
            } else {
              VStack(spacing: 20) {
                ForEach(sections) { section in
                  VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                      Text(section.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(palette.text)
                      Spacer()
                      Text("Total session time: \(section.totalLabel)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.muted)
                    }
                    .padding(.trailing, 12)

                      VStack(spacing: 16) {
                        ForEach(section.entries) { entry in
                        HistoryCard(
                          entry: entry,
                          palette: palette,
                          grid: grid,
                          onStartSession: { imagePath in
                            model.startSession(with: imagePath)
                          },
                          onDeleteRequest: { logId in
                            pendingDeleteId = logId
                            pendingDeleteInfo = "\(entry.time) · \(entry.timer) x \(entry.count)"
                          }
                        )
                      }
                    }
                    .padding(.trailing, 12)
                  }
                  .background(
                    GeometryReader { proxy in
                      Color.clear.preference(
                        key: HistorySectionOffsetKey.self,
                        value: [section.id: proxy.frame(in: .named("historyScroll")).minY]
                      )
                    }
                  )
                }
              }
              .padding(.top, 8)
            }
          }
          .coordinateSpace(name: "historyScroll")
          .onPreferenceChange(HistorySectionOffsetKey.self) { offsets in
            sectionOffsets = offsets
          }
          .padding(.trailing, -12)
          .thinScrollIndicators()
          .frame(maxHeight: .infinity)
        }
        .padding(20)
        .background(palette.panel)
        .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)

        HistorySidePanel(
          palette: palette,
          logs: model.history,
          onDateSelected: { date in
            scrollToDate(date)
          }
        )
          .padding(20)
          .background(palette.panel)
          .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
          .frame(width: 360)
          .frame(maxHeight: .infinity, alignment: .top)
      }
      .padding(20)
      .background(palette.background)
      .frame(maxHeight: .infinity)

      if let deleteId = pendingDeleteId {
        ConfirmationModal(
          palette: palette,
          title: "Delete entry?",
          message: "\(pendingDeleteInfo)\nThis will remove the session from the log.",
          confirmTitle: "Delete",
          onCancel: {
            pendingDeleteId = nil
            pendingDeleteInfo = ""
          },
          onConfirm: {
            model.deleteHistoryLog(id: deleteId)
            pendingDeleteId = nil
            pendingDeleteInfo = ""
          }
        )
      }
    }
  }

  private func timerLabel(for log: SessionLog) -> String {
    guard log.isTimed, log.minutesPerImage > 0 else { return "∞" }
    return "\(log.minutesPerImage) min"
  }

  private func countLabel(for log: SessionLog) -> String {
    if let target = log.targetCount {
      return "\(target)"
    }
    let count = log.imageIds.count
    return "\(count)"
  }

  private func imagePaths(for log: SessionLog) -> [String] {
    var seen = Set<String>()
    var paths: [String] = []
    for id in log.imageIds {
      if seen.contains(id) { continue }
      seen.insert(id)
      paths.append(id)
    }
    return paths
  }

  private func sessionLengthLabel(for log: SessionLog) -> String {
    sessionLengthLabel(forSeconds: max(0, log.end.timeIntervalSince(log.start)))
  }

  private func sessionLengthLabel(forSeconds seconds: Double) -> String {
    let totalMinutes = Int(seconds / 60)
    if totalMinutes < 1 {
      return "<1 min"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 {
      return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    return "\(minutes) min"
  }

  private func scrollToDate(_ date: Date) {
    let target = calendar.startOfDay(for: date)
    guard let scrollView = logScrollView else { return }
    guard let offset = sectionOffsets[target] else { return }
    let currentOrigin = scrollView.contentView.bounds.origin.y
    let targetOrigin = currentOrigin + offset
    let point = NSPoint(x: 0, y: targetOrigin)
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.25
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      scrollView.contentView.animator().setBoundsOrigin(point)
    } completionHandler: {
      scrollView.reflectScrolledClipView(scrollView.contentView)
    }
  }

}

struct HistoryEntry: Identifiable {
  let id: UUID
  let time: String
  let sessionLength: String
  let timer: String
  let count: String
  let imagePaths: [String]
}

struct HistorySection: Identifiable {
  let id: Date
  let date: Date
  let label: String
  let totalLabel: String
  let entries: [HistoryEntry]
}

struct HistoryCard: View {
  let entry: HistoryEntry
  let palette: Palette
  let grid: [GridItem]
  let onStartSession: (String) -> Void
  let onDeleteRequest: (UUID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text(entry.time)
            .fontWeight(.semibold)
            .padding(.bottom, 4)
          Text("\(entry.timer) x \(entry.count)")
            .font(.system(size: 14, weight: .bold))
          Text(entry.sessionLength)
            .font(.system(size: 11))
            .foregroundStyle(palette.muted)
          Spacer(minLength: 0)
          DeleteIconButton(palette: palette) {
            onDeleteRequest(entry.id)
          }
        }
        .font(.system(size: 12))
        .frame(width: 180, alignment: .leading)

        LazyVGrid(columns: grid, spacing: 10) {
          ForEach(entry.imagePaths, id: \.self) { path in
            ZStack {
              Rectangle()
                .fill(palette.previewBackground)
              ThumbnailView(path: path)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 90)
            .onHover { hovering in
              if hovering {
                NSCursor.pointingHand.set()
              } else {
                NSCursor.arrow.set()
              }
            }
            .onTapGesture(count: 2) {
              onStartSession(path)
            }
          }
        }
      }

    }
    .padding(16)
    .background(palette.panel)
    .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
  }
}

private struct HistoryLine: View {
  let title: String
  let value: String

  var body: some View {
    HStack(spacing: 4) {
      Text(title)
        .fontWeight(.semibold)
      Text(value)
        .fontWeight(.light)
    }
  }
}

private struct DeleteIconButton: View {
  let palette: Palette
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: "trash")
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(isHovering ? palette.text : palette.muted)
        .frame(width: 12, height: 12, alignment: .center)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}

struct HistorySidePanel: View {
  let palette: Palette
  let logs: [SessionLog]
  let onDateSelected: (Date) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      UsageCalendar(palette: palette, logs: logs, onDateSelected: onDateSelected)

      Text("Click on a date to navigate to those sessions")
        .font(.system(size: 11))
        .foregroundStyle(palette.muted)
        .frame(maxWidth: .infinity, alignment: .center)
    }
  }
}

struct ConfirmationModal: View {
  let palette: Palette
  let title: String
  let message: String
  let confirmTitle: String
  let onCancel: () -> Void
  let onConfirm: () -> Void

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

        HStack(spacing: 8) {
          BWButton(title: "Cancel", minHeight: 28, fontSize: 11) {
            onCancel()
          }
          BWButton(title: confirmTitle, minHeight: 28, fontSize: 11) {
            onConfirm()
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

struct UsageCalendar: View {
  let palette: Palette
  let logs: [SessionLog]
  let onDateSelected: (Date) -> Void

  @State private var displayedMonth: Date = Date()
  @Environment(\.colorScheme) private var scheme

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
  private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  private let calendar = Calendar.current

  private var calendarDays: [CalendarDay] {
    let monthStart = startOfMonth(for: displayedMonth)
    guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
    let daysInMonth = range.count
    let firstWeekday = calendar.component(.weekday, from: monthStart)
    let startOffset = max(0, firstWeekday - 1)
    let sessionDays = Set(sessionLogsForMonth().map { calendar.component(.day, from: $0.start) })

    var days: [CalendarDay] = []
    for index in 0..<42 {
      let dayNumber = index - startOffset + 1
      if dayNumber >= 1 && dayNumber <= daysInMonth {
        days.append(CalendarDay(day: "\(dayNumber)", hasSession: sessionDays.contains(dayNumber)))
      } else {
        days.append(CalendarDay(day: "", hasSession: false))
      }
    }
    return trimmedCalendarDays(days)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ZStack {
        HStack {
          HStack(spacing: 6) {
            BWButton(title: "", minWidth: 8, minHeight: 20, systemImage: "chevron.left", fontSize: 9) {
              shiftMonth(-1)
            }
            BWButton(title: "", minWidth: 8, minHeight: 20, systemImage: "chevron.right", fontSize: 9) {
              shiftMonth(1)
            }
          }

          Spacer()

          BWButton(title: "Today", minHeight: 24, fontSize: 10) {
            displayedMonth = Date()
          }
        }

        Text(monthLabel(for: displayedMonth))
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(palette.muted)
      }

      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(weekdayLabels, id: \.self) { label in
          Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(palette.muted)
            .frame(maxWidth: .infinity)
        }

        ForEach(calendarDays) { day in
          let isToday = isToday(day)
          let hasSession = day.hasSession
          if hasSession {
            calendarCell(day: day, isToday: isToday, isHovering: false)
              .overlay(
                MouseDownButton {
                  if let date = dateForDay(day) {
                    onDateSelected(date)
                  }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              )
          } else {
            calendarCell(day: day, isToday: isToday, isHovering: false)
          }
        }
      }
    }
    .padding(16)
    .background(palette.panel)
    .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
  }

  private func startOfMonth(for date: Date) -> Date {
    let comps = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: comps) ?? date
  }

  private func monthLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: date)
  }

  private func shiftMonth(_ value: Int) {
    if let next = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
      displayedMonth = next
    }
  }

  private func sessionLogsForMonth() -> [SessionLog] {
    let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
    return logs.filter { log in
      let logComps = calendar.dateComponents([.year, .month], from: log.start)
      return logComps.year == comps.year && logComps.month == comps.month
    }
  }

  private func dateForDay(_ day: CalendarDay) -> Date? {
    guard let dayNumber = Int(day.day) else { return nil }
    let monthStart = startOfMonth(for: displayedMonth)
    return calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)
  }

  @ViewBuilder
  private func calendarCell(day: CalendarDay, isToday: Bool, isHovering: Bool) -> some View {
    VStack(spacing: 4) {
      Text(day.day)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(palette.text)

      Circle()
        .fill(day.hasSession ? palette.text : Color.clear)
        .frame(width: 4, height: 4)
    }
    .frame(height: 30)
    .frame(maxWidth: .infinity)
    .background(day.hasSession && isHovering ? palette.panel : palette.panelAlt)
    .overlay(Rectangle().stroke(isToday ? (scheme == .light ? Color.black : Color.white) : palette.border, lineWidth: 1))
  }

  private func isToday(_ day: CalendarDay) -> Bool {
    guard let dayNumber = Int(day.day) else { return false }
    let monthStart = startOfMonth(for: displayedMonth)
    guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart) else {
      return false
    }
    return calendar.isDateInToday(date)
  }

  private func trimmedCalendarDays(_ days: [CalendarDay]) -> [CalendarDay] {
    var trimmed = days
    while trimmed.count >= 7 {
      let tail = trimmed.suffix(7)
      if tail.allSatisfy({ $0.day.isEmpty }) {
        trimmed.removeLast(7)
      } else {
        break
      }
    }
    return trimmed
  }
}

struct CalendarDay: Identifiable {
  let id = UUID()
  let day: String
  let hasSession: Bool
}

struct MouseDownButton: NSViewRepresentable {
  let onMouseDown: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onMouseDown: onMouseDown)
  }

  func makeNSView(context: Context) -> NSButton {
    let button = NSButton()
    button.title = ""
    button.isBordered = false
    button.setButtonType(.momentaryChange)
    button.target = context.coordinator
    button.action = #selector(Coordinator.handleMouseDown)
    button.sendAction(on: [.leftMouseDown])
    button.wantsLayer = true
    button.layer?.backgroundColor = NSColor.clear.cgColor
    return button
  }

  func updateNSView(_ nsView: NSButton, context: Context) {
    context.coordinator.onMouseDown = onMouseDown
  }

  final class Coordinator: NSObject {
    var onMouseDown: () -> Void

    init(onMouseDown: @escaping () -> Void) {
      self.onMouseDown = onMouseDown
    }

    @objc func handleMouseDown() {
      onMouseDown()
    }
  }
}

struct HistorySectionOffsetKey: PreferenceKey {
  static var defaultValue: [Date: CGFloat] = [:]

  static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })
  }
}

struct ScrollViewFinder: NSViewRepresentable {
  let onFind: (NSScrollView) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      if let scrollView = view.enclosingScrollView {
        onFind(scrollView)
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async {
      if let scrollView = nsView.enclosingScrollView {
        onFind(scrollView)
      }
    }
  }
}

#Preview {
  HistoryView(model: AppModel(), palette: AppTheme.dark.palette)
}
