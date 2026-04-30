# StatsLite Settings Window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build a dark, dashboard-style macOS settings window that controls refresh interval, accent color, and menu bar metric selection.

**Architecture:** Add a small `AppSettings` store backed by `UserDefaults`, a shared `StatsState` object for the latest snapshot, and a SwiftUI `SettingsView`. `MenuBarController` reads settings/state, restarts its timer when preferences change, and renders one or two menu bar gauges based on the selected metric layout.

**Tech Stack:** Swift 6, SwiftUI, AppKit `NSStatusItem`, `UserDefaults`, XCTest, Xcode macOS app target.

---

### Task 1: Settings Model And Persistence

**Files:**
- Create: `StatsLite/AppSettings.swift`
- Create: `StatsLiteTests/AppSettingsTests.swift`
- Modify: `StatsLite.xcodeproj/project.pbxproj`

- [x] **Step 1: Write failing tests for defaults and invalid persisted values**

```swift
import XCTest
@testable import StatsLite

final class AppSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "StatsLite.AppSettingsTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDefaultsMatchCurrentMenuBarBehavior() {
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.refreshInterval, .twoSeconds)
        XCTAssertEqual(settings.accentColorPreset, .teal)
        XCTAssertEqual(settings.metricLayout, .cpuAndMemory)
    }

    func testInvalidPersistedValuesFallBackToDefaults() {
        defaults.set(99, forKey: AppSettings.Keys.refreshInterval)
        defaults.set("pink", forKey: AppSettings.Keys.accentColorPreset)
        defaults.set("gpuOnly", forKey: AppSettings.Keys.metricLayout)

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.refreshInterval, .twoSeconds)
        XCTAssertEqual(settings.accentColorPreset, .teal)
        XCTAssertEqual(settings.metricLayout, .cpuAndMemory)
    }

    func testSelectionsPersistToUserDefaults() {
        let settings = AppSettings(defaults: defaults)

        settings.refreshInterval = .fiveSeconds
        settings.accentColorPreset = .orange
        settings.metricLayout = .memoryOnly

        XCTAssertEqual(defaults.integer(forKey: AppSettings.Keys.refreshInterval), 5)
        XCTAssertEqual(defaults.string(forKey: AppSettings.Keys.accentColorPreset), "orange")
        XCTAssertEqual(defaults.string(forKey: AppSettings.Keys.metricLayout), "memoryOnly")
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -only-testing:StatsLiteTests/AppSettingsTests`

Expected: FAIL because `AppSettings` and related types do not exist.

- [x] **Step 3: Implement minimal settings store**

```swift
import AppKit
import SwiftUI

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case oneSecond = 1
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10

    var id: Int { rawValue }
    var label: String { "\(rawValue)s" }
    var seconds: Int { rawValue }
    var timeInterval: TimeInterval { TimeInterval(rawValue) }
}

enum AccentColorPreset: String, CaseIterable, Identifiable {
    case teal
    case blue
    case orange

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .teal:
            return Color(red: 0.12, green: 0.54, blue: 0.44)
        case .blue:
            return Color(red: 0.23, green: 0.45, blue: 0.78)
        case .orange:
            return Color(red: 0.78, green: 0.44, blue: 0.23)
        }
    }
}

enum MetricLayout: String, CaseIterable, Identifiable {
    case cpuAndMemory
    case cpuOnly
    case memoryOnly

    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    enum Keys {
        static let refreshInterval = "refreshIntervalSeconds"
        static let accentColorPreset = "accentColorPreset"
        static let metricLayout = "metricLayout"
    }

    private let defaults: UserDefaults

    @Published var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval) }
    }

    @Published var accentColorPreset: AccentColorPreset {
        didSet { defaults.set(accentColorPreset.rawValue, forKey: Keys.accentColorPreset) }
    }

    @Published var metricLayout: MetricLayout {
        didSet { defaults.set(metricLayout.rawValue, forKey: Keys.metricLayout) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refreshInterval = RefreshInterval(rawValue: defaults.integer(forKey: Keys.refreshInterval)) ?? .twoSeconds
        accentColorPreset = defaults.string(forKey: Keys.accentColorPreset).flatMap(AccentColorPreset.init(rawValue:)) ?? .teal
        metricLayout = defaults.string(forKey: Keys.metricLayout).flatMap(MetricLayout.init(rawValue:)) ?? .cpuAndMemory
    }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -only-testing:StatsLiteTests/AppSettingsTests`

Expected: PASS.

### Task 2: Menu Bar Rendering From Settings

**Files:**
- Modify: `StatsLite/SemiCircleProgressView.swift`
- Modify: `StatsLite/MenuBarController.swift`
- Modify: `StatsLite/StatsSnapshot.swift`
- Modify: `StatsLite/AppDelegate.swift`
- Modify: `StatsLiteTests/SemiCircleProgressViewModelTests.swift`

- [x] **Step 1: Write failing tests for metric layout sizing**

```swift
func testMenuBarLayoutUsesSelectedMetricCount() {
    XCTAssertEqual(MenuBarItemLayout.metricCount(for: .cpuAndMemory), 2)
    XCTAssertEqual(MenuBarItemLayout.metricCount(for: .cpuOnly), 1)
    XCTAssertEqual(MenuBarItemLayout.metricCount(for: .memoryOnly), 1)

    XCTAssertEqual(
        MenuBarItemLayout.contentSize(for: .cpuOnly).width,
        SemiCircleProgressLayout.viewSize.width
    )
    XCTAssertEqual(
        MenuBarItemLayout.contentSize(for: .cpuAndMemory).width,
        SemiCircleProgressLayout.viewSize.width * 2 + MenuBarItemLayout.itemSpacing
    )
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -only-testing:StatsLiteTests/SemiCircleProgressViewModelTests/testMenuBarLayoutUsesSelectedMetricCount`

Expected: FAIL because `MetricLayout` sizing APIs do not exist yet.

- [x] **Step 3: Update layout, snapshot interval, and controller settings wiring**

Implementation requirements:

```swift
enum MenuBarItemLayout {
    static func metricCount(for layout: MetricLayout) -> CGFloat {
        layout == .cpuAndMemory ? 2 : 1
    }

    static func contentSize(for layout: MetricLayout) -> CGSize {
        let count = metricCount(for: layout)
        return CGSize(
            width: SemiCircleProgressLayout.viewSize.width * count + itemSpacing * max(count - 1, 0),
            height: SemiCircleProgressLayout.viewSize.height
        )
    }
}
```

`MenuBarController` must take `AppSettings`, set `StatsSnapshot.refreshIntervalSeconds` from `settings.refreshInterval.seconds`, render selected gauges, pass `settings.accentColorPreset.color` into `MenuBarStatsView`, and reschedule the timer when settings change.

- [x] **Step 4: Run targeted tests**

Run: `xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -only-testing:StatsLiteTests/SemiCircleProgressViewModelTests`

Expected: PASS.

### Task 3: Dark Settings Window UI

**Files:**
- Create: `StatsLite/StatsState.swift`
- Create: `StatsLite/SettingsView.swift`
- Modify: `StatsLite/StatsLiteApp.swift`
- Modify: `StatsLite/AppDelegate.swift`
- Modify: `StatsLite/MenuBarController.swift`
- Modify: `StatsLite.xcodeproj/project.pbxproj`

- [x] **Step 1: Build shared state object**

```swift
import Foundation

@MainActor
final class StatsState: ObservableObject {
    @Published var snapshot: StatsSnapshot

    init(snapshot: StatsSnapshot = .placeholder) {
        self.snapshot = snapshot
    }
}
```

- [x] **Step 2: Add dark dashboard settings view**

Create `SettingsView` with `NavigationSplitView`, sidebar items `常规` / `外观` / `指标`, segmented refresh interval, accent swatches, metric layout picker, and metric cards driven by `StatsState.snapshot`.

- [x] **Step 3: Wire app-level shared objects**

`StatsLiteApp` owns `@StateObject private var settings = AppSettings()` and `@StateObject private var statsState = StatsState()`, injects them into `AppDelegate`, and uses `Settings { SettingsView(settings: settings, statsState: statsState) }`.

`AppDelegate` exposes `configure(settings:statsState:)`; `MenuBarController` receives both objects.

- [x] **Step 4: Add menu entry**

`MenuBarController.makeMenu()` adds `Settings...` before `Quit`, targeting `showSettings`.

```swift
@objc private func showSettings() {
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    NSApp.activate(ignoringOtherApps: true)
}
```

- [x] **Step 5: Run build**

Run: `xcodebuild build -project StatsLite.xcodeproj -scheme StatsLite`

Expected: BUILD SUCCEEDED.

### Task 4: Final Verification And Commit

**Files:**
- All changed implementation, test, and project files.

- [x] **Step 1: Run full tests**

Run: `xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite`

Expected: `** TEST SUCCEEDED **`.

- [x] **Step 2: Review diff**

Run: `git diff --stat && git diff --check`

Expected: changed files match the plan and `git diff --check` exits 0.

- [x] **Step 3: Commit implementation**

```bash
git add StatsLite StatsLiteTests StatsLite.xcodeproj docs/superpowers/plans/2026-04-30-statslite-settings-window.md
git commit -m "feat: add settings window"
```
