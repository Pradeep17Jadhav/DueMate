import Foundation

/// A timezone-independent civil date (year-month-day).
/// Due dates are date-only; payment timestamps remain `Date`.
public struct CalendarDate: Hashable, Sendable, Comparable, Codable, CustomStringConvertible {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    public static var today: CalendarDate {
        CalendarDate(Date())
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var dateComponents: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    public func foundationDate(in calendar: Calendar = .current) -> Date? {
        calendar.date(from: dateComponents)
    }

    public static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    public func adding(days: Int, calendar: Calendar = .current) -> CalendarDate {
        guard let value = foundationDate(in: calendar),
              let next = calendar.date(byAdding: .day, value: days, to: value) else {
            return self
        }
        return CalendarDate(next, calendar: calendar)
    }

    public func adding(months: Int, calendar: Calendar = .current) -> CalendarDate {
        guard let value = foundationDate(in: calendar),
              let next = calendar.date(byAdding: .month, value: months, to: value) else {
            return self
        }
        return CalendarDate(next, calendar: calendar)
    }

    public func startOfMonth(calendar: Calendar = .current) -> CalendarDate {
        CalendarDate(year: year, month: month, day: 1)
    }

    public func endOfMonth(calendar: Calendar = .current) -> CalendarDate {
        guard let value = foundationDate(in: calendar),
              let range = calendar.range(of: .day, in: .month, for: value) else {
            return self
        }
        return CalendarDate(year: year, month: month, day: range.count)
    }

    enum CodingKeys: String, CodingKey {
        case year, month, day
        case iso
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let iso = try? container.decode(String.self),
           let parsed = CalendarDate(isoString: iso) {
            self = parsed
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let iso = try container.decodeIfPresent(String.self, forKey: .iso),
           let parsed = CalendarDate(isoString: iso) {
            self = parsed
            return
        }
        year = try container.decode(Int.self, forKey: .year)
        month = try container.decode(Int.self, forKey: .month)
        day = try container.decode(Int.self, forKey: .day)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init?(isoString: String) {
        let parts = isoString.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        self.init(year: y, month: m, day: d)
    }
}
