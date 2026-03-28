import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    var onShowPopover: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            // Load from app bundle - try tiff first
            if let bundlePath = Bundle.main.path(forResource: "16x16", ofType: "tiff"),
               let image = NSImage(contentsOfFile: bundlePath) {
                button.image = image
                button.image?.isTemplate = true  // Important for menu bar icons
            } else {
                // Fallback to SF Symbol or emoji
                if let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro") {
                    button.image = image
                } else {
                    button.title = "🍅"
                }
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
    }

    func setPopoverContent(_ viewController: NSViewController) {
        popover?.contentViewController = viewController
    }

    @objc private func togglePopover() {
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            if let button = statusItem?.button {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                onShowPopover?()
            }
        }
    }

    func closePopover() {
        popover?.performClose(nil)
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
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pomodoro") {
            statusItem?.button?.image = image
        }
    }
}
