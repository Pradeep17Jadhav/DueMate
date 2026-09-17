import DueMateCore
import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

public actor NotificationScheduler {
    public static let shared = NotificationScheduler()

    public func requestPermission() async -> Bool {
        #if canImport(UserNotifications)
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    public func reschedule(snapshot: Snapshot) async {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard snapshot.settings.notificationsEnabled else { return }

        let horizon = CalendarDate.today.adding(days: 60)
        let obligations = Dictionary(uniqueKeysWithValues: snapshot.obligations.map { ($0.id, $0) })
        for occurrence in snapshot.occurrences where occurrence.status == .pending && occurrence.scheduledDate <= horizon {
            guard let obligation = obligations[occurrence.obligationId], obligation.lifecycle == .active else { continue }
            let offsets = obligation.reminders.isEmpty
                ? snapshot.settings.defaultReminderDaysBefore.map { ReminderOffset(daysBefore: $0) }
                : obligation.reminders
            for reminder in offsets {
                let fireDate = occurrence.scheduledDate.adding(days: -reminder.daysBefore)
                guard fireDate >= CalendarDate.today,
                      let date = fireDate.foundationDate() else { continue }
                var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                components.hour = 9
                let content = UNMutableNotificationContent()
                content.title = obligation.title
                let amount = MoneyFormatter.string(from: occurrence.expectedAmount ?? obligation.amount)
                if reminder.daysBefore == 0 {
                    content.body = "\(amount) due today."
                } else if reminder.daysBefore == 1 {
                    content.body = "\(amount) due tomorrow."
                } else {
                    content.body = "\(amount) due in \(reminder.daysBefore) days."
                }
                content.sound = .default
                content.userInfo = ["occurrenceId": occurrence.id.uuidString]
                content.threadIdentifier = occurrence.id.uuidString
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(occurrence.id.uuidString)-\(reminder.daysBefore)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
        #endif
    }
}
