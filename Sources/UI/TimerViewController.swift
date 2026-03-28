import AppKit

final class TimerViewController: NSViewController {
    private let timerView = TimerView()
    private let statisticsView = StatisticsView()
    private let settingsView = SettingsView()
    private let timer = PomodoroTimer()
    private let notificationManager = NotificationManager()
    private let settings = SettingsStore()

    private var tabView: NSSegmentedControl!
    private var containerView: NSView!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTimerCallbacks()
        updateUI()
        showTab(0)
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0).cgColor

        // Tab bar
        tabView = NSSegmentedControl(labels: ["计时器", "统计", "设置"], trackingMode: .selectOne, target: self, action: #selector(tabChanged))
        tabView.selectedSegment = 0
        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)

        // Container for content views
        containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Timer view
        timerView.translatesAutoresizingMaskIntoConstraints = false
        timerView.isHidden = true
        containerView.addSubview(timerView)

        // Statistics view
        statisticsView.translatesAutoresizingMaskIntoConstraints = false
        statisticsView.isHidden = true
        containerView.addSubview(statisticsView)

        // Settings view
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.isHidden = true
        containerView.addSubview(settingsView)

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            containerView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            timerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            timerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            timerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            timerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            statisticsView.topAnchor.constraint(equalTo: containerView.topAnchor),
            statisticsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statisticsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            statisticsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            settingsView.topAnchor.constraint(equalTo: containerView.topAnchor),
            settingsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            settingsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            settingsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
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
        showTab(tabView.selectedSegment)
    }

    private func showTab(_ index: Int) {
        timerView.isHidden = index != 0
        statisticsView.isHidden = index != 1
        settingsView.isHidden = index != 2

        if index == 1 {
            statisticsView.loadData()
        }
    }
}
