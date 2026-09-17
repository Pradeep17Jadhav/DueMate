import Foundation

public struct DashboardSummary: Hashable, Sendable {
    public var dueTodayCount: Int
    public var dueTodayTotal: Money
    public var dueThisWeekCount: Int
    public var dueThisWeekTotal: Money
    public var pendingCount: Int
    public var pendingTotal: Money
    public var paidThisMonthCount: Int
    public var paidThisMonthTotal: Money
    public var scheduledThisMonthTotal: Money
    public var overdueCount: Int
    public var overdueTotal: Money

    public static let empty = DashboardSummary(
        dueTodayCount: 0,
        dueTodayTotal: .zeroINR,
        dueThisWeekCount: 0,
        dueThisWeekTotal: .zeroINR,
        pendingCount: 0,
        pendingTotal: .zeroINR,
        paidThisMonthCount: 0,
        paidThisMonthTotal: .zeroINR,
        scheduledThisMonthTotal: .zeroINR,
        overdueCount: 0,
        overdueTotal: .zeroINR
    )
}

public struct CategorySpend: Hashable, Sendable, Identifiable {
    public var id: UUID { category.id }
    public var category: ObligationCategory
    public var total: Money
}

public struct DashboardService: Sendable {
    public init() {}

    public func summary(
        occurrences: [Occurrence],
        payments: [Payment],
        asOf: CalendarDate,
        calendar: Calendar = .current,
        currencyCode: String = "INR"
    ) -> DashboardSummary {
        let today = asOf
        let weekEnd = asOf.adding(days: 6)
        let monthStart = asOf.startOfMonth()
        let monthEnd = asOf.endOfMonth()

        func money(_ amount: Money?) -> Money {
            amount ?? Money(amount: 0, currencyCode: currencyCode)
        }

        let unpaid: (Occurrence) -> Bool = { occurrence in
            occurrence.status == .pending
        }

        let dueToday = occurrences.filter { unpaid($0) && $0.scheduledDate == today }
        let dueWeek = occurrences.filter { unpaid($0) && $0.scheduledDate >= today && $0.scheduledDate <= weekEnd }
        let pendingOpen = occurrences.filter { unpaid($0) && $0.scheduledDate >= monthStart && $0.scheduledDate <= monthEnd }
        let overdue = occurrences.filter { $0.displayStatus(asOf: today) == .overdue }
        let scheduledMonth = occurrences.filter {
            $0.scheduledDate >= monthStart && $0.scheduledDate <= monthEnd && $0.status != .cancelled && $0.status != .skipped
        }

        let paidThisMonth = payments.filter { payment in
            CalendarDate(payment.paidAt, calendar: calendar) >= monthStart
                && CalendarDate(payment.paidAt, calendar: calendar) <= monthEnd
        }

        return DashboardSummary(
            dueTodayCount: dueToday.count,
            dueTodayTotal: sum(dueToday.map { money($0.expectedAmount) }, currencyCode: currencyCode),
            dueThisWeekCount: dueWeek.count,
            dueThisWeekTotal: sum(dueWeek.map { money($0.expectedAmount) }, currencyCode: currencyCode),
            pendingCount: pendingOpen.count,
            pendingTotal: sum(pendingOpen.map { money($0.expectedAmount) }, currencyCode: currencyCode),
            paidThisMonthCount: paidThisMonth.count,
            paidThisMonthTotal: sum(paidThisMonth.map(\.amount), currencyCode: currencyCode),
            scheduledThisMonthTotal: sum(scheduledMonth.map { money($0.expectedAmount) }, currencyCode: currencyCode),
            overdueCount: overdue.count,
            overdueTotal: sum(overdue.map { money($0.expectedAmount) }, currencyCode: currencyCode)
        )
    }

    public func categoryTotals(
        occurrences: [Occurrence],
        obligations: [Obligation],
        categories: [ObligationCategory],
        asOf: CalendarDate,
        currencyCode: String = "INR"
    ) -> [CategorySpend] {
        let monthStart = asOf.startOfMonth()
        let monthEnd = asOf.endOfMonth()
        let monthItems = occurrences.filter {
            $0.scheduledDate >= monthStart && $0.scheduledDate <= monthEnd && $0.status != .cancelled
        }
        let obligationMap = Dictionary(uniqueKeysWithValues: obligations.map { ($0.id, $0) })
        var totals: [UUID: Decimal] = [:]
        for item in monthItems {
            guard let obligation = obligationMap[item.obligationId] else { continue }
            totals[obligation.categoryId, default: 0] += (item.expectedAmount ?? obligation.amount)?.amount ?? 0
        }
        return categories.compactMap { category in
            guard let amount = totals[category.id], amount > 0 else { return nil }
            return CategorySpend(category: category, total: Money(amount: amount, currencyCode: currencyCode))
        }
        .sorted { $0.total > $1.total }
    }

    private func sum(_ values: [Money], currencyCode: String) -> Money {
        Money(amount: values.reduce(0) { $0 + $1.amount }, currencyCode: currencyCode)
    }
}

public enum TaskFilter: String, Sendable, CaseIterable, Identifiable {
    case all
    case pending
    case paid
    case overdue
    case dueToday
    case upcoming

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .dueToday: "Due Today"
        case .upcoming: "Upcoming"
        }
    }
}

public enum TaskSort: String, Sendable, CaseIterable, Identifiable {
    case dueDate
    case amount
    case category
    case recentlyUpdated

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dueDate: "Due date"
        case .amount: "Amount"
        case .category: "Category"
        case .recentlyUpdated: "Recently updated"
        }
    }
}

public struct TaskQuery: Sendable {
    public var search: String
    public var filter: TaskFilter
    public var sort: TaskSort
    public var categoryID: UUID?
    public var from: CalendarDate?
    public var to: CalendarDate?

    public init(
        search: String = "",
        filter: TaskFilter = .all,
        sort: TaskSort = .dueDate,
        categoryID: UUID? = nil,
        from: CalendarDate? = nil,
        to: CalendarDate? = nil
    ) {
        self.search = search
        self.filter = filter
        self.sort = sort
        self.categoryID = categoryID
        self.from = from
        self.to = to
    }
}

public struct OccurrenceRecord: Hashable, Sendable, Identifiable {
    public var occurrence: Occurrence
    public var obligation: Obligation
    public var category: ObligationCategory?
    public var payments: [Payment]

    public var id: UUID { occurrence.id }

    public var displayAmount: Money? {
        if let paid = payments.first {
            return paid.amount
        }
        return occurrence.expectedAmount ?? obligation.amount
    }
}

public struct QueryService: Sendable {
    public init() {}

    public func records(
        snapshot: Snapshot,
        query: TaskQuery,
        asOf: CalendarDate
    ) -> [OccurrenceRecord] {
        let obligations = Dictionary(uniqueKeysWithValues: snapshot.obligations.map { ($0.id, $0) })
        let categories = Dictionary(uniqueKeysWithValues: snapshot.categories.map { ($0.id, $0) })
        let paymentsByOccurrence = Dictionary(grouping: snapshot.payments, by: \.occurrenceId)

        var items: [OccurrenceRecord] = snapshot.occurrences.compactMap { occurrence in
            guard let obligation = obligations[occurrence.obligationId] else { return nil }
            if obligation.lifecycle == .archived { return nil }
            return OccurrenceRecord(
                occurrence: occurrence,
                obligation: obligation,
                category: categories[obligation.categoryId],
                payments: paymentsByOccurrence[occurrence.id] ?? []
            )
        }

        let needle = query.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            items = items.filter { record in
                let haystacks = [
                    record.obligation.title,
                    record.obligation.providerName,
                    record.obligation.notes,
                    record.payments.first?.paymentApp,
                    record.payments.first?.paymentBank,
                    record.payments.first?.transactionReference,
                    record.payments.first?.notes,
                ]
                .compactMap { $0?.lowercased() }
                return haystacks.contains { $0.contains(needle) }
            }
        }

        if let categoryID = query.categoryID {
            items = items.filter { $0.obligation.categoryId == categoryID }
        }
        if let from = query.from {
            items = items.filter { $0.occurrence.scheduledDate >= from }
        }
        if let to = query.to {
            items = items.filter { $0.occurrence.scheduledDate <= to }
        }

        items = items.filter { record in
            let display = record.occurrence.displayStatus(asOf: asOf)
            switch query.filter {
            case .all:
                return true
            case .pending:
                return record.occurrence.status == .pending && display != .overdue
            case .paid:
                return record.occurrence.status == .paid
            case .overdue:
                return display == .overdue
            case .dueToday:
                return record.occurrence.scheduledDate == asOf && record.occurrence.status == .pending
            case .upcoming:
                return record.occurrence.scheduledDate > asOf && record.occurrence.status == .pending
            }
        }

        items.sort { lhs, rhs in
            switch query.sort {
            case .dueDate:
                if lhs.occurrence.scheduledDate != rhs.occurrence.scheduledDate {
                    return lhs.occurrence.scheduledDate < rhs.occurrence.scheduledDate
                }
                return lhs.obligation.title < rhs.obligation.title
            case .amount:
                return (lhs.displayAmount?.amount ?? 0) > (rhs.displayAmount?.amount ?? 0)
            case .category:
                return (lhs.category?.name ?? "") < (rhs.category?.name ?? "")
            case .recentlyUpdated:
                return lhs.occurrence.updatedAt > rhs.occurrence.updatedAt
            }
        }
        return items
    }
}
