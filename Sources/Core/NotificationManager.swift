import Foundation
import UserNotifications

final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Notification auth failed: \(error)")
            return false
        }
    }

    func sendFocusCompleteNotification(pomodorosCompleted: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "专注完成！"
        content.body = "已完成了 \(pomodorosCompleted) 个番茄钟，去休息一下吧"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("Notification send failed: \(error)")
        }
    }

    func sendBreakCompleteNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "休息结束！"
        content.body = "准备好开始下一个番茄钟了吗？"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("Notification send failed: \(error)")
        }
    }
}
