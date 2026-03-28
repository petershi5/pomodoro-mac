import AppKit

final class TimerViewController: NSViewController {
    private let timerView = TimerView()
    private let timer = PomodoroTimer()
    private let notificationManager = NotificationManager()
    private let settings = SettingsStore()

    private var tabView: NSSegmentedControl!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimerCallbacks()
        updateUI()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0).cgColor

        // Tab bar
        tabView = NSSegmentedControl(labels: ["计时器", "统计", "设置"], trackingMode: .selectOne, target: self, action: #selector(tabChanged))
        tabView.selectedSegment = 0
        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)

        // Timer view
        timerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerView)

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            timerView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 12),
            timerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        timerView.onStart = { [weak self] in
            self?.timer.start()
        }
        timerView.onPause = { [weak self] in
            self?.timer.pause()
        }
        timerView.onReset = { [weak self] in
            self?.timer.reset()
        }
    }

    private func setupTimerCallbacks() {
        timer.onTick = { [weak self] remaining in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        timer.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        timer.onPomodoroCompleted = { [weak self] in
            guard let self = self else { return }
            Task {
                await self.notificationManager.sendFocusCompleteNotification(pomodorosCompleted: self.timer.currentPomodoroCount)
            }
        }
    }

    private func updateUI() {
        timerView.update(
            state: timer.state,
            remainingSeconds: timer.remainingSeconds,
            progress: timer.progress,
            pomodoroCount: timer.currentPomodoroCount
        )
    }

    @objc private func tabChanged() {
        // Placeholder for tab navigation - statistics and settings views will be added in separate tasks
    }
}
