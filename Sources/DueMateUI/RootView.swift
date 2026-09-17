import DueMateCore
import SwiftUI

public struct RootView: View {
    @Bindable var session: AppSession

    public init(session: AppSession) {
        self.session = session
    }

    public var body: some View {
        Group {
            if session.isLoading {
                ProgressView("Loading DueMate")
            } else {
                tabs
            }
        }
        .environment(session)
        .preferredColorScheme(colorScheme)
        .sheet(isPresented: $session.showAddSheet) {
            AddObligationSheet()
        }
        .sheet(item: $session.pendingPayment) { record in
            PaymentSheet(record: record)
        }
        .sheet(item: $session.editingPayment) { payment in
            if let record = session.records().first(where: { $0.occurrence.id == payment.occurrenceId }) {
                PaymentSheet(record: record, existing: payment)
            }
        }
        .sheet(isPresented: $session.showOnboarding) {
            OnboardingView()
                .environment(session)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
        .task { await session.bootstrap() }
        .onOpenURL { session.handle(url: $0) }
    }

    private var tabs: some View {
        TabView(selection: $session.selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)
            CalendarFeatureView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(AppTab.tasks)
            ObligationsView()
                .tabItem { Label("Obligations", systemImage: "wallet.pass.fill") }
                .tag(AppTab.obligations)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }

    private var colorScheme: ColorScheme? {
        switch session.snapshot.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
