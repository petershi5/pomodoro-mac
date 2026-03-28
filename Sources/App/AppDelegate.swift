import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var timerViewController: TimerViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        timerViewController = TimerViewController()
        statusBarController = StatusBarController()
        statusBarController.setPopoverContent(timerViewController)
        statusBarController.onShowPopover = {
            // Refresh data when popover shows
        }

        Task {
            let notificationManager = NotificationManager()
            _ = await notificationManager.requestAuthorization()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController.closePopover()
    }
}
