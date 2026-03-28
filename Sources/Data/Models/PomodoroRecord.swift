import Foundation

struct PomodoroRecord: Codable {
    let date: Date
    var completedPomodoros: Int
    var totalFocusMinutes: Int
    var totalBreakMinutes: Int

    var focusHours: Double {
        Double(totalFocusMinutes) / 60.0
    }
}
