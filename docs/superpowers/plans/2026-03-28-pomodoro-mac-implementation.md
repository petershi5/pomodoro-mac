# Pomodoro-Mac Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar Pomodoro timer app with statistics tracking and customizable reminders.

**Architecture:** Menu bar app using NSStatusItem + NSPopover. Core timer logic isolated in PomodoroTimer. Data layer split: UserDefaults for settings, SQLite.swift for statistics. UI built with AppKit views, warm tomato-themed design.

**Tech Stack:** Swift, AppKit, SQLite.swift, XcodeGen

---

## File Structure

```
PomodoroMac/
├── Sources/
│   ├── App/
│   │   ├── main.swift                    # Manual NSApplication startup
│   │   └── AppDelegate.swift             # App lifecycle, status item setup
│   ├── UI/
│   │   ├── StatusBarController.swift      # NSStatusItem + NSPopover management
│   │   ├── TimerViewController.swift      # Main popover content + tab management
│   │   ├── TimerView.swift               # Timer display with circular progress
│   │   ├── StatisticsView.swift          # Stats panel with charts
│   │   └── SettingsView.swift           # Settings panel
│   ├── Core/
│   │   ├── PomodoroTimer.swift           # Timer state machine + logic
│   │   ├── NotificationManager.swift     # UNUserNotificationCenter wrapper
│   │   └── SoundManager.swift           # NSSound playback
│   ├── Data/
│   │   ├── DatabaseManager.swift         # SQLite.swift wrapper
│   │   ├── SettingsStore.swift          # UserDefaults wrapper
│   │   └── Models/
│   │       └── PomodoroRecord.swift     # Daily stats model
│   └── Resources/
│       └── Assets.xcassets/              # App icon + menu bar icons
├── project.yml                           # XcodeGen configuration
├── Podfile                               # CocoaPods (SQLite.swift)
└── SPEC.md                               # Copied from design doc
```

---

## Task 1: Project Scaffolding

**Files:**
- Create: `project.yml`
- Create: `Podfile`
- Create: `Sources/App/main.swift`
- Create: `Sources/App/AppDelegate.swift`
- Create: `Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Create project.yml for XcodeGen**

```yaml
name: PomodoroMac
options:
  bundleIdPrefix: com.pomodoro
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"

targets:
  PomodoroMac:
    type: application
    platform: macOS
    sources:
      - path: Sources
        type: group
    resources:
      - path: Resources
        type: group
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.pomodoro.mac
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        INFOPLIST_FILE: Sources/App/Info.plist
        CODE_SIGN_STYLE: Automatic
        COMBINE_HIDPI_IMAGES: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
        SWIFT_VERSION: "5.9"
```

- [ ] **Step 2: Create Podfile**

```ruby
platform :osx, '13.0'
use_frameworks!

target 'PomodoroMac' do
  pod 'SQLite.swift', '~> 0.15.0'
end
```

- [ ] **Step 3: Create minimal main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 4: Create AppDelegate with stub**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
```

- [ ] **Step 5: Create Assets.xcassets structure**

Create `Resources/Assets.xcassets/Contents.json`:
```json
{"info":{"version":1,"author":"xcode"}}
```

Create `Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{"images":[{"idiom":"mac","scale":"1x","size":"16x16"},{"idiom":"mac","scale":"2x","size":"16x16"},{"idiom":"mac","scale":"1x","size":"32x32"},{"idiom":"mac","scale":"2x","size":"32x32"},{"idiom":"mac","scale":"1x","size":"128x128"},{"idiom":"mac","scale":"2x","size":"128x128"},{"idiom":"mac","scale":"1x","size":"256x256"},{"idiom":"mac","scale":"2x","size":"256x256"},{"idiom":"mac","scale":"1x","size":"512x512"},{"idiom":"mac","scale":"2x","size":"512x512"}],"info":{"version":1,"author":"xcode"}}
```

- [ ] **Step 6: Generate project and install pods**

Run: `xcodegen generate && pod install`

- [ ] **Step 7: Verify empty shell builds**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "chore: project scaffolding with XcodeGen and CocoaPods

- Add project.yml for XcodeGen
- Add Podfile with SQLite.swift
- Add minimal main.swift + AppDelegate
- Add Assets.xcassets structure"
```

---

## Task 2: Settings Store (UserDefaults)

**Files:**
- Create: `Sources/Data/SettingsStore.swift`
- Create: `Sources/Data/Models/PomodoroRecord.swift`

- [ ] **Step 1: Write SettingsStore test**

```swift
import XCTest
@testable import PomodoroMac

final class SettingsStoreTests: XCTestCase {
    var store: SettingsStore!

    override func setUp() {
        store = SettingsStore()
    }

    override func tearDown() {
        store.resetToDefaults()
    }

    func testDefaultValues() {
        XCTAssertEqual(store.focusDuration, 25)
        XCTAssertEqual(store.shortBreakDuration, 5)
        XCTAssertEqual(store.longBreakDuration, 15)
        XCTAssertEqual(store.dailyGoal, 8)
        XCTAssertTrue(store.notificationsEnabled)
        XCTAssertFalse(store.popupAlertEnabled)
        XCTAssertTrue(store.soundEnabled)
    }

    func testCustomValuesPersist() {
        store.focusDuration = 30
        XCTAssertEqual(store.focusDuration, 30)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/SettingsStoreTests 2>&1 | grep -E "(FAILED|PASSED|error:)"`

Expected: FAIL with "Cannot find 'SettingsStore'"

- [ ] **Step 3: Write PomodoroRecord model**

```swift
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
```

- [ ] **Step 4: Write SettingsStore**

```swift
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
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    var popupAlertEnabled: Bool {
        get { defaults.bool(forKey: Keys.popupAlertEnabled) }
        set { defaults.set(newValue, forKey: Keys.popupAlertEnabled) }
    }

    var soundEnabled: Bool {
        get { defaults.bool(forKey: Keys.soundEnabled) }
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
```

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/SettingsStoreTests 2>&1 | grep -E "(FAILED|PASSED)"`

Expected: PASSED

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: add SettingsStore with UserDefaults persistence"
```

---

## Task 3: Database Manager (SQLite.swift)

**Files:**
- Create: `Sources/Data/DatabaseManager.swift`

- [ ] **Step 1: Write DatabaseManager test**

```swift
import XCTest
@testable import PomodoroMac

final class DatabaseManagerTests: XCTestCase {
    var db: DatabaseManager!

    override func setUp() {
        db = DatabaseManager()
        db.clearAllRecords()
    }

    override func tearDown() {
        db.clearAllRecords()
    }

    func testSaveAndFetchTodayRecord() {
        db.savePomodoroCompleted(minutes: 25)
        db.saveBreakCompleted(minutes: 5)

        let record = db.fetchTodayRecord()
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.completedPomodoros, 1)
        XCTAssertEqual(record?.totalFocusMinutes, 25)
        XCTAssertEqual(record?.totalBreakMinutes, 5)
    }

    func testMultiplePomodorosIncrement() {
        db.savePomodoroCompleted(minutes: 25)
        db.savePomodoroCompleted(minutes: 25)

        let record = db.fetchTodayRecord()
        XCTAssertEqual(record?.completedPomodoros, 2)
        XCTAssertEqual(record?.totalFocusMinutes, 50)
    }

    func testFetchWeekRecords() {
        let records = db.fetchWeekRecords()
        XCTAssertLessThanOrEqual(records.count, 7)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/DatabaseManagerTests 2>&1 | grep -E "(FAILED|PASSED|error:)"`

Expected: FAIL with "Cannot find 'DatabaseManager'"

- [ ] **Step 3: Write DatabaseManager**

```swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/DatabaseManagerTests 2>&1 | grep -E "(FAILED|PASSED)"`

Expected: PASSED

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add DatabaseManager with SQLite.swift persistence"
```

---

## Task 4: PomodoroTimer Core Logic

**Files:**
- Create: `Sources/Core/PomodoroTimer.swift`

- [ ] **Step 1: Write PomodoroTimer test**

```swift
import XCTest
@testable import PomodoroMac

final class PomodoroTimerTests: XCTestCase {
    var timer: PomodoroTimer!
    var didUpdate = false
    var didComplete = false

    override func setUp() {
        timer = PomodoroTimer()
        timer.onTick = { [weak self] _ in self?.didUpdate = true }
        timer.onStateChanged = { _ in }
        timer.onPomodoroCompleted = { self.didComplete = true }
    }

    func testInitialState() {
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.remainingSeconds, 25 * 60)
        XCTAssertEqual(timer.currentPomodoroCount, 0)
    }

    func testStartTimer() {
        timer.start()
        XCTAssertEqual(timer.state, .focusing)
    }

    func testPauseResume() {
        timer.start()
        timer.pause()
        XCTAssertEqual(timer.state, .paused)
        timer.resume()
        XCTAssertEqual(timer.state, .focusing)
    }

    func testReset() {
        timer.start()
        timer.reset()
        XCTAssertEqual(timer.state, .idle)
        XCTAssertEqual(timer.remainingSeconds, 25 * 60)
    }

    func testSkipToNextState() {
        timer.start()
        timer.skip()
        XCTAssertEqual(timer.state, .shortBreak)
        XCTAssertEqual(timer.currentPomodoroCount, 1)
    }

    func testLongBreakAfterFourPomodoros() {
        for _ in 0..<4 {
            timer.start()
            timer.skip()
        }
        XCTAssertEqual(timer.state, .longBreak)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/PomodoroTimerTests 2>&1 | grep -E "(FAILED|PASSED|error:)"`

Expected: FAIL with "Cannot find 'PomodoroTimer'"

- [ ] **Step 3: Write PomodoroTimer**

```swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/PomodoroTimerTests 2>&1 | grep -E "(FAILED|PASSED)"`

Expected: PASSED

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add PomodoroTimer state machine with core logic"
```

---

## Task 5: NotificationManager & SoundManager

**Files:**
- Create: `Sources/Core/NotificationManager.swift`
- Create: `Sources/Core/SoundManager.swift`

- [ ] **Step 1: Write NotificationManager test**

```swift
import XCTest
@testable import PomodoroMac

final class NotificationManagerTests: XCTestCase {
    var manager: NotificationManager!

    override func setUp() {
        manager = NotificationManager()
    }

    func testRequestAuthorization() async {
        let granted = await manager.requestAuthorization()
        XCTAssertTrue(granted)
    }

    func testSendFocusCompleteNotification() async {
        await manager.requestAuthorization()
        await manager.sendFocusCompleteNotification(pomodorosCompleted: 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/NotificationManagerTests 2>&1 | grep -E "(FAILED|PASSED|error:)"`

Expected: FAIL with "Cannot find 'NotificationManager'"

- [ ] **Step 3: Write NotificationManager**

```swift
import Foundation
import UserNotifications

final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("Notification auth failed: \(error)")
            return false
        }
    }

    func sendFocusCompleteNotification(pomodorosCompleted: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "专注完成！"
        content.body = "已完成了 \(pomodorosCompleted) 个番茄钟，去休息一下吧"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("Notification send failed: \(error)")
        }
    }

    func sendBreakCompleteNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "休息结束！"
        content.body = "准备好开始下一个番茄钟了吗？"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            print("Notification send failed: \(error)")
        }
    }
}
```

- [ ] **Step 4: Write SoundManager**

```swift
import Foundation
import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playCompletionSound() {
        NSSound(named: .init("Glass"))?.play()
    }

    func playFocusStartSound() {
        NSSound(named: .init("Pop"))?.play()
    }

    func playBreakStartSound() {
        NSSound(named: .init("Basso"))?.play()
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug test -only-testing:PomodoroMacTests/NotificationManagerTests 2>&1 | grep -E "(FAILED|PASSED)"`

Expected: PASSED

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: add NotificationManager and SoundManager"
```

---

## Task 6: StatusBarController (Menu Bar)

**Files:**
- Create: `Sources/UI/StatusBarController.swift`

- [ ] **Step 1: Write StatusBarController**

```swift
import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    var onShowPopover: (() -> Void)?

    init() {
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.animates = true
    }

    func setPopoverContent(_ viewController: NSViewController) {
        popover.contentViewController = viewController
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        onShowPopover?()
    }

    func closePopover() {
        popover.performClose(nil)
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
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Pomodoro")
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add StatusBarController with NSStatusItem and NSPopover"
```

---

## Task 7: TimerView (UI)

**Files:**
- Create: `Sources/UI/TimerView.swift`

- [ ] **Step 1: Write TimerView**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add TimerView with circular progress ring"
```

---

## Task 8: TimerViewController (Main Popover)

**Files:**
- Create: `Sources/UI/TimerViewController.swift`

- [ ] **Step 1: Write TimerViewController**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add TimerViewController as main popover content"
```

---

## Task 9: StatisticsView & SettingsView

**Files:**
- Create: `Sources/UI/StatisticsView.swift`
- Create: `Sources/UI/SettingsView.swift`

- [ ] **Step 1: Write StatisticsView**

```swift
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
```

- [ ] **Step 2: Write SettingsView**

```swift
import AppKit

final class SettingsView: NSView {
    private let settings = SettingsStore()

    private var focusStepper: NSStepper!
    private var shortBreakStepper: NSStepper!
    private var longBreakStepper: NSStepper!
    private var goalStepper: NSStepper!

    private var focusLabel: NSTextField!
    private var shortBreakLabel: NSTextField!
    private var longBreakLabel: NSTextField!
    private var goalLabel: NSTextField!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadSettings()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0).cgColor

        var yOffset: CGFloat = 16

        // Duration section
        let durationTitle = createSectionTitle("⏱ 时长设置")
        durationTitle.frame.origin = CGPoint(x: 16, y: bounds.height - yOffset)
        addSubview(durationTitle)
        yOffset += 28

        let durationBox = NSBox()
        durationBox.boxType = .custom
        durationBox.fillColor = .white
        durationBox.cornerRadius = 8
        durationBox.frame = CGRect(x: 16, y: bounds.height - yOffset - 90, width: 288, height: 80)
        addSubview(durationBox)

        focusLabel = createValueLabel("\(settings.focusDuration) 分钟")
        shortBreakLabel = createValueLabel("\(settings.shortBreakDuration) 分钟")
        longBreakLabel = createValueLabel("\(settings.longBreakDuration) 分钟")

        focusStepper = createStepper()
        shortBreakStepper = createStepper()
        longBreakStepper = createStepper()

        durationBox.addSubview(createSettingRow(label: "专注时长", valueLabel: focusLabel, stepper: focusStepper, y: 50))
        durationBox.addSubview(createSettingRow(label: "短休息", valueLabel: shortBreakLabel, stepper: shortBreakStepper, y: 25))

        yOffset += 100

        // Notification section
        let notifTitle = createSectionTitle("🔔 提醒设置")
        notifTitle.frame.origin = CGPoint(x: 16, y: bounds.height - yOffset)
        addSubview(notifTitle)
        yOffset += 28

        let notifBox = NSBox()
        notifBox.boxType = .custom
        notifBox.fillColor = .white
        notifBox.cornerRadius = 8
        notifBox.frame = CGRect(x: 16, y: bounds.height - yOffset - 80, width: 288, height: 70)
        addSubview(notifBox)

        let notifSwitch = NSSwitch()
        notifSwitch.state = settings.notificationsEnabled ? .on : .off
        notifSwitch.target = self
        notifSwitch.action = #selector(notifSwitchChanged)
        notifBox.addSubview(createSettingRow(label: "系统通知", valueLabel: nil, stepper: notifSwitch, y: 40))

        let popupSwitch = NSSwitch()
        popupSwitch.state = settings.popupAlertEnabled ? .on : .off
        popupSwitch.target = self
        popupSwitch.action = #selector(popupSwitchChanged)
        notifBox.addSubview(createSettingRow(label: "弹窗提醒", valueLabel: nil, stepper: popupSwitch, y: 10))

        yOffset += 90

        // Goal section
        let goalTitle = createSectionTitle("🎯 目标设置")
        goalTitle.frame.origin = CGPoint(x: 16, y: bounds.height - yOffset)
        addSubview(goalTitle)
        yOffset += 28

        let goalBox = NSBox()
        goalBox.boxType = .custom
        goalBox.fillColor = .white
        goalBox.cornerRadius = 8
        goalBox.frame = CGRect(x: 16, y: bounds.height - yOffset - 40, width: 288, height: 30)
        addSubview(goalBox)

        goalLabel = createValueLabel("\(settings.dailyGoal) 个")
        goalStepper = createStepper()
        goalStepper.minValue = 1
        goalStepper.maxValue = 20
        goalBox.addSubview(createSettingRow(label: "每日番茄目标", valueLabel: goalLabel, stepper: goalStepper, y: 5))
    }

    private func createSectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        return label
    }

    private func createValueLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)
        return label
    }

    private func createStepper() -> NSStepper {
        let stepper = NSStepper()
        stepper.minValue = 1
        stepper.maxValue = 60
        stepper.increment = 5
        stepper.target = self
        stepper.action = #selector(stepperChanged)
        return stepper
    }

    private func createSettingRow(label: String, valueLabel: NSTextField?, stepper: NSView, y: CGFloat) -> NSView {
        let row = NSView()
        row.frame = CGRect(x: 12, y: y, width: 264, height: 24)

        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.frame = CGRect(x: 0, y: 0, width: 120, height: 24)
        row.addSubview(titleLabel)

        if let valueLabel = valueLabel {
            valueLabel.frame = CGRect(x: 180, y: 0, width: 60, height: 24)
            row.addSubview(valueLabel)
        }

        stepper.frame = CGRect(x: 240, y: 0, width: 24, height: 24)
        row.addSubview(stepper)

        return row
    }

    private func loadSettings() {
        focusLabel?.stringValue = "\(settings.focusDuration) 分钟"
        shortBreakLabel?.stringValue = "\(settings.shortBreakDuration) 分钟"
        longBreakLabel?.stringValue = "\(settings.longBreakDuration) 分钟"
        goalLabel?.stringValue = "\(settings.dailyGoal) 个"
    }

    @objc private func stepperChanged(_ sender: NSStepper) {
        if sender == focusStepper {
            settings.focusDuration = Int(sender.doubleValue)
            focusLabel.stringValue = "\(settings.focusDuration) 分钟"
        } else if sender == shortBreakStepper {
            settings.shortBreakDuration = Int(sender.doubleValue)
            shortBreakLabel.stringValue = "\(settings.shortBreakDuration) 分钟"
        } else if sender == longBreakStepper {
            settings.longBreakDuration = Int(sender.doubleValue)
            longBreakLabel.stringValue = "\(settings.longBreakDuration) 分钟"
        } else if sender == goalStepper {
            settings.dailyGoal = Int(sender.doubleValue)
            goalLabel.stringValue = "\(settings.dailyGoal) 个"
        }
    }

    @objc private func notifSwitchChanged(_ sender: NSSwitch) {
        settings.notificationsEnabled = sender.state == .on
    }

    @objc private func popupSwitchChanged(_ sender: NSSwitch) {
        settings.popupAlertEnabled = sender.state == .on
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add StatisticsView and SettingsView"
```

---

## Task 10: Integrate AppDelegate

**Files:**
- Modify: `Sources/App/AppDelegate.swift`

- [ ] **Step 1: Update AppDelegate to wire everything together**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var timerViewController: TimerViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        timerViewController = TimerViewController()
        statusBarController = StatusBarController()
        statusBarController.setPopoverContent(timerViewController)
        statusBarController.onShowPopover = {
            // Refresh data when popover shows
        }

        Task {
            let notificationManager = NotificationManager()
            _ = await notificationManager.requestAuthorization()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController.closePopover()
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -10`

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: wire up AppDelegate with StatusBarController and TimerViewController"
```

---

## Verification

1. **Build verification**: `xcodebuild -workspace PomodoroMac.xcworkspace -scheme PomodoroMac -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -3`
   - Expected: `BUILD SUCCEEDED`

2. **Run app**: Open `PomodoroMac.xcworkspace` in Xcode and run. Menu bar icon should appear. Click to show timer popover.

3. **Manual testing checklist**:
   - [ ] Menu bar icon appears and is clickable
   - [ ] Popover shows with timer at 25:00
   - [ ] Start button begins countdown
   - [ ] Pause button pauses timer
   - [ ] Reset button resets to 25:00
   - [ ] Tab navigation works (timer/stats/settings)
   - [ ] Statistics view loads today's data
   - [ ] Settings changes persist across app restart
