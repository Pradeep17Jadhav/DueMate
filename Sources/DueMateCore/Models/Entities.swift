import Foundation

public struct ObligationCategory: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorToken: String
    public var sortOrder: Int
    public var isSystem: Bool
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorToken: String,
        sortOrder: Int,
        isSystem: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorToken = colorToken
        self.sortOrder = sortOrder
        self.isSystem = isSystem
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static let systemDefaults: [ObligationCategory] = [
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Bill Due Date", icon: "calendar.badge.clock", colorToken: "neutral", sortOrder: 0, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Credit Card", icon: "creditcard.fill", colorToken: "blue", sortOrder: 1, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "EMI", icon: "building.columns.fill", colorToken: "purple", sortOrder: 2, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Utility", icon: "bolt.fill", colorToken: "orange", sortOrder: 3, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Loan", icon: "banknote.fill", colorToken: "indigo", sortOrder: 4, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Insurance", icon: "shield.fill", colorToken: "green", sortOrder: 5, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Subscription", icon: "repeat", colorToken: "teal", sortOrder: 6, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "Rent", icon: "house.fill", colorToken: "brown", sortOrder: 7, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, name: "Tax", icon: "doc.text.fill", colorToken: "red", sortOrder: 8, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!, name: "Investment", icon: "chart.line.uptrend.xyaxis", colorToken: "mint", sortOrder: 9, isSystem: true),
        ObligationCategory(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!, name: "Other", icon: "ellipsis.circle.fill", colorToken: "gray", sortOrder: 10, isSystem: true),
    ]

    public static func systemID(named name: String) -> UUID? {
        systemDefaults.first { $0.name == name }?.id
    }
}

public struct Obligation: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var summary: String?
    public var categoryId: UUID
    public var icon: String
    public var colorToken: String
    public var amount: Money?
    public var amountKind: AmountKind
    public var recurrenceRule: RecurrenceRule
    public var startDate: CalendarDate
    public var endDate: CalendarDate?
    public var lifecycle: ObligationLifecycle
    public var providerName: String?
    public var accountReference: String?
    public var website: String?
    public var notes: String?
    public var reminders: [ReminderOffset]
    public var emi: EMIDetails?
    public var creditCard: CreditCardDetails?
    public var lastPaymentMethod: PaymentMethod?
    public var lastPaymentApp: String?
    public var lastPaymentBank: String?
    public var resumeDate: CalendarDate?
    public var createdAt: Date
    public var updatedAt: Date
    public var serverUpdatedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        categoryId: UUID,
        icon: String = "wallet.pass.fill",
        colorToken: String = "blue",
        amount: Money? = nil,
        amountKind: AmountKind = .fixed,
        recurrenceRule: RecurrenceRule,
        startDate: CalendarDate,
        endDate: CalendarDate? = nil,
        lifecycle: ObligationLifecycle = .active,
        providerName: String? = nil,
        accountReference: String? = nil,
        website: String? = nil,
        notes: String? = nil,
        reminders: [ReminderOffset] = [ReminderOffset(daysBefore: 1)],
        emi: EMIDetails? = nil,
        creditCard: CreditCardDetails? = nil,
        lastPaymentMethod: PaymentMethod? = nil,
        lastPaymentApp: String? = nil,
        lastPaymentBank: String? = nil,
        resumeDate: CalendarDate? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.categoryId = categoryId
        self.icon = icon
        self.colorToken = colorToken
        self.amount = amount
        self.amountKind = amountKind
        self.recurrenceRule = recurrenceRule
        self.startDate = startDate
        self.endDate = endDate
        self.lifecycle = lifecycle
        self.providerName = providerName
        self.accountReference = accountReference
        self.website = website
        self.notes = notes
        self.reminders = reminders
        self.emi = emi
        self.creditCard = creditCard
        self.lastPaymentMethod = lastPaymentMethod
        self.lastPaymentApp = lastPaymentApp
        self.lastPaymentBank = lastPaymentBank
        self.resumeDate = resumeDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
    }

    public var generatesFutureOccurrences: Bool {
        switch lifecycle {
        case .active: true
        case .paused, .archived, .completed, .completedEarly: false
        }
    }
}

public struct Occurrence: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var obligationId: UUID
    public var scheduledDate: CalendarDate
    public var status: OccurrenceStatus
    public var expectedAmount: Money?
    public var notes: String?
    public var installmentNumber: Int?
    public var balanceStatus: EMIBalanceStatus
    public var isDetachedFromSeries: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var serverUpdatedAt: Date?

    public init(
        id: UUID = UUID(),
        obligationId: UUID,
        scheduledDate: CalendarDate,
        status: OccurrenceStatus = .pending,
        expectedAmount: Money? = nil,
        notes: String? = nil,
        installmentNumber: Int? = nil,
        balanceStatus: EMIBalanceStatus = .unknown,
        isDetachedFromSeries: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.obligationId = obligationId
        self.scheduledDate = scheduledDate
        self.status = status
        self.expectedAmount = expectedAmount
        self.notes = notes
        self.installmentNumber = installmentNumber
        self.balanceStatus = balanceStatus
        self.isDetachedFromSeries = isDetachedFromSeries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
    }

    public func displayStatus(asOf: CalendarDate) -> DisplayOccurrenceStatus {
        DisplayOccurrenceStatus(status: status, scheduledDate: scheduledDate, asOf: asOf)
    }
}

public struct Payment: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var occurrenceId: UUID
    public var paidAt: Date
    public var amount: Money
    public var paymentMethod: PaymentMethod
    public var paymentApp: String?
    public var paymentBank: String?
    public var transactionReference: String?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var serverUpdatedAt: Date?

    public init(
        id: UUID = UUID(),
        occurrenceId: UUID,
        paidAt: Date = Date(),
        amount: Money,
        paymentMethod: PaymentMethod = .upi,
        paymentApp: String? = nil,
        paymentBank: String? = nil,
        transactionReference: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        serverUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.occurrenceId = occurrenceId
        self.paidAt = paidAt
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.paymentApp = paymentApp
        self.paymentBank = paymentBank
        self.transactionReference = transactionReference
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
    }
}
