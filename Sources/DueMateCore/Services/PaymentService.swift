import Foundation

public struct PaymentDraft: Sendable {
    public var amount: Money
    public var paidAt: Date
    public var paymentMethod: PaymentMethod
    public var paymentApp: String?
    public var paymentBank: String?
    public var transactionReference: String?
    public var notes: String?

    public init(
        amount: Money,
        paidAt: Date = Date(),
        paymentMethod: PaymentMethod = .upi,
        paymentApp: String? = nil,
        paymentBank: String? = nil,
        transactionReference: String? = nil,
        notes: String? = nil
    ) {
        self.amount = amount
        self.paidAt = paidAt
        self.paymentMethod = paymentMethod
        self.paymentApp = paymentApp
        self.paymentBank = paymentBank
        self.transactionReference = transactionReference
        self.notes = notes
    }
}

public enum PaymentServiceError: Error, Equatable {
    case amountMustBeNonNegative
}

/// Payment records are independent of occurrences. Paid status is backed by at least one payment.
public struct PaymentService: Sendable {
    public init() {}

    public func makePayment(for occurrence: Occurrence, draft: PaymentDraft) throws -> Payment {
        guard draft.amount.amount >= 0 else { throw PaymentServiceError.amountMustBeNonNegative }
        return Payment(
            occurrenceId: occurrence.id,
            paidAt: draft.paidAt,
            amount: draft.amount,
            paymentMethod: draft.paymentMethod,
            paymentApp: draft.paymentApp,
            paymentBank: draft.paymentBank,
            transactionReference: draft.transactionReference,
            notes: draft.notes
        )
    }

    public func occurrenceStatus(afterPayments payments: [Payment]) -> OccurrenceStatus {
        payments.isEmpty ? .pending : .paid
    }

    public func totalPaid(payments: [Payment]) -> Decimal {
        payments.reduce(0) { $0 + $1.amount.amount }
    }

    public func remembering(obligation: Obligation, from draft: PaymentDraft) -> Obligation {
        var copy = obligation
        copy.lastPaymentMethod = draft.paymentMethod
        copy.lastPaymentApp = draft.paymentApp
        copy.lastPaymentBank = draft.paymentBank
        copy.updatedAt = Date()
        return copy
    }

    public func prefill(for obligation: Obligation, occurrence: Occurrence) -> PaymentDraft {
        let amount = occurrence.expectedAmount ?? obligation.amount ?? Money.zeroINR
        return PaymentDraft(
            amount: amount,
            paidAt: Date(),
            paymentMethod: obligation.lastPaymentMethod ?? .upi,
            paymentApp: obligation.lastPaymentApp,
            paymentBank: obligation.lastPaymentBank
        )
    }
}
