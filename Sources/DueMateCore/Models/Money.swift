import Foundation

/// Decimal-based money. Never use `Double` for financial values.
public struct Money: Hashable, Sendable, Codable, Comparable {
    public var amount: Decimal
    public var currencyCode: String

    public init(amount: Decimal, currencyCode: String = "INR") {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    public init(amount: Int, currencyCode: String = "INR") {
        self.amount = Decimal(amount)
        self.currencyCode = currencyCode
    }

    public static var zeroINR: Money { Money(amount: 0, currencyCode: "INR") }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount + rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount - rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.amount < rhs.amount
    }

    public var isZero: Bool { amount == 0 }

    enum CodingKeys: String, CodingKey {
        case amount
        case currencyCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "INR"
        if let string = try? container.decode(String.self, forKey: .amount),
           let decimal = Decimal(string: string) {
            amount = decimal
        } else if let decimal = try? container.decode(Decimal.self, forKey: .amount) {
            amount = decimal
        } else if let double = try? container.decode(Double.self, forKey: .amount) {
            amount = Decimal(double)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: container,
                debugDescription: "Unsupported amount encoding"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(NSDecimalNumber(decimal: amount).stringValue, forKey: .amount)
        try container.encode(currencyCode, forKey: .currencyCode)
    }
}

public enum AmountKind: String, Codable, Sendable, CaseIterable {
    case fixed
    case variable
    case unknown
}
