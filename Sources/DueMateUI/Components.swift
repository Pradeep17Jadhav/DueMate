import DueMateCore
import SwiftUI

public struct StatusBadge: View {
    public var status: DisplayOccurrenceStatus

    public init(status: DisplayOccurrenceStatus) {
        self.status = status
    }

    public var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.status(status))
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(AppColors.status(status).opacity(0.12), in: Capsule())
            .accessibilityLabel(title)
    }

    private var title: String {
        switch status {
        case .pending: "Pending"
        case .paid: "Paid"
        case .skipped: "Skipped"
        case .cancelled: "Cancelled"
        case .overdue: "Overdue"
        case .scheduled: "Scheduled"
        }
    }

    private var icon: String {
        switch status {
        case .pending: "clock"
        case .paid: "checkmark.circle.fill"
        case .skipped: "forward.fill"
        case .cancelled: "xmark.circle"
        case .overdue: "exclamationmark.triangle.fill"
        case .scheduled: "calendar"
        }
    }
}

public struct MoneyText: View {
    public var money: Money?
    public var hideAmount: Bool

    public init(_ money: Money?, hideAmount: Bool = false) {
        self.money = money
        self.hideAmount = hideAmount
    }

    public var body: some View {
        Text(MoneyFormatter.string(from: money, hideAmount: hideAmount))
            .monospacedDigit()
    }
}

public struct CategoryBadge: View {
    public var category: ObligationCategory?

    public init(_ category: ObligationCategory?) {
        self.category = category
    }

    public var body: some View {
        if let category {
            Label(category.name, systemImage: category.icon)
                .font(.caption)
                .foregroundStyle(AppColors.token(category.colorToken))
        }
    }
}

public struct EmptyStateView: View {
    public var title: String
    public var systemImage: String
    public var message: String
    public var actionTitle: String?
    public var action: (() -> Void)?

    public init(title: String, systemImage: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

public struct SummaryCard: View {
    public var title: String
    public var value: String
    public var systemImage: String
    public var tint: Color

    public init(title: String, value: String, systemImage: String, tint: Color) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.medium)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }
}

public struct ObligationRow: View {
    public var record: OccurrenceRecord
    public var asOf: CalendarDate

    public init(record: OccurrenceRecord, asOf: CalendarDate = .today) {
        self.record = record
        self.asOf = asOf
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: record.obligation.icon)
                .font(.title3)
                .foregroundStyle(AppColors.token(record.obligation.colorToken))
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.obligation.title)
                    .font(.headline)
                CategoryBadge(record.category)
                Text("Due \(Formatters.date(record.occurrence.scheduledDate, style: .medium))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                MoneyText(record.displayAmount)
                    .font(.headline)
                StatusBadge(status: record.occurrence.displayStatus(asOf: asOf))
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .opacity(record.occurrence.status == .paid ? 0.78 : 1)
        .accessibilityElement(children: .combine)
    }
}

public struct MoneyField: View {
    @Binding var text: String
    var currencyCode: String

    public init(text: Binding<String>, currencyCode: String = "INR") {
        _text = text
        self.currencyCode = currencyCode
    }

    public var body: some View {
        TextField("0", text: $text)
            .dueMateNumericKeyboard()
    }
}

extension View {
    @ViewBuilder
    func dueMateNumericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

public extension Decimal {
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }
}
