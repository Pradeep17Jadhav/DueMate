import DueMateCore
import SwiftUI

public struct WidgetUpcomingView: View {
    public var snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        if let item = snapshot.upcoming.first {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                MoneyText(item.amount, hideAmount: snapshot.hideAmounts)
                    .font(.title3.weight(.semibold))
                Text(duePhrase(item.scheduledDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            Text("No upcoming payments")
                .foregroundStyle(.secondary)
        }
    }
}

public struct WidgetTodayView: View {
    public var snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(snapshot.today.count) payments")
                .font(.headline)
            MoneyText(
                Money(amount: snapshot.today.compactMap(\.amount).reduce(0) { $0 + $1.amount }, currencyCode: "INR"),
                hideAmount: snapshot.hideAmounts
            )
            ForEach(snapshot.today.prefix(3)) { item in
                Text("• \(item.title)")
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct WidgetUpcomingListView: View {
    public var snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPCOMING")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(snapshot.upcoming.prefix(5)) { item in
                HStack {
                    Text(duePhrase(item.scheduledDate))
                        .foregroundStyle(.secondary)
                    Text(item.title)
                        .lineLimit(1)
                    Spacer()
                    MoneyText(item.amount, hideAmount: snapshot.hideAmounts)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct WidgetMonthlyView: View {
    public var snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Formatters.monthYear(.today))
                .font(.headline)
            LabeledContent("Paid") {
                MoneyText(snapshot.monthPaid, hideAmount: snapshot.hideAmounts)
            }
            LabeledContent("Pending") {
                MoneyText(snapshot.monthPending, hideAmount: snapshot.hideAmounts)
            }
            LabeledContent("Total") {
                MoneyText(snapshot.monthPaid + snapshot.monthPending, hideAmount: snapshot.hideAmounts)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct WidgetLoansView: View {
    public var snapshot: WidgetSnapshot

    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LOANS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(snapshot.loans) { loan in
                VStack(alignment: .leading, spacing: 4) {
                    Text(loan.title)
                    if let total = loan.total {
                        ProgressView(value: Double(loan.paid), total: Double(max(total, 1)))
                        Text("\(loan.paid) / \(total) paid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(loan.paid) paid")
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

func duePhrase(_ date: CalendarDate) -> String {
    let today = CalendarDate.today
    if date == today { return "Due today" }
    if date == today.adding(days: 1) { return "Due tomorrow" }
    return "Due \(Formatters.date(date, style: .medium))"
}
