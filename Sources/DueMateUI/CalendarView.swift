import DueMateCore
import SwiftUI

struct CalendarFeatureView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            VStack(spacing: AppSpacing.medium) {
                monthHeader
                weekdayHeader
                monthGrid
                Divider()
                dayList
            }
            .padding(AppSpacing.medium)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") {
                        session.selectedCalendarDate = .today
                    }
                }
            }
        }
    }

    private var month: CalendarDate { session.selectedCalendarDate.startOfMonth() }

    private var monthHeader: some View {
        HStack {
            Button {
                session.selectedCalendarDate = month.adding(months: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(Formatters.monthYear(month))
                .font(.title3.weight(.semibold))
            Spacer()
            Button {
                session.selectedCalendarDate = month.adding(months: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(Formatters.weekdaySymbols(weekStart: session.snapshot.settings.weekStart), id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var monthGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func dayCell(_ day: CalendarDate) -> some View {
        let selected = day == session.selectedCalendarDate
        let isToday = day == CalendarDate.today
        let marks = markers(on: day)
        return Button {
            session.selectedCalendarDate = day
        } label: {
            VStack(spacing: 4) {
                Text("\(day.day)")
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .frame(width: 32, height: 32)
                    .background(selected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.15) : Color.clear), in: Circle())
                HStack(spacing: 2) {
                    ForEach(marks.prefix(3), id: \.self) { token in
                        Circle()
                            .fill(AppColors.token(token))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.day), \(marks.count) obligations")
    }

    private var dayList: some View {
        let items = session.records(TaskQuery(from: session.selectedCalendarDate, to: session.selectedCalendarDate))
        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(Formatters.date(session.selectedCalendarDate, style: .full))
                .font(.headline)
            if items.isEmpty {
                EmptyStateView(title: "No payments due", systemImage: "calendar", message: "Nothing scheduled for this day.")
            } else {
                ForEach(items) { record in
                    NavigationLink {
                        OccurrenceDetailView(record: record)
                    } label: {
                        ObligationRow(record: record)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        if record.occurrence.status != .paid {
                            Button("Mark Paid") { session.pendingPayment = record }
                                .tint(.green)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markers(on day: CalendarDate) -> [String] {
        session.records(TaskQuery(from: day, to: day)).map(\.obligation.colorToken)
    }

    private func daysInMonth() -> [CalendarDate?] {
        var calendar = Calendar.current
        switch session.snapshot.settings.weekStart {
        case .monday: calendar.firstWeekday = 2
        case .sunday: calendar.firstWeekday = 1
        case .deviceDefault: break
        }
        let start = month
        guard let startDate = start.foundationDate(in: calendar),
              let range = calendar.range(of: .day, in: .month, for: startDate) else { return [] }
        let weekday = calendar.component(.weekday, from: startDate)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var days: [CalendarDate?] = Array(repeating: nil, count: leading)
        for day in 1...range.count {
            days.append(CalendarDate(year: start.year, month: start.month, day: day))
        }
        return days
    }
}
