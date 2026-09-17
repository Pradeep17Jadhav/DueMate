import Foundation

public enum StoreError: Error, LocalizedError {
    case obligationNotFound
    case occurrenceNotFound
    case paymentNotFound
    case categoryNotFound
    case validation(String)
    case persistence(String)

    public var errorDescription: String? {
        switch self {
        case .obligationNotFound: "That obligation could not be found."
        case .occurrenceNotFound: "That scheduled payment could not be found."
        case .paymentNotFound: "That payment could not be found."
        case .categoryNotFound: "That category could not be found."
        case .validation(let message): message
        case .persistence(let message): "Couldn't save your data. \(message)"
        }
    }
}

public protocol SnapshotPersisting: Sendable {
    func load() async throws -> Snapshot
    func save(_ snapshot: Snapshot) async throws
}

public actor MemorySnapshotPersistence: SnapshotPersisting {
    private var snapshot: Snapshot

    public init(snapshot: Snapshot = Snapshot()) {
        self.snapshot = snapshot
    }

    public func load() async throws -> Snapshot { snapshot }

    public func save(_ snapshot: Snapshot) async throws {
        self.snapshot = snapshot
    }
}

public actor FileSnapshotPersistence: SnapshotPersisting {
    private let url: URL
    private let encoder = JSONEncoder.dueMate
    private let decoder = JSONDecoder.dueMate

    public init(url: URL) {
        self.url = url
    }

    public func load() async throws -> Snapshot {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return Snapshot()
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(Snapshot.self, from: data)
    }

    public func save(_ snapshot: Snapshot) async throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }
}

public enum JSONCoder {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public extension JSONEncoder {
    static var dueMate: JSONEncoder { JSONCoder.makeEncoder() }
}

public extension JSONDecoder {
    static var dueMate: JSONDecoder { JSONCoder.makeDecoder() }
}

/// Offline-first source of truth. Mutations are local first, then queued for API sync.
public actor DueMateStore {
    private var snapshot: Snapshot
    private let persistence: any SnapshotPersisting
    private let planner: OccurrencePlanner
    private let paymentService: PaymentService
    private let validator: ObligationValidator
    private let emiService: EMIService

    public init(
        persistence: any SnapshotPersisting,
        snapshot: Snapshot = Snapshot(),
        planner: OccurrencePlanner = OccurrencePlanner(),
        paymentService: PaymentService = PaymentService(),
        validator: ObligationValidator = ObligationValidator(),
        emiService: EMIService = EMIService()
    ) {
        self.persistence = persistence
        self.snapshot = snapshot
        self.planner = planner
        self.paymentService = paymentService
        self.validator = validator
        self.emiService = emiService
    }

    public func load() async throws {
        snapshot = try await persistence.load()
        if snapshot.categories.isEmpty {
            snapshot.categories = ObligationCategory.systemDefaults
        }
        refreshOccurrences(asOf: .today)
        try await persist()
    }

    public func current() -> Snapshot { snapshot }

    public func settings() -> AppSettings { snapshot.settings }

    public func updateSettings(_ settings: AppSettings) async throws {
        snapshot.settings = settings
        enqueue(.settings, snapshot.settings.idFallback, .update)
        try await persist()
    }

    public func addObligation(_ obligation: Obligation, asOf: CalendarDate = .today) async throws {
        try validator.validate(obligation)
        var value = obligation
        value.updatedAt = Date()
        snapshot.obligations.append(value)
        snapshot.occurrences = planner.generate(obligation: value, existing: snapshot.occurrences, asOf: asOf)
        enqueue(.obligation, value.id, .create, value)
        try await persist()
    }

    public func updateObligation(_ obligation: Obligation, scope: SeriesEditScope, asOf: CalendarDate = .today) async throws {
        try validator.validate(obligation)
        guard let index = snapshot.obligations.firstIndex(where: { $0.id == obligation.id }) else {
            throw StoreError.obligationNotFound
        }
        var value = obligation
        value.updatedAt = Date()
        snapshot.obligations[index] = value

        switch scope {
        case .entireSeries:
            snapshot.occurrences = snapshot.occurrences.map { occurrence in
                guard occurrence.obligationId == value.id, occurrence.status == .pending else { return occurrence }
                var copy = occurrence
                copy.expectedAmount = value.amount
                copy.updatedAt = Date()
                return copy
            }
        case .thisAndFuture:
            break
        case .thisOccurrence:
            break
        }

        snapshot.occurrences = planner.generate(obligation: value, existing: snapshot.occurrences, asOf: asOf)
        enqueue(.obligation, value.id, .update, value)
        try await persist()
    }

    public func updateOccurrence(_ occurrence: Occurrence) async throws {
        guard let index = snapshot.occurrences.firstIndex(where: { $0.id == occurrence.id }) else {
            throw StoreError.occurrenceNotFound
        }
        var value = occurrence
        value.updatedAt = Date()
        snapshot.occurrences[index] = value
        enqueue(.occurrence, value.id, .update, value)
        try await persist()
    }

    public func deleteObligation(_ id: UUID, scope: SeriesEditScope, occurrenceID: UUID?) async throws {
        switch scope {
        case .thisOccurrence:
            guard let occurrenceID else { throw StoreError.occurrenceNotFound }
            try await deleteOccurrence(occurrenceID)
        case .thisAndFuture:
            guard let occurrenceID,
                  let pivot = snapshot.occurrences.first(where: { $0.id == occurrenceID }) else {
                throw StoreError.occurrenceNotFound
            }
            snapshot.occurrences.removeAll {
                $0.obligationId == id && $0.scheduledDate >= pivot.scheduledDate && $0.status != .paid
            }
            if var obligation = snapshot.obligations.first(where: { $0.id == id }) {
                obligation.endDate = pivot.scheduledDate.adding(days: -1)
                obligation.updatedAt = Date()
                snapshot.obligations.removeAll { $0.id == id }
                snapshot.obligations.append(obligation)
                enqueue(.obligation, id, .update, obligation)
            }
        case .entireSeries:
            if var obligation = snapshot.obligations.first(where: { $0.id == id }) {
                obligation.lifecycle = .archived
                obligation.updatedAt = Date()
                snapshot.obligations.removeAll { $0.id == id }
                snapshot.obligations.append(obligation)
                snapshot.occurrences.removeAll { $0.obligationId == id && $0.status != .paid }
                enqueue(.obligation, id, .update, obligation)
            }
        }
        try await persist()
    }

    public func setLifecycle(_ id: UUID, lifecycle: ObligationLifecycle, resumeDate: CalendarDate? = nil) async throws {
        guard var obligation = snapshot.obligations.first(where: { $0.id == id }) else {
            throw StoreError.obligationNotFound
        }
        obligation.lifecycle = lifecycle
        obligation.resumeDate = resumeDate
        obligation.updatedAt = Date()
        snapshot.obligations.removeAll { $0.id == id }
        snapshot.obligations.append(obligation)
        if !obligation.generatesFutureOccurrences {
            snapshot.occurrences.removeAll { $0.obligationId == id && $0.status == .pending && $0.scheduledDate >= CalendarDate.today }
        } else {
            snapshot.occurrences = planner.generate(obligation: obligation, existing: snapshot.occurrences, asOf: .today)
        }
        enqueue(.obligation, id, .update, obligation)
        try await persist()
    }

    public func duplicateObligation(_ id: UUID) async throws {
        guard var obligation = snapshot.obligations.first(where: { $0.id == id }) else {
            throw StoreError.obligationNotFound
        }
        obligation.id = UUID()
        obligation.title += " Copy"
        obligation.createdAt = Date()
        obligation.updatedAt = Date()
        try await addObligation(obligation)
    }

    public func markPaid(occurrenceID: UUID, draft: PaymentDraft) async throws -> Payment {
        guard var occurrence = snapshot.occurrences.first(where: { $0.id == occurrenceID }) else {
            throw StoreError.occurrenceNotFound
        }
        let payment = try paymentService.makePayment(for: occurrence, draft: draft)
        snapshot.payments.append(payment)
        occurrence.status = .paid
        occurrence.updatedAt = Date()
        replaceOccurrence(occurrence)
        if var obligation = snapshot.obligations.first(where: { $0.id == occurrence.obligationId }) {
            obligation = paymentService.remembering(obligation: obligation, from: draft)
            snapshot.obligations.removeAll { $0.id == obligation.id }
            snapshot.obligations.append(obligation)
            let progress = emiService.progress(obligation: obligation, occurrences: snapshot.occurrences)
            if progress.isComplete {
                obligation.lifecycle = .completed
                snapshot.obligations.removeAll { $0.id == obligation.id }
                snapshot.obligations.append(obligation)
            }
            enqueue(.obligation, obligation.id, .update, obligation)
        }
        enqueue(.payment, payment.id, .create, payment)
        enqueue(.occurrence, occurrence.id, .update, occurrence)
        try await persist()
        return payment
    }

    public func updatePayment(_ payment: Payment) async throws {
        guard snapshot.payments.contains(where: { $0.id == payment.id }) else {
            throw StoreError.paymentNotFound
        }
        var value = payment
        value.updatedAt = Date()
        snapshot.payments.removeAll { $0.id == payment.id }
        snapshot.payments.append(value)
        enqueue(.payment, value.id, .update, value)
        try await persist()
    }

    public func deletePayment(_ id: UUID) async throws {
        guard let payment = snapshot.payments.first(where: { $0.id == id }) else {
            throw StoreError.paymentNotFound
        }
        snapshot.payments.removeAll { $0.id == id }
        let remaining = snapshot.payments.filter { $0.occurrenceId == payment.occurrenceId }
        if remaining.isEmpty, var occurrence = snapshot.occurrences.first(where: { $0.id == payment.occurrenceId }) {
            occurrence.status = .pending
            occurrence.updatedAt = Date()
            replaceOccurrence(occurrence)
            enqueue(.occurrence, occurrence.id, .update, occurrence)
        }
        enqueue(.payment, id, .delete)
        try await persist()
    }

    public func deleteOccurrence(_ id: UUID) async throws {
        snapshot.occurrences.removeAll { $0.id == id }
        let payments = snapshot.payments.filter { $0.occurrenceId == id }
        for payment in payments {
            snapshot.payments.removeAll { $0.id == payment.id }
            enqueue(.payment, payment.id, .delete)
        }
        enqueue(.occurrence, id, .delete)
        try await persist()
    }

    public func addCategory(_ category: ObligationCategory) async throws {
        snapshot.categories.append(category)
        enqueue(.category, category.id, .create, category)
        try await persist()
    }

    public func updateCategory(_ category: ObligationCategory) async throws {
        snapshot.categories.removeAll { $0.id == category.id }
        snapshot.categories.append(category)
        enqueue(.category, category.id, .update, category)
        try await persist()
    }

    public func seedIfNeeded(_ seed: Snapshot) async throws {
        if snapshot.obligations.isEmpty {
            snapshot.categories = seed.categories
            snapshot.obligations = seed.obligations
            snapshot.occurrences = seed.occurrences
            snapshot.payments = seed.payments
            refreshOccurrences(asOf: .today)
            try await persist()
        }
    }

    public func replacePendingMutations(_ mutations: [SyncMutation]) async throws {
        snapshot.pendingMutations = mutations
        try await persist()
    }

    public func mergeServerSnapshot(_ remote: Snapshot) async throws {
        if snapshot.pendingMutations.isEmpty {
            snapshot.categories = remote.categories.isEmpty ? snapshot.categories : remote.categories
            snapshot.obligations = remote.obligations
            snapshot.occurrences = remote.occurrences
            snapshot.payments = remote.payments
            try await persist()
            return
        }
        snapshot.obligations = merge(local: snapshot.obligations, remote: remote.obligations)
        snapshot.occurrences = merge(local: snapshot.occurrences, remote: remote.occurrences)
        snapshot.payments = merge(local: snapshot.payments, remote: remote.payments)
        try await persist()
    }

    private func merge<T: Identifiable>(local: [T], remote: [T]) -> [T] where T: DatedEntity {
        var result = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        for item in local {
            if let existing = result[item.id] {
                if item.updatedAt >= existing.updatedAt {
                    result[item.id] = item
                }
            } else {
                result[item.id] = item
            }
        }
        return Array(result.values)
    }

    private func refreshOccurrences(asOf: CalendarDate) {
        for obligation in snapshot.obligations {
            snapshot.occurrences = planner.generate(
                obligation: obligation,
                existing: snapshot.occurrences,
                asOf: asOf
            )
        }
    }

    private func replaceOccurrence(_ occurrence: Occurrence) {
        snapshot.occurrences.removeAll { $0.id == occurrence.id }
        snapshot.occurrences.append(occurrence)
    }

    private func enqueue<T: Encodable>(_ type: SyncEntityType, _ id: UUID, _ kind: SyncMutationKind, _ value: T) {
        let data = try? JSONEncoder.dueMate.encode(value)
        snapshot.pendingMutations.append(SyncMutation(entityType: type, entityID: id, kind: kind, payloadJSON: data))
    }

    private func enqueue(_ type: SyncEntityType, _ id: UUID, _ kind: SyncMutationKind) {
        snapshot.pendingMutations.append(SyncMutation(entityType: type, entityID: id, kind: kind))
    }

    private func persist() async throws {
        do {
            try await persistence.save(snapshot)
        } catch {
            throw StoreError.persistence(error.localizedDescription)
        }
    }
}

private protocol DatedEntity {
    var updatedAt: Date { get }
}

extension Obligation: DatedEntity {}
extension Occurrence: DatedEntity {}
extension Payment: DatedEntity {}

private extension AppSettings {
    var idFallback: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    }
}
