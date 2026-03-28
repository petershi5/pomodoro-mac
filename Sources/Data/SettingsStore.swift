import Foundation

final class SettingsStore {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let focusDuration = "focusDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let dailyGoal = "dailyGoal"
        static let notificationsEnabled = "notificationsEnabled"
        static let popupAlertEnabled = "popupAlertEnabled"
        static let soundEnabled = "soundEnabled"
    }

    var focusDuration: Int {
        get { defaults.integer(forKey: Keys.focusDuration).nonZeroOr(25) }
        set { defaults.set(newValue, forKey: Keys.focusDuration) }
    }

    var shortBreakDuration: Int {
        get { defaults.integer(forKey: Keys.shortBreakDuration).nonZeroOr(5) }
        set { defaults.set(newValue, forKey: Keys.shortBreakDuration) }
    }

    var longBreakDuration: Int {
        get { defaults.integer(forKey: Keys.longBreakDuration).nonZeroOr(15) }
        set { defaults.set(newValue, forKey: Keys.longBreakDuration) }
    }

    var dailyGoal: Int {
        get { defaults.integer(forKey: Keys.dailyGoal).nonZeroOr(8) }
        set { defaults.set(newValue, forKey: Keys.dailyGoal) }
    }

    var notificationsEnabled: Bool {
        get { defaults.object(forKey: Keys.notificationsEnabled) == nil ? true : defaults.bool(forKey: Keys.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    var popupAlertEnabled: Bool {
        get { defaults.bool(forKey: Keys.popupAlertEnabled) }
        set { defaults.set(newValue, forKey: Keys.popupAlertEnabled) }
    }

    var soundEnabled: Bool {
        get { defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled) }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.focusDuration)
        defaults.removeObject(forKey: Keys.shortBreakDuration)
        defaults.removeObject(forKey: Keys.longBreakDuration)
        defaults.removeObject(forKey: Keys.dailyGoal)
        defaults.removeObject(forKey: Keys.notificationsEnabled)
        defaults.removeObject(forKey: Keys.popupAlertEnabled)
        defaults.removeObject(forKey: Keys.soundEnabled)
    }
}

private extension Int {
    func nonZeroOr(_ defaultValue: Int) -> Int {
        self == 0 ? defaultValue : self
    }
}
