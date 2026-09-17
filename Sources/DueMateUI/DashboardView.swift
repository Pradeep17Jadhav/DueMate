import DueMateCore
import SwiftUI

struct DashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var path = NavigationPath()

    var body: some View {
        @Bindable var session = session
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    header
                    summaryGrid
                    section("Today") {
                        todayList
                    }
                    section("Upcoming") {
                        upcomingList
                    }
                    section("Pending / Overdue") {
                        overdueList
                    }
                    monthly
                    section("Recent payments") {
                        recentPayments
                    }
                }
                .padding(AppSpacing.medium)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        session.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add obligation")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let record = session.records().first(where: { $0.occurrence.id == id }) {
                    OccurrenceDetailView(record: record)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Greeting.text())
                .font(.title2.weight(.semibold))
            Text(Formatters.date(.today, style: .full))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var summary: DashboardSummary { session.summary() }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.small) {
            SummaryCard(title: "Due Today", value: MoneyFormatter.string(from: summary.dueTodayTotal), systemImage: "sun.max.fill", tint: .orange)
            SummaryCard(title: "This Week", value: MoneyFormatter.string(from: summary.dueThisWeekTotal), systemImage: "calendar", tint: .blue)
            SummaryCard(title: "Pending", value: "\(summary.pendingCount)", systemImage: "clock", tint: .purple)
            SummaryCard(title: "Paid This Month", value: MoneyFormatter.string(from: summary.paidThisMonthTotal), systemImage: "checkmark.circle.fill", tint: .green)
        }
    }

    @ViewBuilder
    private var todayList: some View {
        let items = session.records(TaskQuery(filter: .dueToday))
        if items.isEmpty {
            Text("No payments due today")
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { record in
                NavigationLink(value: record.occurrence.id) {
                    ObligationRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var upcomingList: some View {
        let items = Array(session.records(TaskQuery(filter: .upcoming)).prefix(6))
        if items.isEmpty {
            Text("Nothing upcoming")
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { record in
                NavigationLink(value: record.occurrence.id) {
                    ObligationRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var overdueList: some View {
        let items = session.records(TaskQuery(filter: .overdue))
        if items.isEmpty {
            Text("You're all caught up")
                .foregroundStyle(.secondary)
        } else {
            ForEach(items) { record in
                NavigationLink(value: record.occurrence.id) {
                    ObligationRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var monthly: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(Formatters.monthYear(.today))
                .font(.headline)
            LabeledContent("Scheduled", value: MoneyFormatter.string(from: summary.scheduledThisMonthTotal))
            LabeledContent("Paid", value: MoneyFormatter.string(from: summary.paidThisMonthTotal))
            LabeledContent("Pending", value: MoneyFormatter.string(from: summary.pendingTotal))
            LabeledContent("Overdue", value: MoneyFormatter.string(from: summary.overdueTotal))
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }

    @ViewBuilder
    private var recentPayments: some View {
        let recent = session.snapshot.payments.sorted { $0.paidAt > $1.paidAt }.prefix(5)
        if recent.isEmpty {
            Text("No payments yet")
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(recent)) { payment in
                if let record = session.records().first(where: { $0.occurrence.id == payment.occurrenceId }) {
                    VStack(alignment: .leading) {
                        Text(record.obligation.title)
                        HStack {
                            MoneyText(payment.amount)
                            Spacer()
                            Text(payment.paidAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}
