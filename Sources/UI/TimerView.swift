import AppKit

final class TimerView: NSView {
    private let statusLabel = NSTextField(labelWithString: "空闲")
    private let timerLabel = NSTextField(labelWithString: "25:00")
    private let progressRing = CAShapeLayer()
    private let pomodoroCountLabel = NSTextField(labelWithString: "第 0 个番茄")

    private var startButton: NSButton!
    private var resetButton: NSButton!

    var onStart: (() -> Void)?
    var onPause: (() -> Void)?
    var onReset: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0).cgColor

        // Status label
        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        // Timer circle
        let circleContainer = NSView()
        circleContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleContainer)

        progressRing.fillColor = nil
        progressRing.strokeColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0).cgColor
        progressRing.lineWidth = 8
        progressRing.lineCap = .round
        circleContainer.layer?.addSublayer(progressRing)

        // Timer label
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        timerLabel.textColor = NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
        timerLabel.alignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        circleContainer.addSubview(timerLabel)

        // Pomodoro count
        pomodoroCountLabel.font = .systemFont(ofSize: 11)
        pomodoroCountLabel.textColor = .secondaryLabelColor
        pomodoroCountLabel.alignment = .center
        pomodoroCountLabel.translatesAutoresizingMaskIntoConstraints = false
        circleContainer.addSubview(pomodoroCountLabel)

        // Buttons
        startButton = NSButton(title: "开始", target: self, action: #selector(startTapped))
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(startButton)

        resetButton = NSButton(title: "重置", target: self, action: #selector(resetTapped))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resetButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            circleContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            circleContainer.widthAnchor.constraint(equalToConstant: 200),
            circleContainer.heightAnchor.constraint(equalToConstant: 200),

            timerLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: circleContainer.centerYAnchor, constant: -8),

            pomodoroCountLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 4),
            pomodoroCountLabel.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),

            startButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -50),
            startButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            startButton.widthAnchor.constraint(equalToConstant: 80),

            resetButton.leadingAnchor.constraint(equalTo: startButton.trailingAnchor, constant: 12),
            resetButton.centerYAnchor.constraint(equalTo: startButton.centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }

    override func layout() {
        super.layout()
        let center = CGPoint(x: 100, y: 100)
        let radius: CGFloat = 90
        let path = CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), transform: nil)
        progressRing.path = path
        progressRing.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
    }

    func update(state: PomodoroState, remainingSeconds: Int, progress: Double, pomodoroCount: Int) {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)

        pomodoroCountLabel.stringValue = "第 \(pomodoroCount) 个番茄"

        switch state {
        case .idle:
            statusLabel.stringValue = "空闲"
            startButton.title = "开始"
            startButton.action = #selector(startTapped)
        case .focusing:
            statusLabel.stringValue = "专注中"
            startButton.title = "暂停"
            startButton.action = #selector(pauseTapped)
        case .shortBreak:
            statusLabel.stringValue = "短休息"
            startButton.title = "暂停"
            startButton.action = #selector(pauseTapped)
        case .longBreak:
            statusLabel.stringValue = "长休息"
            startButton.title = "暂停"
            startButton.action = #selector(pauseTapped)
        case .paused:
            statusLabel.stringValue = "已暂停"
            startButton.title = "继续"
            startButton.action = #selector(startTapped)
        }

        progressRing.strokeEnd = CGFloat(progress)
    }

    @objc private func startTapped() { onStart?() }
    @objc private func pauseTapped() { onPause?() }
    @objc private func resetTapped() { onReset?() }
}
