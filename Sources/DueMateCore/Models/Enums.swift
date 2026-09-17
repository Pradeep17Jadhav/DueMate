import Foundation

public enum ObligationLifecycle: String, Codable, Sendable, CaseIterable {
    case active
    case paused
    case archived
    case completed
    case completedEarly
}

/// Stored occurrence status. Overdue is derived at display time.
public enum OccurrenceStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case paid
    case skipped
    case cancelled
}

public enum DisplayOccurrenceStatus: String, Sendable, CaseIterable {
    case pending
    case paid
    case skipped
    case cancelled
    case overdue
    case scheduled

    public init(status: OccurrenceStatus, scheduledDate: CalendarDate, asOf: CalendarDate) {
        switch status {
        case .paid:
            self = .paid
        case .skipped:
            self = .skipped
        case .cancelled:
            self = .cancelled
        case .pending:
            if scheduledDate < asOf {
                self = .overdue
            } else if scheduledDate == asOf {
                self = .pending
            } else {
                self = .scheduled
            }
        }
    }
}

public enum InvalidDayPolicy: String, Codable, Sendable, CaseIterable {
    /// If 31 Jan → Feb, use the last valid day of February.
    case clampToLastDay
}

public enum RecurrenceFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
}

public enum LoanType: String, Codable, Sendable, CaseIterable {
    case home
    case car
    case personal
    case education
    case other
}

public enum EMIBalanceStatus: String, Codable, Sendable, CaseIterable {
    case sufficient
    case insufficient
    case unknown
}

public enum PaymentMethod: Hashable, Sendable, CaseIterable, Identifiable {
    case upi
    case bankTransfer
    case debitCard
    case creditCard
    case netBanking
    case cash
    case autoDebit
    case cheque
    case other

    public var id: String { rawValue }

    public var rawValue: String {
        switch self {
        case .upi: "upi"
        case .bankTransfer: "bankTransfer"
        case .debitCard: "debitCard"
        case .creditCard: "creditCard"
        case .netBanking: "netBanking"
        case .cash: "cash"
        case .autoDebit: "autoDebit"
        case .cheque: "cheque"
        case .other: "other"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "upi": self = .upi
        case "bankTransfer": self = .bankTransfer
        case "debitCard": self = .debitCard
        case "creditCard": self = .creditCard
        case "netBanking": self = .netBanking
        case "cash": self = .cash
        case "autoDebit": self = .autoDebit
        case "cheque": self = .cheque
        case "other": self = .other
        default: return nil
        }
    }

    public var title: String {
        switch self {
        case .upi: "UPI"
        case .bankTransfer: "Bank Transfer"
        case .debitCard: "Debit Card"
        case .creditCard: "Credit Card"
        case .netBanking: "Net Banking"
        case .cash: "Cash"
        case .autoDebit: "Auto Debit"
        case .cheque: "Cheque"
        case .other: "Other"
        }
    }
}

extension PaymentMethod: Codable {
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = PaymentMethod(rawValue: value) ?? .other
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum SeriesEditScope: String, Sendable, CaseIterable {
    case thisOccurrence
    case thisAndFuture
    case entireSeries
}

public enum AppearanceMode: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

public enum WeekStart: String, Codable, Sendable, CaseIterable {
    case deviceDefault
    case monday
    case sunday
}

public enum SyncStatus: String, Sendable {
    case synced
    case syncing
    case offline
    case failed
}
