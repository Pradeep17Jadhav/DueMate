import Foundation

/// Generates civil dates from a recurrence rule using Foundation Calendar.
/// Does not pre-generate unbounded series; callers pass an inclusive horizon.
public struct RecurrenceService: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        var calendar = calendar
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        self.calendar = calendar
    }

    public func dates(
        from start: CalendarDate,
        rule: RecurrenceRule,
        through horizon: CalendarDate
    ) -> [CalendarDate] {
        let end = min(horizon, rule.endDate ?? horizon)
        guard start <= end else { return [] }

        var results: [CalendarDate] = []
        var cursor = alignedStart(start, rule: rule)
        var safety = 0

        while cursor < start {
            guard let next = advancing(cursor, rule: rule), next > cursor else { return [] }
            cursor = next
            safety += 1
            if safety > 48 { return [] }
        }

        safety = 0
        while cursor <= end {
            results.append(cursor)
            guard let next = advancing(cursor, rule: rule) else { break }
            if next <= cursor { break }
            cursor = next
            safety += 1
            if safety > 2_000 { break }
        }
        return results
    }

    public func nextDate(after date: CalendarDate, rule: RecurrenceRule, start: CalendarDate) -> CalendarDate? {
        let horizon = date.adding(days: 366 * 5, calendar: calendar)
        return dates(from: start, rule: rule, through: horizon).first { $0 > date }
    }

    private func alignedStart(_ start: CalendarDate, rule: RecurrenceRule) -> CalendarDate {
        switch rule.frequency {
        case .daily:
            return start
        case .weekly:
            guard let weekday = rule.weekday else { return start }
            return nextMatchingWeekday(onOrAfter: start, weekday: weekday)
        case .monthly:
            return dateInMonth(
                year: start.year,
                month: start.month,
                dayOfMonth: rule.dayOfMonth ?? start.day
            )
        case .yearly:
            let month = rule.monthOfYear ?? start.month
            let day = rule.dayOfMonth ?? start.day
            var candidate = dateInMonth(year: start.year, month: month, dayOfMonth: day)
            if candidate < start {
                candidate = dateInMonth(year: start.year + 1, month: month, dayOfMonth: day)
            }
            return candidate
        }
    }

    private func advancing(_ date: CalendarDate, rule: RecurrenceRule) -> CalendarDate? {
        switch rule.frequency {
        case .daily:
            return date.adding(days: rule.interval, calendar: calendar)
        case .weekly:
            return date.adding(days: 7 * rule.interval, calendar: calendar)
        case .monthly:
            return addMonths(date, count: rule.interval, dayOfMonth: rule.dayOfMonth ?? date.day)
        case .yearly:
            let month = rule.monthOfYear ?? date.month
            let day = rule.dayOfMonth ?? date.day
            return dateInMonth(year: date.year + rule.interval, month: month, dayOfMonth: day)
        }
    }

    private func addMonths(_ date: CalendarDate, count: Int, dayOfMonth: Int) -> CalendarDate {
        guard let foundationDate = date.foundationDate(in: calendar),
              let shifted = calendar.date(byAdding: .month, value: count, to: foundationDate) else {
            return date
        }
        let components = calendar.dateComponents([.year, .month], from: shifted)
        return dateInMonth(
            year: components.year ?? date.year,
            month: components.month ?? date.month,
            dayOfMonth: dayOfMonth
        )
    }

    private func dateInMonth(year: Int, month: Int, dayOfMonth: Int) -> CalendarDate {
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return CalendarDate(year: year, month: month, day: 1)
        }
        let lastDay = range.count
        let requested = dayOfMonth == -1 ? lastDay : dayOfMonth
        let day = min(max(1, requested), lastDay)
        return CalendarDate(year: year, month: month, day: day)
    }

    private func nextMatchingWeekday(onOrAfter start: CalendarDate, weekday: Int) -> CalendarDate {
        guard let date = start.foundationDate(in: calendar) else { return start }
        let current = calendar.component(.weekday, from: date)
        let delta = (weekday - current + 7) % 7
        return start.adding(days: delta, calendar: calendar)
    }
}
