import AppKit

final class StatisticsView: NSView {
    private let db = DatabaseManager()

    private let todayCircleView = NSView()
    private let todayCountLabel = NSTextField(labelWithString: "0")
    private let todayGoalLabel = NSTextField(labelWithString: "/ 8 番茄")
    private let focusTimeLabel = NSTextField(labelWithString: "0h 0m")
    private let breakTimeLabel = NSTextField(labelWithString: "0m")
    private let weekChartView = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadData()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0).cgColor

        // Title
        let titleLabel = NSTextField(labelWithString: "今日完成")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Circle progress
        todayCircleView.wantsLayer = true
        todayCircleView.layer?.borderWidth = 8
        todayCircleView.layer?.borderColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0).cgColor
        todayCircleView.layer?.cornerRadius = 50
        todayCircleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(todayCircleView)

        todayCountLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        todayCountLabel.textColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)
        todayCountLabel.alignment = .center
        todayCountLabel.translatesAutoresizingMaskIntoConstraints = false
        todayCircleView.addSubview(todayCountLabel)

        todayGoalLabel.font = .systemFont(ofSize: 10)
        todayGoalLabel.textColor = .secondaryLabelColor
        todayGoalLabel.alignment = .center
        todayGoalLabel.translatesAutoresizingMaskIntoConstraints = false
        todayCircleView.addSubview(todayGoalLabel)

        // Stats row
        let statsStack = NSStackView()
        statsStack.orientation = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        let focusView = createStatView(valueLabel: focusTimeLabel, title: "专注时长")
        let breakView = createStatView(valueLabel: breakTimeLabel, title: "休息时长")

        statsStack.addArrangedSubview(focusView)
        statsStack.addArrangedSubview(breakView)
        addSubview(statsStack)

        // Week title
        let weekTitle = NSTextField(labelWithString: "近 7 天")
        weekTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        weekTitle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(weekTitle)

        // Week chart placeholder
        weekChartView.wantsLayer = true
        weekChartView.layer?.backgroundColor = NSColor.white.cgColor
        weekChartView.layer?.cornerRadius = 8
        weekChartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(weekChartView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            todayCircleView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            todayCircleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            todayCircleView.widthAnchor.constraint(equalToConstant: 100),
            todayCircleView.heightAnchor.constraint(equalToConstant: 100),

            todayCountLabel.centerXAnchor.constraint(equalTo: todayCircleView.centerXAnchor),
            todayCountLabel.centerYAnchor.constraint(equalTo: todayCircleView.centerYAnchor, constant: -8),

            todayGoalLabel.topAnchor.constraint(equalTo: todayCountLabel.bottomAnchor, constant: 2),
            todayGoalLabel.centerXAnchor.constraint(equalTo: todayCircleView.centerXAnchor),

            statsStack.topAnchor.constraint(equalTo: todayCircleView.bottomAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            statsStack.heightAnchor.constraint(equalToConstant: 60),

            weekTitle.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 16),
            weekTitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            weekChartView.topAnchor.constraint(equalTo: weekTitle.bottomAnchor, constant: 8),
            weekChartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            weekChartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            weekChartView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func createStatView(valueLabel: NSTextField, title: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.cgColor
        container.layer?.cornerRadius = 8

        valueLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        valueLabel.textColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)
        valueLabel.alignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 9)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])

        return container
    }

    func loadData() {
        guard let record = db.fetchTodayRecord() else { return }
        todayCountLabel.stringValue = "\(record.completedPomodoros)"
        let hours = record.focusHours
        let focusHours = Int(hours)
        let focusMinutes = Int((hours - Double(focusHours)) * 60)
        focusTimeLabel.stringValue = focusHours > 0 ? "\(focusHours)h \(focusMinutes)m" : "\(focusMinutes)m"
        breakTimeLabel.stringValue = "\(record.totalBreakMinutes)m"
    }
}
