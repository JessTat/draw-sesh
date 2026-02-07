import SwiftUI

struct HistoryView: View {
  @ObservedObject var model: AppModel
  let palette: Palette

  @State private var pendingAction: HistoryAction? = nil

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
          time: timeFormatter.string(from: log.start),
          sessionLength: sessionLengthLabel(for: log),
          timer: timerLabel(for: log),
          count: countLabel(for: log),
          imagePaths: imagePaths(for: log)
        )
      }
      return HistorySection(
        date: date,
        label: dateFormatter.string(from: date),
        totalLabel: sessionLengthLabel(forSeconds: totalSeconds),
        entries: entries
      )
    }
  }

  var body: some View {
    ZStack {
      ScrollViewReader { proxy in
        HStack(alignment: .top, spacing: 20) {
          VStack(alignment: .leading, spacing: 16) {
            Text("Log")
              .font(.system(size: 20, weight: .bold))

            ScrollView {
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

                      VStack(spacing: 16) {
                        ForEach(section.entries) { entry in
                          HistoryCard(
                            entry: entry,
                            palette: palette,
                            grid: grid,
                            onStartSession: { imagePath in
                              model.startSession(with: imagePath)
                            }
                          )
                        }
                      }
                    }
                    .id(section.id)
                  }
                }
                .padding(.top, 8)
              }
            }
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
              if let match = sections.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                withAnimation(.easeInOut(duration: 0.25)) {
                  proxy.scrollTo(match.id, anchor: .top)
                }
              }
            },
            onAction: { action in
              pendingAction = action
            }
          )
            .padding(20)
            .background(palette.panel)
            .overlay(Rectangle().stroke(palette.border, lineWidth: 1))
            .frame(width: 360)
            .frame(maxHeight: .infinity, alignment: .top)
        }
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

  private func handleAction(_ action: HistoryAction) {
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

struct HistoryEntry: Identifiable {
  let id = UUID()
  let time: String
  let sessionLength: String
  let timer: String
  let count: String
  let imagePaths: [String]
}

struct HistorySection: Identifiable {
  let id = UUID()
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

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          HistoryLine(title: entry.time, value: "")
            .padding(.bottom, 4)
          HistoryLine(title: "Session:", value: entry.sessionLength)
          HistoryLine(title: "Timer:", value: entry.timer)
          HistoryLine(title: "Images:", value: entry.count)
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

struct HistorySidePanel: View {
  let palette: Palette
  let logs: [SessionLog]
  let onDateSelected: (Date) -> Void
  let onAction: (HistoryAction) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Summary")
        .font(.system(size: 20, weight: .bold))

      UsageCalendar(palette: palette, logs: logs, onDateSelected: onDateSelected)

      Divider()

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
            onAction(.clearHistory)
          }
          BWButton(
            title: "Reset Draw Count",
            minHeight: 24,
            fillColor: palette.panelAlt,
            textColor: palette.muted,
            borderColor: palette.border,
            fontSize: 10
          ) {
            onAction(.resetDrawCount)
          }
          BWButton(
            title: "Reset All",
            minHeight: 24,
            fillColor: palette.panelAlt,
            textColor: palette.muted,
            borderColor: palette.border,
            fontSize: 10
          ) {
            onAction(.resetAll)
          }
        }
      }
    }
  }
}

enum HistoryAction: String, Identifiable {
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
          let isEmpty = day.day.isEmpty
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
          .background(palette.panelAlt)
          .overlay(Rectangle().stroke(isToday ? (scheme == .light ? Color.black : Color.white) : palette.border, lineWidth: 1))
          .contentShape(Rectangle())
          .onTapGesture {
            if let date = dateForDay(day) {
              onDateSelected(date)
            }
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

#Preview {
  HistoryView(model: AppModel(), palette: AppTheme.dark.palette)
}
