import DueMateCore
import SwiftUI

struct OccurrenceDetailView: View {
    @Environment(AppSession.self) private var session
    var record: OccurrenceRecord
    @State private var confirmDeletePayment = false
    @State private var scope: SeriesEditScope = .thisOccurrence
    @State private var showScope = false

    var body: some View {
        let live = session.records().first(where: { $0.occurrence.id == record.occurrence.id }) ?? record
        List {
            Section {
                ObligationRow(record: live)
                if let expected = live.occurrence.expectedAmount, let paid = live.payments.first, expected.amount != paid.amount.amount {
                    LabeledContent("Expected") { MoneyText(expected) }
                    LabeledContent("Paid") { MoneyText(paid.amount) }
                }
            }
            if live.obligation.emi != nil {
                Section("EMI") {
                    Picker("Bank balance", selection: balanceBinding(live)) {
                        Text("Enough balance").tag(EMIBalanceStatus.sufficient)
                        Text("Need to add funds").tag(EMIBalanceStatus.insufficient)
                        Text("Unknown").tag(EMIBalanceStatus.unknown)
                    }
                    if let number = live.occurrence.installmentNumber {
                        LabeledContent("Installment", value: "\(number)")
                    }
                }
            }
            if let payment = live.payments.first {
                Section("Payment") {
                    LabeledContent("Paid on", value: payment.paidAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Method", value: payment.paymentMethod.title)
                    LabeledContent("App", value: payment.paymentApp ?? "—")
                    LabeledContent("Bank", value: payment.paymentBank ?? "—")
                    LabeledContent("Reference", value: payment.transactionReference ?? "—")
                    Button("Edit payment") { session.editingPayment = payment }
                    Button("Delete payment", role: .destructive) { confirmDeletePayment = true }
                }
            }
        }
        .navigationTitle(live.obligation.title)
        .toolbar {
            if live.occurrence.status != .paid {
                ToolbarItem(placement: .primaryAction) {
                    Button("Mark Paid") { session.pendingPayment = live }
                }
            }
        }
        .confirmationDialog("Delete this payment?", isPresented: $confirmDeletePayment) {
            Button("Delete payment", role: .destructive) {
                if let id = live.payments.first?.id {
                    Task { try? await session.store.deletePayment(id); await session.refresh() }
                }
            }
        } message: {
            Text("The occurrence will return to Pending.")
        }
    }

    private func balanceBinding(_ live: OccurrenceRecord) -> Binding<EMIBalanceStatus> {
        Binding(
            get: { live.occurrence.balanceStatus },
            set: { status in
                var occurrence = live.occurrence
                occurrence.balanceStatus = status
                Task { try? await session.store.updateOccurrence(occurrence); await session.refresh() }
            }
        )
    }
}

struct PaymentSheet: View {
    @Environment(AppSession.self) private var session
    var record: OccurrenceRecord
    var existing: Payment?
    @State private var amountText = ""
    @State private var paidAt = Date()
    @State private var method: PaymentMethod = .upi
    @State private var appName = "Google Pay"
    @State private var bank = "HDFC Bank"
    @State private var reference = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .dueMateNumericKeyboard()
                }
                Section("When") {
                    DatePicker("Paid on", selection: $paidAt)
                }
                Section("How") {
                    Picker("Method", selection: $method) {
                        ForEach(PaymentMethod.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    Picker("App", selection: $appName) {
                        ForEach(PaymentDirectory.defaultApps, id: \.self, content: Text.init)
                    }
                    Picker("Bank", selection: $bank) {
                        ForEach(PaymentDirectory.commonBanks, id: \.self, content: Text.init)
                    }
                    TextField("Transaction reference", text: $reference)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(existing == nil ? "Mark as Paid" : "Edit Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        session.pendingPayment = nil
                        session.editingPayment = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(Decimal.parse(amountText) == nil)
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        if let existing {
            amountText = NSDecimalNumber(decimal: existing.amount.amount).stringValue
            paidAt = existing.paidAt
            method = existing.paymentMethod
            appName = existing.paymentApp ?? appName
            bank = existing.paymentBank ?? bank
            reference = existing.transactionReference ?? ""
            notes = existing.notes ?? ""
        } else {
            let draft = session.paymentService.prefill(for: record.obligation, occurrence: record.occurrence)
            amountText = NSDecimalNumber(decimal: draft.amount.amount).stringValue
            paidAt = draft.paidAt
            method = draft.paymentMethod
            appName = draft.paymentApp ?? appName
            bank = draft.paymentBank ?? bank
        }
    }

    private func save() async {
        guard let amount = Decimal.parse(amountText) else { return }
        let draft = PaymentDraft(
            amount: Money(amount: amount, currencyCode: record.displayAmount?.currencyCode ?? "INR"),
            paidAt: paidAt,
            paymentMethod: method,
            paymentApp: appName,
            paymentBank: bank,
            transactionReference: reference.isEmpty ? nil : reference,
            notes: notes.isEmpty ? nil : notes
        )
        if var existing {
            existing.amount = draft.amount
            existing.paidAt = draft.paidAt
            existing.paymentMethod = draft.paymentMethod
            existing.paymentApp = draft.paymentApp
            existing.paymentBank = draft.paymentBank
            existing.transactionReference = draft.transactionReference
            existing.notes = draft.notes
            try? await session.store.updatePayment(existing)
            session.editingPayment = nil
            await session.refresh()
        } else {
            await session.markPaid(record: record, draft: draft)
        }
    }
}
