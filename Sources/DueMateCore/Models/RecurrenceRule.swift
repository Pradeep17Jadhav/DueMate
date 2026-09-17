import Foundation

public struct RecurrenceRule: Hashable, Sendable, Codable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    /// 1...31 for a specific day, `-1` for last day of month.
    public var dayOfMonth: Int?
    /// 1 = Sunday ... 7 = Saturday (Foundation weekday).
    public var weekday: Int?
    public var monthOfYear: Int?
    public var endDate: CalendarDate?
    public var invalidDayPolicy: InvalidDayPolicy

    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        dayOfMonth: Int? = nil,
        weekday: Int? = nil,
        monthOfYear: Int? = nil,
        endDate: CalendarDate? = nil,
        invalidDayPolicy: InvalidDayPolicy = .clampToLastDay
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.dayOfMonth = dayOfMonth
        self.weekday = weekday
        self.monthOfYear = monthOfYear
        self.endDate = endDate
        self.invalidDayPolicy = invalidDayPolicy
    }

    public static func daily(interval: Int = 1, endDate: CalendarDate? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .daily, interval: interval, endDate: endDate)
    }

    public static func weekly(interval: Int = 1, weekday: Int? = nil, endDate: CalendarDate? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .weekly, interval: interval, weekday: weekday, endDate: endDate)
    }

    public static func monthly(day: Int, interval: Int = 1, endDate: CalendarDate? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .monthly, interval: interval, dayOfMonth: day, endDate: endDate)
    }

    public static func lastDayOfMonth(interval: Int = 1, endDate: CalendarDate? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .monthly, interval: interval, dayOfMonth: -1, endDate: endDate)
    }

    public static func yearly(month: Int, day: Int, interval: Int = 1, endDate: CalendarDate? = nil) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .yearly,
            interval: interval,
            dayOfMonth: day,
            monthOfYear: month,
            endDate: endDate
        )
    }

    public var summary: String {
        let n = interval
        switch frequency {
        case .daily:
            return n == 1 ? "Every day" : "Every \(n) days"
        case .weekly:
            return n == 1 ? "Every week" : "Every \(n) weeks"
        case .monthly:
            if dayOfMonth == -1 {
                return n == 1 ? "Last day of every month" : "Last day every \(n) months"
            }
            if let dayOfMonth {
                let suffix = Self.ordinal(dayOfMonth)
                return n == 1 ? "\(suffix) of every month" : "\(suffix) every \(n) months"
            }
            return n == 1 ? "Every month" : "Every \(n) months"
        case .yearly:
            return n == 1 ? "Every year" : "Every \(n) years"
        }
    }

    private static func ordinal(_ value: Int) -> String {
        let remainder100 = value % 100
        let remainder10 = value % 10
        if remainder100 >= 11 && remainder100 <= 13 { return "\(value)th" }
        switch remainder10 {
        case 1: return "\(value)st"
        case 2: return "\(value)nd"
        case 3: return "\(value)rd"
        default: return "\(value)th"
        }
    }
}

public struct ReminderOffset: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var daysBefore: Int

    public init(id: UUID = UUID(), daysBefore: Int) {
        self.id = id
        self.daysBefore = daysBefore
    }
}

public struct EMIDetails: Hashable, Sendable, Codable {
    public var loanType: LoanType
    public var loanProvider: String?
    public var deductionBank: String?
    public var loanAccountReference: String?
    public var tenureMonths: Int?
    public var totalInstallments: Int?
    public var startDate: CalendarDate?
    public var interestRatePercent: Decimal?
    public var principalAmount: Money?
    public var autoDebitAccount: String?

    public init(
        loanType: LoanType = .home,
        loanProvider: String? = nil,
        deductionBank: String? = nil,
        loanAccountReference: String? = nil,
        tenureMonths: Int? = nil,
        totalInstallments: Int? = nil,
        startDate: CalendarDate? = nil,
        interestRatePercent: Decimal? = nil,
        principalAmount: Money? = nil,
        autoDebitAccount: String? = nil
    ) {
        self.loanType = loanType
        self.loanProvider = loanProvider
        self.deductionBank = deductionBank
        self.loanAccountReference = loanAccountReference
        self.tenureMonths = tenureMonths
        self.totalInstallments = totalInstallments ?? tenureMonths
        self.startDate = startDate
        self.interestRatePercent = interestRatePercent
        self.principalAmount = principalAmount
        self.autoDebitAccount = autoDebitAccount
    }
}

public struct CreditCardDetails: Hashable, Sendable, Codable {
    public var issuingBank: String?
    public var statementDay: Int?
    public var creditLimit: Money?
    public var lastFourDigits: String?

    public init(
        issuingBank: String? = nil,
        statementDay: Int? = nil,
        creditLimit: Money? = nil,
        lastFourDigits: String? = nil
    ) {
        self.issuingBank = issuingBank
        self.statementDay = statementDay
        self.creditLimit = creditLimit
        self.lastFourDigits = lastFourDigits
    }
}
