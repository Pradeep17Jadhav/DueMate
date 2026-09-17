import DueMateCore
import SwiftUI

struct ObligationsView: View {
    @Environment(AppSession.self) private var session
    @State private var search = ""
    @State private var showArchived = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { obligation in
                    NavigationLink {
                        ObligationDetailView(obligationID: obligation.id)
                    } label: {
                        HStack {
                            Image(systemName: obligation.icon)
                                .foregroundStyle(AppColors.token(obligation.colorToken))
                            VStack(alignment: .leading) {
                                Text(obligation.title)
                                Text(obligation.recurrenceRule.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let amount = obligation.amount {
                                MoneyText(amount)
                            }
                        }
                    }
                    .swipeActions {
                        Button("Pause") {
                            Task { try? await session.store.setLifecycle(obligation.id, lifecycle: .paused); await session.refresh() }
                        }
                        Button("Archive") {
                            Task { try? await session.store.setLifecycle(obligation.id, lifecycle: .archived); await session.refresh() }
                        }
                    }
                }
            }
            .navigationTitle("Obligations")
            .searchable(text: $search)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        session.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add obligation")
                }
                ToolbarItem(placement: .automatic) {
                    Toggle("Archived", isOn: $showArchived)
                }
            }
            .overlay {
                if filtered.isEmpty {
                    EmptyStateView(
                        title: "No obligations yet",
                        systemImage: "wallet.pass",
                        message: "Add your first bill, EMI or subscription.",
                        actionTitle: "Add"
                    ) {
                        session.showAddSheet = true
                    }
                }
            }
        }
    }

    private var filtered: [Obligation] {
        session.snapshot.obligations
            .filter { showArchived ? $0.lifecycle == .archived : $0.lifecycle != .archived }
            .filter {
                search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || ($0.providerName?.localizedCaseInsensitiveContains(search) ?? false)
            }
            .sorted { $0.title < $1.title }
    }
}

struct ObligationDetailView: View {
    @Environment(AppSession.self) private var session
    var obligationID: UUID
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        if let obligation = session.snapshot.obligations.first(where: { $0.id == obligationID }) {
            content(obligation)
        } else {
            ContentUnavailableView("Obligation unavailable", systemImage: "questionmark")
        }
    }

    @ViewBuilder
    private func content(_ obligation: Obligation) -> some View {
        let records = session.records().filter { $0.obligation.id == obligation.id }
        let progress = session.emi.progress(obligation: obligation, occurrences: session.snapshot.occurrences)
        List {
            Section {
                Label(obligation.title, systemImage: obligation.icon)
                LabeledContent("Recurrence", value: obligation.recurrenceRule.summary)
                LabeledContent("Amount") {
                    MoneyText(obligation.amount)
                }
                if let next = records.first(where: { $0.occurrence.status == .pending }) {
                    LabeledContent("Next due", value: Formatters.date(next.occurrence.scheduledDate))
                }
            }
            if obligation.emi != nil {
                Section("Loan") {
                    LabeledContent("Installments", value: progress.display)
                    if let remaining = progress.remainingInstallments {
                        LabeledContent("Remaining", value: "\(remaining)")
                    }
                    LabeledContent("Provider", value: obligation.emi?.loanProvider ?? "—")
                    LabeledContent("Deduction bank", value: obligation.emi?.deductionBank ?? "—")
                    if progress.isComplete {
                        Text("Loan Completed")
                            .foregroundStyle(.green)
                    }
                }
            }
            Section("Payment history") {
                ForEach(records.filter { $0.occurrence.status == .paid }) { record in
                    NavigationLink {
                        OccurrenceDetailView(record: record)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(Formatters.monthYear(record.occurrence.scheduledDate))
                            if let payment = record.payments.first {
                                Text("Paid \(payment.paidAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                MoneyText(payment.amount)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(obligation.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let next = records.first(where: { $0.occurrence.status == .pending }) {
                    Button("Mark Paid") { session.pendingPayment = next }
                }
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            ObligationEditor(existing: obligation)
        }
        .confirmationDialog("Delete obligation?", isPresented: $confirmDelete) {
            Button("Delete this and future", role: .destructive) {
                Task {
                    let next = records.first { $0.occurrence.status == .pending }
                    try? await session.store.deleteObligation(obligation.id, scope: .thisAndFuture, occurrenceID: next?.occurrence.id)
                    await session.refresh()
                }
            }
            Button("Archive entire series", role: .destructive) {
                Task { try? await session.store.deleteObligation(obligation.id, scope: .entireSeries, occurrenceID: nil); await session.refresh() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Delete / Archive", role: .destructive) { confirmDelete = true }
                .padding()
        }
    }
}
