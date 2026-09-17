import Foundation

public struct EMIProgress: Hashable, Sendable {
    public var paidInstallments: Int
    public var totalInstallments: Int?
    public var remainingInstallments: Int?
    public var isComplete: Bool
    public var isCompleteEarly: Bool

    public var display: String {
        if let totalInstallments {
            return "\(paidInstallments) / \(totalInstallments) paid"
        }
        return "\(paidInstallments) paid"
    }
}

/// Installment counts are derived from paid occurrences so marking paid is idempotent.
public struct EMIService: Sendable {
    public init() {}

    public func progress(
        obligation: Obligation,
        occurrences: [Occurrence],
        asOf: CalendarDate = .today
    ) -> EMIProgress {
        let relevant = occurrences.filter { $0.obligationId == obligation.id }
        let paid = relevant.filter { $0.status == .paid }.count
        let total = obligation.emi?.totalInstallments ?? obligation.emi?.tenureMonths
        let remaining: Int?
        if let total {
            remaining = max(0, total - paid)
        } else {
            remaining = nil
        }
        let complete = total.map { paid >= $0 } ?? false
        return EMIProgress(
            paidInstallments: paid,
            totalInstallments: total,
            remainingInstallments: remaining,
            isComplete: complete,
            isCompleteEarly: obligation.lifecycle == .completedEarly
        )
    }

    public func assignInstallmentNumbers(
        occurrences: [Occurrence],
        startDate: CalendarDate
    ) -> [Occurrence] {
        let sorted = occurrences.sorted { $0.scheduledDate < $1.scheduledDate }
        return sorted.enumerated().map { index, occurrence in
            var copy = occurrence
            copy.installmentNumber = index + 1
            return copy
        }
    }

    public func approximateEndDate(start: CalendarDate, tenureMonths: Int) -> CalendarDate {
        start.adding(months: max(0, tenureMonths - 1))
    }

    public func shouldStopGenerating(progress: EMIProgress, lifecycle: ObligationLifecycle) -> Bool {
        switch lifecycle {
        case .completed, .completedEarly, .archived, .paused:
            return true
        case .active:
            return progress.isComplete
        }
    }
}
