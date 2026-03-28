import Foundation
import SQLite

final class DatabaseManager {
    private var db: Connection?

    private let pomodoros = Table("pomodoros")
    private let id = Expression<Int64>("id")
    private let date = Expression<String>("date")
    private let completedPomodoros = Expression<Int>("completed_pomodoros")
    private let totalFocusMinutes = Expression<Int>("total_focus_minutes")
    private let totalBreakMinutes = Expression<Int>("total_break_minutes")

    init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("pomodoro.db").path
            db = try Connection(path)
            try db?.run(pomodoros.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(date, unique: true)
                t.column(completedPomodoros, defaultValue: 0)
                t.column(totalFocusMinutes, defaultValue: 0)
                t.column(totalBreakMinutes, defaultValue: 0)
            })
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func savePomodoroCompleted(minutes: Int) {
        saveRecord(pomodorosCompleted: 1, focusMinutes: minutes, breakMinutes: 0)
    }

    func saveBreakCompleted(minutes: Int) {
        saveRecord(pomodorosCompleted: 0, focusMinutes: 0, breakMinutes: minutes)
    }

    private func saveRecord(pomodorosCompleted: Int, focusMinutes: Int, breakMinutes: Int) {
        let today = todayDateString()
        do {
            if let existing = try db?.pluck(pomodoros.filter(date == today)) {
                try db?.run(pomodoros.filter(date == today).update(
                    completedPomodoros += pomodorosCompleted,
                    totalFocusMinutes += focusMinutes,
                    totalBreakMinutes += breakMinutes
                ))
            } else {
                try db?.run(pomodoros.insert(
                    date <- today,
                    completedPomodoros <- pomodorosCompleted,
                    totalFocusMinutes <- focusMinutes,
                    totalBreakMinutes <- breakMinutes
                ))
            }
        } catch {
            print("Save failed: \(error)")
        }
    }

    func fetchTodayRecord() -> PomodoroRecord? {
        let today = todayDateString()
        do {
            if let row = try db?.pluck(pomodoros.filter(date == today)) {
                return PomodoroRecord(
                    date: Date(),
                    completedPomodoros: row[completedPomodoros],
                    totalFocusMinutes: row[totalFocusMinutes],
                    totalBreakMinutes: row[totalBreakMinutes]
                )
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        return nil
    }

    func fetchWeekRecords() -> [PomodoroRecord] {
        var records: [PomodoroRecord] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let dateString = formatter.string(from: date)
            do {
                if let row = try db?.pluck(pomodoros.filter(date == dateString)) {
                    records.append(PomodoroRecord(
                        date: date,
                        completedPomodoros: row[completedPomodoros],
                        totalFocusMinutes: row[totalFocusMinutes],
                        totalBreakMinutes: row[totalBreakMinutes]
                    ))
                }
            } catch {
                print("Fetch week failed: \(error)")
            }
        }
        return records
    }

    func clearAllRecords() {
        do {
            try db?.run(pomodoros.delete())
        } catch {
            print("Clear failed: \(error)")
        }
    }
}
