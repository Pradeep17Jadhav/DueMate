import Foundation

public enum SampleData {
    public static func make(asOf: CalendarDate = .today, calendar: Calendar = Calendar(identifier: .gregorian)) -> Snapshot {
        let categories = ObligationCategory.systemDefaults
        func category(_ name: String) -> ObligationCategory {
            categories.first { $0.name == name } ?? categories[0]
        }

        let hdfcCard = Obligation(
            title: "HDFC Credit Card",
            categoryId: category("Credit Card").id,
            icon: "creditcard.fill",
            colorToken: "blue",
            amount: Money(amount: 18_420),
            amountKind: .variable,
            recurrenceRule: .monthly(day: 5),
            startDate: CalendarDate(year: asOf.year, month: 1, day: 5),
            providerName: "HDFC Bank",
            accountReference: "•••• 4242",
            reminders: [ReminderOffset(daysBefore: 1)],
            creditCard: CreditCardDetails(issuingBank: "HDFC Bank", statementDay: 20, lastFourDigits: "4242"),
            lastPaymentMethod: .upi,
            lastPaymentApp: "Google Pay",
            lastPaymentBank: "HDFC Bank"
        )

        let iciciCard = Obligation(
            title: "ICICI Credit Card",
            categoryId: category("Credit Card").id,
            icon: "creditcard.fill",
            colorToken: "blue",
            amount: Money(amount: 9_800),
            amountKind: .variable,
            recurrenceRule: .monthly(day: 12),
            startDate: CalendarDate(year: asOf.year, month: 1, day: 12),
            providerName: "ICICI Bank",
            creditCard: CreditCardDetails(issuingBank: "ICICI Bank", lastFourDigits: "1901")
        )

        let homeLoan = Obligation(
            title: "Home Loan EMI",
            categoryId: category("EMI").id,
            icon: "building.columns.fill",
            colorToken: "purple",
            amount: Money(amount: 33_000),
            amountKind: .fixed,
            recurrenceRule: .monthly(day: 7),
            startDate: CalendarDate(year: 2022, month: 4, day: 7),
            providerName: "HDFC Bank",
            reminders: [ReminderOffset(daysBefore: 3), ReminderOffset(daysBefore: 0)],
            emi: EMIDetails(
                loanType: .home,
                loanProvider: "HDFC Bank",
                deductionBank: "HDFC Bank",
                tenureMonths: 120,
                totalInstallments: 120,
                startDate: CalendarDate(year: 2022, month: 4, day: 7)
            )
        )

        let carLoan = Obligation(
            title: "Car Loan EMI",
            categoryId: category("EMI").id,
            icon: "car.fill",
            colorToken: "purple",
            amount: Money(amount: 18_500),
            amountKind: .fixed,
            recurrenceRule: .monthly(day: 1),
            startDate: CalendarDate(year: 2024, month: 6, day: 1),
            emi: EMIDetails(
                loanType: .car,
                loanProvider: "Axis Bank",
                deductionBank: "HDFC Bank",
                tenureMonths: 84,
                totalInstallments: 84,
                startDate: CalendarDate(year: 2024, month: 6, day: 1)
            )
        )

        let electricity = Obligation(
            title: "Electricity",
            categoryId: category("Utility").id,
            icon: "bolt.fill",
            colorToken: "orange",
            amountKind: .variable,
            recurrenceRule: .monthly(day: 15),
            startDate: CalendarDate(year: asOf.year, month: 1, day: 15),
            providerName: "BESCOM"
        )

        let internet = Obligation(
            title: "Internet",
            categoryId: category("Utility").id,
            icon: "wifi",
            colorToken: "orange",
            amount: Money(amount: 999),
            amountKind: .fixed,
            recurrenceRule: .monthly(day: 3),
            startDate: CalendarDate(year: asOf.year, month: 1, day: 3),
            providerName: "Airtel"
        )

        let insurance = Obligation(
            title: "Term Insurance",
            categoryId: category("Insurance").id,
            icon: "shield.fill",
            colorToken: "green",
            amount: Money(amount: 18_000),
            amountKind: .fixed,
            recurrenceRule: .yearly(month: 7, day: 10),
            startDate: CalendarDate(year: asOf.year - 2, month: 7, day: 10),
            providerName: "HDFC Life"
        )

        let netflix = Obligation(
            title: "Netflix",
            categoryId: category("Subscription").id,
            icon: "play.tv.fill",
            colorToken: "teal",
            amount: Money(amount: 649),
            amountKind: .fixed,
            recurrenceRule: .monthly(day: 21),
            startDate: CalendarDate(year: asOf.year, month: 1, day: 21)
        )

        let propertyTax = Obligation(
            title: "Property Tax",
            categoryId: category("Tax").id,
            icon: "doc.text.fill",
            colorToken: "red",
            amount: Money(amount: 12_400),
            amountKind: .fixed,
            recurrenceRule: .yearly(month: 4, day: 30),
            startDate: CalendarDate(year: asOf.year, month: 4, day: 30)
        )

        let obligations = [hdfcCard, iciciCard, homeLoan, carLoan, electricity, internet, insurance, netflix, propertyTax]
        let planner = OccurrencePlanner()
        var occurrences: [Occurrence] = []
        for obligation in obligations {
            occurrences = planner.generate(obligation: obligation, existing: occurrences, asOf: asOf)
        }

        func occurrence(_ obligation: Obligation, date: CalendarDate) -> Occurrence? {
            occurrences.first { $0.obligationId == obligation.id && $0.scheduledDate == date }
        }

        var payments: [Payment] = []

        let lastMonth = asOf.adding(months: -1)
        if var paidCard = occurrence(hdfcCard, date: CalendarDate(year: lastMonth.year, month: lastMonth.month, day: 5)) {
            paidCard.status = .paid
            replace(&occurrences, paidCard)
            payments.append(
                Payment(
                    occurrenceId: paidCard.id,
                    paidAt: paidCard.scheduledDate.foundationDate() ?? Date(),
                    amount: Money(amount: 17_900),
                    paymentMethod: .upi,
                    paymentApp: "Google Pay",
                    paymentBank: "HDFC Bank"
                )
            )
        }

        if var paidHome = occurrence(homeLoan, date: CalendarDate(year: asOf.year, month: asOf.month, day: 7)),
           paidHome.scheduledDate < asOf {
            paidHome.status = .paid
            paidHome.balanceStatus = .sufficient
            replace(&occurrences, paidHome)
            payments.append(
                Payment(
                    occurrenceId: paidHome.id,
                    paidAt: paidHome.scheduledDate.foundationDate() ?? Date(),
                    amount: Money(amount: 33_000),
                    paymentMethod: .autoDebit,
                    paymentBank: "HDFC Bank"
                )
            )
        }

        if var overdueElectricity = occurrence(electricity, date: CalendarDate(year: lastMonth.year, month: lastMonth.month, day: 15)) {
            overdueElectricity.expectedAmount = Money(amount: 2_847)
            replace(&occurrences, overdueElectricity)
        }

        if var thisElectricity = occurrence(electricity, date: CalendarDate(year: asOf.year, month: asOf.month, day: 15)) {
            thisElectricity.expectedAmount = Money(amount: 3_200)
            replace(&occurrences, thisElectricity)
        }

        let historicalHome = historicalPaidEMI(obligation: homeLoan, until: asOf, already: occurrences)
        occurrences.append(contentsOf: historicalHome.occurrences)
        payments.append(contentsOf: historicalHome.payments)

        return Snapshot(
            categories: categories,
            obligations: obligations,
            occurrences: occurrences,
            payments: payments,
            settings: AppSettings(hasCompletedOnboarding: true)
        )
    }

    private static func replace(_ occurrences: inout [Occurrence], _ value: Occurrence) {
        occurrences.removeAll { $0.id == value.id }
        occurrences.append(value)
    }

    private static func historicalPaidEMI(obligation: Obligation, until asOf: CalendarDate, already: [Occurrence]) -> (occurrences: [Occurrence], payments: [Payment]) {
        guard let start = obligation.emi?.startDate else { return ([], []) }
        let recurrence = RecurrenceService()
        let cutoff = asOf.adding(months: -1).endOfMonth()
        let dates = recurrence.dates(from: start, rule: obligation.recurrenceRule, through: cutoff)
        let existing = Set(already.filter { $0.obligationId == obligation.id }.map(\.scheduledDate))
        var extra: [Occurrence] = []
        var payments: [Payment] = []
        for (index, date) in dates.enumerated() where !existing.contains(date) {
            let occurrence = Occurrence(
                obligationId: obligation.id,
                scheduledDate: date,
                status: .paid,
                expectedAmount: obligation.amount,
                installmentNumber: index + 1
            )
            extra.append(occurrence)
            payments.append(
                Payment(
                    occurrenceId: occurrence.id,
                    paidAt: date.foundationDate() ?? Date(),
                    amount: obligation.amount ?? .zeroINR,
                    paymentMethod: .autoDebit,
                    paymentBank: obligation.emi?.deductionBank
                )
            )
        }
        return (extra, payments)
    }
}

public enum AppLog {
    public static func debug(_ message: String, category: String) {
        #if DEBUG
        print("[\(category)] \(message)")
        #endif
    }
}
