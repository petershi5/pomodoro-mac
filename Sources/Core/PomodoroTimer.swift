import Foundation

enum PomodoroState {
    case idle
    case focusing
    case shortBreak
    case longBreak
    case paused
}

final class PomodoroTimer {
    private var timer: Timer?
    private var remaining: Int = 0
    private var pausedState: PomodoroState = .idle

    private let settings = SettingsStore()
    private let db = DatabaseManager()

    var state: PomodoroState = .idle
    var currentPomodoroCount: Int = 0

    var onTick: ((Int) -> Void)?
    var onStateChanged: ((PomodoroState) -> Void)?
    var onPomodoroCompleted: (() -> Void)?

    var remainingSeconds: Int {
        remaining > 0 ? remaining : durationFor(state: state)
    }

    var progress: Double {
        let total = Double(durationFor(state: state))
        let current = Double(remainingSeconds)
        return total > 0 ? (total - current) / total : 0
    }

    init() {
        remaining = durationFor(state: .idle)
    }

    func start() {
        guard state == .idle || state == .paused else { return }
        state = pausedState == .idle ? .focusing : pausedState
        remaining = durationFor(state: state)
        startTimer()
    }

    func pause() {
        guard state == .focusing || state == .shortBreak || state == .longBreak else { return }
        pausedState = state
        state = .paused
        timer?.invalidate()
        timer = nil
        onStateChanged?(.paused)
    }

    func resume() {
        guard state == .paused else { return }
        state = pausedState
        startTimer()
        onStateChanged?(state)
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        remaining = durationFor(state: .idle)
        onStateChanged?(.idle)
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        transitionToNextState()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func tick() {
        if remaining > 0 {
            remaining -= 1
            onTick?(remaining)
        } else {
            timer?.invalidate()
            timer = nil
            handleCompletion()
        }
    }

    private func handleCompletion() {
        switch state {
        case .focusing:
            currentPomodoroCount += 1
            db.savePomodoroCompleted(minutes: settings.focusDuration)
            onPomodoroCompleted?()
            transitionToNextState()
        case .shortBreak, .longBreak:
            db.saveBreakCompleted(minutes: state == .shortBreak ? settings.shortBreakDuration : settings.longBreakDuration)
            transitionToNextState()
        default:
            break
        }
    }

    private func transitionToNextState() {
        switch state {
        case .focusing:
            state = currentPomodoroCount % 4 == 0 ? .longBreak : .shortBreak
            remaining = durationFor(state: state)
        case .shortBreak, .longBreak:
            state = .idle
            remaining = durationFor(state: .idle)
        case .paused:
            state = pausedState
            remaining = durationFor(state: state)
        case .idle:
            state = .focusing
            remaining = durationFor(state: state)
        }
        onStateChanged?(state)
        if state == .focusing || state == .shortBreak || state == .longBreak {
            startTimer()
        }
    }

    private func durationFor(state: PomodoroState) -> Int {
        switch state {
        case .idle, .focusing: return settings.focusDuration * 60
        case .shortBreak: return settings.shortBreakDuration * 60
        case .longBreak: return settings.longBreakDuration * 60
        case .paused: return remaining
        }
    }
}
