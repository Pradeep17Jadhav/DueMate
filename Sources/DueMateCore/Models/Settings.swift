import Foundation

public enum PaymentDirectory {
    public static let defaultApps = [
        "Google Pay",
        "PhonePe",
        "Paytm",
        "BHIM",
        "Bank App",
        "Other",
    ]

    public static let commonBanks = [
        "HDFC Bank",
        "ICICI Bank",
        "SBI",
        "Axis Bank",
        "Kotak",
        "Other",
    ]
}

public struct AppSettings: Hashable, Sendable, Codable {
    public var appearance: AppearanceMode
    public var notificationsEnabled: Bool
    public var defaultReminderDaysBefore: [Int]
    public var currencyCode: String
    public var weekStart: WeekStart
    public var widgetHideAmounts: Bool
    public var hasCompletedOnboarding: Bool
    public var loadSampleDataInDebug: Bool

    public init(
        appearance: AppearanceMode = .system,
        notificationsEnabled: Bool = false,
        defaultReminderDaysBefore: [Int] = [1],
        currencyCode: String = "INR",
        weekStart: WeekStart = .deviceDefault,
        widgetHideAmounts: Bool = true,
        hasCompletedOnboarding: Bool = false,
        loadSampleDataInDebug: Bool = true
    ) {
        self.appearance = appearance
        self.notificationsEnabled = notificationsEnabled
        self.defaultReminderDaysBefore = defaultReminderDaysBefore
        self.currencyCode = currencyCode
        self.weekStart = weekStart
        self.widgetHideAmounts = widgetHideAmounts
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.loadSampleDataInDebug = loadSampleDataInDebug
    }

    public static let `default` = AppSettings()
}

public struct Snapshot: Sendable, Codable {
    public var categories: [ObligationCategory]
    public var obligations: [Obligation]
    public var occurrences: [Occurrence]
    public var payments: [Payment]
    public var settings: AppSettings
    public var pendingMutations: [SyncMutation]

    public init(
        categories: [ObligationCategory] = ObligationCategory.systemDefaults,
        obligations: [Obligation] = [],
        occurrences: [Occurrence] = [],
        payments: [Payment] = [],
        settings: AppSettings = .default,
        pendingMutations: [SyncMutation] = []
    ) {
        self.categories = categories
        self.obligations = obligations
        self.occurrences = occurrences
        self.payments = payments
        self.settings = settings
        self.pendingMutations = pendingMutations
    }
}

public enum SyncMutationKind: String, Codable, Sendable {
    case create
    case update
    case delete
}

public enum SyncEntityType: String, Codable, Sendable {
    case obligation
    case occurrence
    case payment
    case category
    case settings
}

public struct SyncMutation: Hashable, Sendable, Codable, Identifiable {
    public var id: UUID
    public var entityType: SyncEntityType
    public var entityID: UUID
    public var kind: SyncMutationKind
    public var payloadJSON: Data?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        entityType: SyncEntityType,
        entityID: UUID,
        kind: SyncMutationKind,
        payloadJSON: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.kind = kind
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
    }
}
