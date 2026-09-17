import Foundation

public enum MoneyFormatter {
    public static func string(from money: Money?, hideAmount: Bool = false, locale: Locale = .current) -> String {
        guard let money else { return "Variable" }
        if hideAmount { return "••••" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.locale = locale
        formatter.maximumFractionDigits = money.amount == money.amount.rounded() ? 0 : 2
        return formatter.string(from: money.amount as NSDecimalNumber) ?? "\(money.currencyCode) \(money.amount)"
    }
}

private extension Decimal {
    func rounded() -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}

public enum Formatters {
    public static func date(_ value: CalendarDate, style: DateFormatter.Style = .medium, calendar: Calendar = .current) -> String {
        guard let date = value.foundationDate(in: calendar) else { return value.description }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    public static func monthYear(_ value: CalendarDate, calendar: Calendar = .current) -> String {
        guard let date = value.foundationDate(in: calendar) else { return "\(value.month)/\(value.year)" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    public static func weekdaySymbols(weekStart: WeekStart, calendar: Calendar = .current) -> [String] {
        var calendar = calendar
        switch weekStart {
        case .monday: calendar.firstWeekday = 2
        case .sunday: calendar.firstWeekday = 1
        case .deviceDefault: break
        }
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }
}

public enum Greeting {
    public static func text(now: Date = Date(), calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

public enum DeepLink {
    public static let scheme = "duemate"

    public static func obligation(_ id: UUID) -> URL {
        URL(string: "\(scheme)://obligation/\(id.uuidString)")!
    }

    public static func occurrence(_ id: UUID) -> URL {
        URL(string: "\(scheme)://occurrence/\(id.uuidString)")!
    }

    public static func calendar(_ date: CalendarDate) -> URL {
        URL(string: "\(scheme)://calendar/\(date.description)")!
    }

    public static func todayTasks() -> URL {
        URL(string: "\(scheme)://tasks/today")!
    }
}

public struct WidgetSnapshot: Codable, Sendable {
    public var generatedAt: Date
    public var hideAmounts: Bool
    public var upcoming: [WidgetOccurrence]
    public var today: [WidgetOccurrence]
    public var monthPaid: Money
    public var monthPending: Money
    public var loans: [WidgetLoan]

    public init(
        generatedAt: Date = Date(),
        hideAmounts: Bool,
        upcoming: [WidgetOccurrence],
        today: [WidgetOccurrence],
        monthPaid: Money,
        monthPending: Money,
        loans: [WidgetLoan]
    ) {
        self.generatedAt = generatedAt
        self.hideAmounts = hideAmounts
        self.upcoming = upcoming
        self.today = today
        self.monthPaid = monthPaid
        self.monthPending = monthPending
        self.loans = loans
    }
}

public struct WidgetOccurrence: Codable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var amount: Money?
    public var scheduledDate: CalendarDate
    public var status: OccurrenceStatus
    public var colorToken: String

    public init(id: UUID, title: String, amount: Money?, scheduledDate: CalendarDate, status: OccurrenceStatus, colorToken: String) {
        self.id = id
        self.title = title
        self.amount = amount
        self.scheduledDate = scheduledDate
        self.status = status
        self.colorToken = colorToken
    }
}

public struct WidgetLoan: Codable, Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var paid: Int
    public var total: Int?

    public init(id: UUID, title: String, paid: Int, total: Int?) {
        self.id = id
        self.title = title
        self.paid = paid
        self.total = total
    }
}

public enum WidgetSnapshotBuilder {
    public static func make(from snapshot: Snapshot, asOf: CalendarDate = .today) -> WidgetSnapshot {
        let query = QueryService()
        let upcoming = query.records(
            snapshot: snapshot,
            query: TaskQuery(filter: .all, from: asOf),
            asOf: asOf
        )
        .filter { $0.occurrence.status == .pending }
        .prefix(5)

        let today = upcoming.filter { $0.occurrence.scheduledDate == asOf }
        let dashboard = DashboardService().summary(
            occurrences: snapshot.occurrences,
            payments: snapshot.payments,
            asOf: asOf
        )
        let emi = EMIService()
        let loans = snapshot.obligations.filter { $0.emi != nil && $0.lifecycle != .archived }.map { obligation in
            let progress = emi.progress(obligation: obligation, occurrences: snapshot.occurrences, asOf: asOf)
            return WidgetLoan(id: obligation.id, title: obligation.title, paid: progress.paidInstallments, total: progress.totalInstallments)
        }

        return WidgetSnapshot(
            hideAmounts: snapshot.settings.widgetHideAmounts,
            upcoming: upcoming.map {
                WidgetOccurrence(
                    id: $0.occurrence.id,
                    title: $0.obligation.title,
                    amount: $0.displayAmount,
                    scheduledDate: $0.occurrence.scheduledDate,
                    status: $0.occurrence.status,
                    colorToken: $0.obligation.colorToken
                )
            },
            today: today.map {
                WidgetOccurrence(
                    id: $0.occurrence.id,
                    title: $0.obligation.title,
                    amount: $0.displayAmount,
                    scheduledDate: $0.occurrence.scheduledDate,
                    status: $0.occurrence.status,
                    colorToken: $0.obligation.colorToken
                )
            },
            monthPaid: dashboard.paidThisMonthTotal,
            monthPending: dashboard.pendingTotal,
            loans: Array(loans.prefix(4))
        )
    }
}
