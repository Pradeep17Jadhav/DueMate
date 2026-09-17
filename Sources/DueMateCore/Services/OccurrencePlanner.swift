import Foundation

public enum ObligationValidationError: Error, Equatable, LocalizedError {
    case titleRequired
    case amountNegative
    case tenureInvalid
    case recurrenceInvalid

    public var errorDescription: String? {
        switch self {
        case .titleRequired: "Enter a name for this obligation."
        case .amountNegative: "Amount must be zero or greater."
        case .tenureInvalid: "Tenure must be greater than zero."
        case .recurrenceInvalid: "Choose a valid recurrence."
        }
    }
}

public struct OccurrencePlanner: Sendable {
    public var recurrence: RecurrenceService
    public var horizonMonths: Int

    public init(recurrence: RecurrenceService = RecurrenceService(), horizonMonths: Int = 12) {
        self.recurrence = recurrence
        self.horizonMonths = horizonMonths
    }

    public func generate(
        obligation: Obligation,
        existing: [Occurrence],
        asOf: CalendarDate
    ) -> [Occurrence] {
        guard obligation.generatesFutureOccurrences else { return existing }

        var effectiveRule = obligation.recurrenceRule
        effectiveRule.endDate = obligation.endDate ?? effectiveRule.endDate

        if let total = obligation.emi?.totalInstallments ?? obligation.emi?.tenureMonths {
            let paid = existing.filter { $0.status == .paid }.count
            if paid >= total { return existing }
        }

        let horizon = asOf.adding(months: horizonMonths)
        let dates = recurrence.dates(from: obligation.startDate, rule: effectiveRule, through: horizon)
        let existingByDate = Dictionary(uniqueKeysWithValues: existing.map { ($0.scheduledDate, $0) })

        var result: [Occurrence] = existing
        for (index, date) in dates.enumerated() {
            if existingByDate[date] != nil { continue }
            if date < obligation.startDate { continue }
            if let resume = obligation.resumeDate, date < resume { continue }
            let occurrence = Occurrence(
                obligationId: obligation.id,
                scheduledDate: date,
                expectedAmount: obligation.amount,
                installmentNumber: obligation.emi == nil ? nil : index + 1
            )
            result.append(occurrence)
        }
        return result
    }
}

public struct ObligationValidator: Sendable {
    public init() {}

    public func validate(_ obligation: Obligation) throws {
        if obligation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ObligationValidationError.titleRequired
        }
        if let amount = obligation.amount, amount.amount < 0 {
            throw ObligationValidationError.amountNegative
        }
        if obligation.recurrenceRule.interval < 1 {
            throw ObligationValidationError.recurrenceInvalid
        }
        if let tenure = obligation.emi?.tenureMonths, tenure <= 0 {
            throw ObligationValidationError.tenureInvalid
        }
        if let total = obligation.emi?.totalInstallments, total <= 0 {
            throw ObligationValidationError.tenureInvalid
        }
    }
}
