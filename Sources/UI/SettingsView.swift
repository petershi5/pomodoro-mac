import AppKit

final class SettingsView: NSView {
    private let settings = SettingsStore()

    private let focusDurationStepper = NSStepper()
    private let focusDurationLabel = NSTextField(labelWithString: "25 分钟")
    private let shortBreakStepper = NSStepper()
    private let shortBreakLabel = NSTextField(labelWithString: "5 分钟")
    private let longBreakStepper = NSStepper()
    private let longBreakLabel = NSTextField(labelWithString: "15 分钟")

    private let notificationsSwitch = NSSwitch()
    private let popupAlertSwitch = NSSwitch()
    private let soundSwitch = NSSwitch()

    private let dailyGoalStepper = NSStepper()
    private let dailyGoalLabel = NSTextField(labelWithString: "8 番茄")

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

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        addSubview(scrollView)

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        // Duration section
        let durationTitleLabel = NSTextField(labelWithString: "⏱ 时长设置")
        durationTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        durationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationTitleLabel)

        let durationBox = NSView()
        durationBox.wantsLayer = true
        durationBox.layer?.backgroundColor = NSColor.white.cgColor
        durationBox.layer?.cornerRadius = 8
        durationBox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationBox)

        let focusRow = createDurationRow(title: "专注时长", stepper: focusDurationStepper, label: focusDurationLabel)
        let shortBreakRow = createDurationRow(title: "短休息时长", stepper: shortBreakStepper, label: shortBreakLabel)
        let longBreakRow = createDurationRow(title: "长休息时长", stepper: longBreakStepper, label: longBreakLabel)

        focusDurationStepper.minValue = 1
        focusDurationStepper.maxValue = 60
        focusDurationStepper.increment = 1
        focusDurationStepper.target = self
        focusDurationStepper.action = #selector(focusDurationChanged)

        shortBreakStepper.minValue = 1
        shortBreakStepper.maxValue = 60
        shortBreakStepper.increment = 1
        shortBreakStepper.target = self
        shortBreakStepper.action = #selector(shortBreakChanged)

        longBreakStepper.minValue = 1
        longBreakStepper.maxValue = 60
        longBreakStepper.increment = 1
        longBreakStepper.target = self
        longBreakStepper.action = #selector(longBreakChanged)

        let durationStack = NSStackView(views: [focusRow, shortBreakRow, longBreakRow])
        durationStack.orientation = .vertical
        durationStack.spacing = 12
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        durationBox.addSubview(durationStack)

        // Notification section
        let notificationTitleLabel = NSTextField(labelWithString: "🔔 提醒设置")
        notificationTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        notificationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notificationTitleLabel)

        let notificationBox = NSView()
        notificationBox.wantsLayer = true
        notificationBox.layer?.backgroundColor = NSColor.white.cgColor
        notificationBox.layer?.cornerRadius = 8
        notificationBox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notificationBox)

        let notificationStack = NSStackView()
        notificationStack.orientation = .vertical
        notificationStack.spacing = 12
        notificationStack.translatesAutoresizingMaskIntoConstraints = false

        let notificationsRow = createSwitchRow(title: "系统通知", switchControl: notificationsSwitch)
        let popupRow = createSwitchRow(title: "弹窗提醒", switchControl: popupAlertSwitch)
        let soundRow = createSwitchRow(title: "提示音", switchControl: soundSwitch)

        notificationsSwitch.target = self
        notificationsSwitch.action = #selector(notificationsSwitchChanged)

        popupAlertSwitch.target = self
        popupAlertSwitch.action = #selector(popupAlertChanged)

        soundSwitch.target = self
        soundSwitch.action = #selector(soundChanged)

        notificationStack.addArrangedSubview(notificationsRow)
        notificationStack.addArrangedSubview(popupRow)
        notificationStack.addArrangedSubview(soundRow)
        notificationBox.addSubview(notificationStack)

        // Goal section
        let goalTitleLabel = NSTextField(labelWithString: "🎯 目标设置")
        goalTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        goalTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(goalTitleLabel)

        let goalBox = NSView()
        goalBox.wantsLayer = true
        goalBox.layer?.backgroundColor = NSColor.white.cgColor
        goalBox.layer?.cornerRadius = 8
        goalBox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(goalBox)

        let goalRow = createGoalRow(stepper: dailyGoalStepper, label: dailyGoalLabel)
        dailyGoalStepper.minValue = 1
        dailyGoalStepper.maxValue = 20
        dailyGoalStepper.increment = 1
        dailyGoalStepper.target = self
        dailyGoalStepper.action = #selector(dailyGoalChanged)
        goalBox.addSubview(goalRow)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            durationTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            durationTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            durationBox.topAnchor.constraint(equalTo: durationTitleLabel.bottomAnchor, constant: 8),
            durationBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            durationBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            durationStack.topAnchor.constraint(equalTo: durationBox.topAnchor, constant: 12),
            durationStack.leadingAnchor.constraint(equalTo: durationBox.leadingAnchor, constant: 16),
            durationStack.trailingAnchor.constraint(equalTo: durationBox.trailingAnchor, constant: -16),
            durationStack.bottomAnchor.constraint(equalTo: durationBox.bottomAnchor, constant: -12),

            notificationTitleLabel.topAnchor.constraint(equalTo: durationBox.bottomAnchor, constant: 20),
            notificationTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            notificationBox.topAnchor.constraint(equalTo: notificationTitleLabel.bottomAnchor, constant: 8),
            notificationBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notificationBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            notificationStack.topAnchor.constraint(equalTo: notificationBox.topAnchor, constant: 12),
            notificationStack.leadingAnchor.constraint(equalTo: notificationBox.leadingAnchor, constant: 16),
            notificationStack.trailingAnchor.constraint(equalTo: notificationBox.trailingAnchor, constant: -16),
            notificationStack.bottomAnchor.constraint(equalTo: notificationBox.bottomAnchor, constant: -12),

            goalTitleLabel.topAnchor.constraint(equalTo: notificationBox.bottomAnchor, constant: 20),
            goalTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            goalBox.topAnchor.constraint(equalTo: goalTitleLabel.bottomAnchor, constant: 8),
            goalBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            goalBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            goalBox.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            goalRow.topAnchor.constraint(equalTo: goalBox.topAnchor, constant: 12),
            goalRow.leadingAnchor.constraint(equalTo: goalBox.leadingAnchor, constant: 16),
            goalRow.trailingAnchor.constraint(equalTo: goalBox.trailingAnchor, constant: -16),
            goalRow.bottomAnchor.constraint(equalTo: goalBox.bottomAnchor, constant: -12),
        ])
    }

    private func createDurationRow(title: String, stepper: NSStepper, label: NSTextField) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        stepper.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stepper)

        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 60),

            stepper.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
            stepper.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 24),
        ])

        return container
    }

    private func createSwitchRow(title: String, switchControl: NSSwitch) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        switchControl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(switchControl)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            switchControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            switchControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 24),
        ])

        return container
    }

    private func createGoalRow(stepper: NSStepper, label: NSTextField) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "每日目标")
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        stepper.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stepper)

        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 60),

            stepper.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
            stepper.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 24),
        ])

        return container
    }

    func loadData() {
        focusDurationStepper.integerValue = settings.focusDuration
        focusDurationLabel.stringValue = "\(settings.focusDuration) 分钟"

        shortBreakStepper.integerValue = settings.shortBreakDuration
        shortBreakLabel.stringValue = "\(settings.shortBreakDuration) 分钟"

        longBreakStepper.integerValue = settings.longBreakDuration
        longBreakLabel.stringValue = "\(settings.longBreakDuration) 分钟"

        notificationsSwitch.state = settings.notificationsEnabled ? .on : .off
        popupAlertSwitch.state = settings.popupAlertEnabled ? .on : .off
        soundSwitch.state = settings.soundEnabled ? .on : .off

        dailyGoalStepper.integerValue = settings.dailyGoal
        dailyGoalLabel.stringValue = "\(settings.dailyGoal) 番茄"
    }

    @objc private func focusDurationChanged() {
        let value = focusDurationStepper.integerValue
        settings.focusDuration = value
        focusDurationLabel.stringValue = "\(value) 分钟"
    }

    @objc private func shortBreakChanged() {
        let value = shortBreakStepper.integerValue
        settings.shortBreakDuration = value
        shortBreakLabel.stringValue = "\(value) 分钟"
    }

    @objc private func longBreakChanged() {
        let value = longBreakStepper.integerValue
        settings.longBreakDuration = value
        longBreakLabel.stringValue = "\(value) 分钟"
    }

    @objc private func notificationsSwitchChanged() {
        settings.notificationsEnabled = notificationsSwitch.state == .on
    }

    @objc private func popupAlertChanged() {
        settings.popupAlertEnabled = popupAlertSwitch.state == .on
    }

    @objc private func soundChanged() {
        settings.soundEnabled = soundSwitch.state == .on
    }

    @objc private func dailyGoalChanged() {
        let value = dailyGoalStepper.integerValue
        settings.dailyGoal = value
        dailyGoalLabel.stringValue = "\(value) 番茄"
    }
}
