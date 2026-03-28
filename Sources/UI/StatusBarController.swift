import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    var onShowPopover: (() -> Void)?

    init() {
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.animates = true
    }

    func setPopoverContent(_ viewController: NSViewController) {
        popover.contentViewController = viewController
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        onShowPopover?()
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func updateIcon(state: PomodoroState) {
        let symbolName: String
        switch state {
        case .idle:
            symbolName = "timer"
        case .focusing:
            symbolName = "timer.circle.fill"
        case .shortBreak, .longBreak:
            symbolName = "cup.and.saucer.fill"
        case .paused:
            symbolName = "pause.circle.fill"
        }
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pomodoro")
    }
}
