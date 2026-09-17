import DueMateCore
import Foundation
import Observation
import SwiftUI

public enum AppTab: String, Hashable, CaseIterable {
    case home, calendar, tasks, obligations, settings
}

public enum AppRoute: Hashable {
    case occurrence(UUID)
    case obligation(UUID)
    case calendar(CalendarDate)
    case tasksToday
}

@MainActor
@Observable
public final class AppSession {
    public var snapshot = Snapshot()
    public var selectedTab: AppTab = .home
    public var selectedCalendarDate = CalendarDate.today
    public var isLoading = true
    public var errorMessage: String?
    public var syncStatus: SyncStatus = .synced
    public var pendingPayment: OccurrenceRecord?
    public var editingPayment: Payment?
    public var showAddSheet = false
    public var showOnboarding = false
    public var route: AppRoute?

    public let store: DueMateStore
    public let api: any APIClientProtocol
    public let auth: any AuthenticationService
    public let sync: SyncService
    public let query = QueryService()
    public let dashboard = DashboardService()
    public let emi = EMIService()
    public let paymentService = PaymentService()

    public init(
        store: DueMateStore,
        api: any APIClientProtocol,
        auth: any AuthenticationService
    ) {
        self.store = store
        self.api = api
        self.auth = auth
        self.sync = SyncService(store: store, api: api)
    }

    public static func live() -> AppSession {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = appSupport.appending(path: "DueMate")
        let storeURL = directory.appending(path: "snapshot.json")
        let persistence = FileSnapshotPersistence(url: storeURL)
        let auth = MockAuthenticationService()
        let api = MockAPIClient()
        return AppSession(store: DueMateStore(persistence: persistence), api: api, auth: auth)
    }

    public static func preview() -> AppSession {
        let seed = SampleData.make()
        let session = AppSession(
            store: DueMateStore(persistence: MemorySnapshotPersistence(snapshot: seed), snapshot: seed),
            api: MockAPIClient(),
            auth: MockAuthenticationService()
        )
        session.snapshot = seed
        session.isLoading = false
        session.showOnboarding = false
        return session
    }

    public func bootstrap() async {
        do {
            try await store.load()
            var current = await store.current()
            #if DEBUG
            if current.obligations.isEmpty && current.settings.loadSampleDataInDebug {
                try await store.seedIfNeeded(SampleData.make())
                current = await store.current()
            }
            #endif
            snapshot = current
            showOnboarding = !current.settings.hasCompletedOnboarding
            isLoading = false
            await refreshSync()
            await NotificationScheduler.shared.reschedule(snapshot: snapshot)
            writeWidgetSnapshot()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    public func refresh() async {
        snapshot = await store.current()
        writeWidgetSnapshot()
        await NotificationScheduler.shared.reschedule(snapshot: snapshot)
    }

    public func refreshSync() async {
        syncStatus = .syncing
        syncStatus = await sync.synchronize()
        await refresh()
    }

    public func records(_ query: TaskQuery = TaskQuery()) -> [OccurrenceRecord] {
        self.query.records(snapshot: snapshot, query: query, asOf: .today)
    }

    public func summary() -> DashboardSummary {
        dashboard.summary(occurrences: snapshot.occurrences, payments: snapshot.payments, asOf: .today)
    }

    public func markPaid(record: OccurrenceRecord, draft: PaymentDraft) async {
        do {
            _ = try await store.markPaid(occurrenceID: record.occurrence.id, draft: draft)
            pendingPayment = nil
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func saveObligation(_ obligation: Obligation, scope: SeriesEditScope = .entireSeries) async {
        do {
            if snapshot.obligations.contains(where: { $0.id == obligation.id }) {
                try await store.updateObligation(obligation, scope: scope)
            } else {
                try await store.addObligation(obligation)
            }
            showAddSheet = false
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func handle(url: URL) {
        guard url.scheme == DeepLink.scheme else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch url.host {
        case "obligation":
            if let id = parts.first.flatMap(UUID.init) {
                selectedTab = .obligations
                route = .obligation(id)
            }
        case "occurrence":
            if let id = parts.first.flatMap(UUID.init) {
                selectedTab = .tasks
                route = .occurrence(id)
            }
        case "calendar":
            if let raw = parts.first, let date = CalendarDate(isoString: raw) {
                selectedTab = .calendar
                selectedCalendarDate = date
                route = .calendar(date)
            }
        case "tasks":
            selectedTab = .tasks
            route = .tasksToday
        default:
            break
        }
    }

    public func completeOnboarding() async {
        var settings = snapshot.settings
        settings.hasCompletedOnboarding = true
        do {
            try await store.updateSettings(settings)
            showOnboarding = false
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func writeWidgetSnapshot() {
        let widget = WidgetSnapshotBuilder.make(from: snapshot)
        guard let data = try? JSONEncoder.dueMate.encode(widget) else { return }
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "DueMate/widget.json")
        if let url {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }
}
