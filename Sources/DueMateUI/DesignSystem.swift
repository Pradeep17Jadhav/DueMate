import DueMateCore
import SwiftUI

public enum AppSpacing {
    public static let xSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xLarge: CGFloat = 32
}

public enum AppCornerRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 18
}

public enum AppColors {
    public static func token(_ name: String) -> Color {
        switch name {
        case "blue": .blue
        case "purple": .purple
        case "orange": .orange
        case "green": .green
        case "teal": .teal
        case "indigo": .indigo
        case "red": .red
        case "mint": .mint
        case "brown": .brown
        case "gray", "neutral": .gray
        default: .accentColor
        }
    }

    public static func status(_ status: DisplayOccurrenceStatus) -> Color {
        switch status {
        case .paid: .green
        case .overdue: .red
        case .pending: .orange
        case .scheduled: .secondary
        case .skipped, .cancelled: .gray
        }
    }
}
