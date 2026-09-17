import DueMateCore
import SwiftUI

struct AddObligationSheet: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        NavigationStack {
            List {
                ForEach(ObligationCategory.systemDefaults) { category in
                    NavigationLink(category.name) {
                        ObligationEditor(template: category)
                    }
                }
            }
            .navigationTitle("Add")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { session.showAddSheet = false }
                }
            }
        }
    }
}

struct ObligationEditor: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var existing: Obligation?
    var template: ObligationCategory?

    @State private var title = ""
    @State private var amountText = ""
    @State private var amountKind: AmountKind = .fixed
    @State private var dueDay = 5
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var interval = 1
    @State private var lastDay = false
    @State private var notes = ""
    @State private var provider = ""
    @State private var icon = "wallet.pass.fill"
    @State private var color = "blue"
    @State private var start = Date()
    @State private var reminder = 1
    @State private var loanType: LoanType = .home
    @State private var tenure = 120
    @State private var deductionBank = "HDFC Bank"
    @State private var loanProvider = ""
    @State private var statementDay = 20
    @State private var lastFour = ""
    @State private var issuingBank = ""
    @State private var validation: String?

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $title)
                if amountKind != .unknown {
                    TextField("Amount", text: $amountText)
                        .dueMateNumericKeyboard()
                }
                Picker("Amount type", selection: $amountKind) {
                    Text("Fixed").tag(AmountKind.fixed)
                    Text("Variable").tag(AmountKind.variable)
                    Text("Unknown").tag(AmountKind.unknown)
                }
                DatePicker("Start / first due", selection: $start, displayedComponents: .date)
            }
            Section("Schedule") {
                Picker("Repeats", selection: $frequency) {
                    Text("Daily").tag(RecurrenceFrequency.daily)
                    Text("Weekly").tag(RecurrenceFrequency.weekly)
                    Text("Monthly").tag(RecurrenceFrequency.monthly)
                    Text("Yearly").tag(RecurrenceFrequency.yearly)
                }
                Stepper("Every \(interval)", value: $interval, in: 1...24)
                if frequency == .monthly {
                    Toggle("Last day of month", isOn: $lastDay)
                    if !lastDay {
                        Stepper("Day \(dueDay)", value: $dueDay, in: 1...31)
                    }
                }
                Picker("Remind", selection: $reminder) {
                    Text("On due date").tag(0)
                    Text("1 day before").tag(1)
                    Text("3 days before").tag(3)
                    Text("7 days before").tag(7)
                }
            }
            if isCreditCard {
                Section("Card") {
                    TextField("Bank", text: $issuingBank)
                    Stepper("Statement day \(statementDay)", value: $statementDay, in: 1...31)
                    TextField("Last four digits", text: $lastFour)
                        .onChange(of: lastFour) { _, value in
                            lastFour = String(value.filter(\.isNumber).prefix(4))
                        }
                }
            }
            if isEMI {
                Section("Loan") {
                    Picker("Loan type", selection: $loanType) {
                        Text("Home").tag(LoanType.home)
                        Text("Car").tag(LoanType.car)
                        Text("Personal").tag(LoanType.personal)
                        Text("Education").tag(LoanType.education)
                        Text("Other").tag(LoanType.other)
                    }
                    TextField("Loan provider", text: $loanProvider)
                    Picker("Deduction bank", selection: $deductionBank) {
                        ForEach(PaymentDirectory.commonBanks, id: \.self, content: Text.init)
                    }
                    Stepper("Tenure \(tenure) months", value: $tenure, in: 1...360)
                }
            }
            Section("More") {
                TextField("Provider", text: $provider)
                TextField("Notes", text: $notes, axis: .vertical)
                Picker("Icon", selection: $icon) {
                    ForEach(["wallet.pass.fill", "creditcard.fill", "building.columns.fill", "bolt.fill", "repeat", "shield.fill"], id: \.self) { name in
                        Label(name, systemImage: name).tag(name)
                    }
                }
            }
            if let validation {
                Section {
                    Text(validation).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(existing == nil ? "New obligation" : "Edit")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
            }
        }
        .onAppear(perform: prefill)
    }

    private var isEMI: Bool {
        template?.name == "EMI" || existing?.emi != nil
    }

    private var isCreditCard: Bool {
        template?.name == "Credit Card" || existing?.creditCard != nil
    }

    private func prefill() {
        if let existing {
            title = existing.title
            amountText = existing.amount.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? ""
            amountKind = existing.amountKind
            frequency = existing.recurrenceRule.frequency
            interval = existing.recurrenceRule.interval
            dueDay = existing.recurrenceRule.dayOfMonth ?? 5
            lastDay = existing.recurrenceRule.dayOfMonth == -1
            notes = existing.notes ?? ""
            provider = existing.providerName ?? ""
            icon = existing.icon
            color = existing.colorToken
            start = existing.startDate.foundationDate() ?? Date()
            reminder = existing.reminders.first?.daysBefore ?? 1
            if let emi = existing.emi {
                loanType = emi.loanType
                tenure = emi.tenureMonths ?? 120
                deductionBank = emi.deductionBank ?? deductionBank
                loanProvider = emi.loanProvider ?? ""
            }
            if let card = existing.creditCard {
                issuingBank = card.issuingBank ?? ""
                statementDay = card.statementDay ?? 20
                lastFour = card.lastFourDigits ?? ""
            }
        } else if let template {
            title = template.name == "Other" ? "" : ""
            icon = template.icon
            color = template.colorToken
            if template.name == "Credit Card" { amountKind = .variable }
            if template.name == "Utility" { amountKind = .variable }
            if template.name == "EMI" { amountKind = .fixed }
        }
    }

    private func save() async {
        let startDate = CalendarDate(start)
        var rule: RecurrenceRule
        switch frequency {
        case .daily:
            rule = .daily(interval: interval)
        case .weekly:
            let weekday = Calendar.current.component(.weekday, from: start)
            rule = .weekly(interval: interval, weekday: weekday)
        case .monthly:
            rule = lastDay ? .lastDayOfMonth(interval: interval) : .monthly(day: dueDay, interval: interval)
        case .yearly:
            rule = .yearly(month: startDate.month, day: startDate.day, interval: interval)
        }
        let amount: Money?
        if amountKind == .unknown {
            amount = nil
        } else if let parsed = Decimal.parse(amountText) {
            amount = Money(amount: parsed)
        } else if amountKind == .variable {
            amount = nil
        } else {
            validation = "Enter a valid amount."
            return
        }

        let category = template ?? session.snapshot.categories.first { $0.id == existing?.categoryId } ?? ObligationCategory.systemDefaults.last!
        var obligation = existing ?? Obligation(
            title: title,
            categoryId: category.id,
            icon: icon,
            colorToken: color,
            amount: amount,
            amountKind: amountKind,
            recurrenceRule: rule,
            startDate: startDate
        )
        obligation.title = title
        obligation.amount = amount
        obligation.amountKind = amountKind
        obligation.recurrenceRule = rule
        obligation.startDate = startDate
        obligation.notes = notes.isEmpty ? nil : notes
        obligation.providerName = provider.isEmpty ? nil : provider
        obligation.icon = icon
        obligation.colorToken = color
        obligation.reminders = [ReminderOffset(daysBefore: reminder)]
        obligation.categoryId = category.id
        if isEMI {
            obligation.emi = EMIDetails(
                loanType: loanType,
                loanProvider: loanProvider.isEmpty ? nil : loanProvider,
                deductionBank: deductionBank,
                tenureMonths: tenure,
                totalInstallments: tenure,
                startDate: startDate
            )
            obligation.endDate = EMIService().approximateEndDate(start: startDate, tenureMonths: tenure)
        }
        if isCreditCard {
            obligation.creditCard = CreditCardDetails(
                issuingBank: issuingBank.isEmpty ? nil : issuingBank,
                statementDay: statementDay,
                lastFourDigits: lastFour.isEmpty ? nil : lastFour
            )
        }
        if obligation.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validation = "Enter a name for this obligation."
            return
        }
        await session.saveObligation(obligation)
        dismiss()
    }
}
