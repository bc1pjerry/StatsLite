# StatsLite 菜单栏应用 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个完整 Xcode macOS 菜单栏应用，用半圆形进度条在菜单栏显示 CPU 使用率整数，并在下拉菜单展示 CPU、GPU、内存详情。

**Architecture:** AppKit 负责 `NSStatusItem`、菜单和无 Dock 图标的应用生命周期；SwiftUI 负责菜单栏内的半圆进度视图；系统信息采集封装在独立 provider 中，格式化逻辑独立可测。第一版保持单一菜单栏仪表，主显示值固定为 CPU 使用率。

**Tech Stack:** macOS AppKit、SwiftUI、Metal、Mach host APIs、sysctl、XCTest、Xcode 26.3、Swift 6.2.4。

---

## 文件结构

- Create: `StatsLite.xcodeproj/project.pbxproj`  
  完整 Xcode 工程配置，包含 macOS App target 和 Unit Test target。
- Create: `StatsLite/StatsLiteApp.swift`  
  App 入口，连接 SwiftUI `App` 生命周期与 AppKit delegate。
- Create: `StatsLite/AppDelegate.swift`  
  设置 accessory activation policy，创建并持有 `MenuBarController`。
- Create: `StatsLite/MenuBarController.swift`  
  持有 `NSStatusItem`，承载 SwiftUI 半圆进度视图，刷新菜单。
- Create: `StatsLite/SemiCircleProgressView.swift`  
  绘制 B 方案半圆进度条，并只显示整数。
- Create: `StatsLite/SystemStatsProvider.swift`  
  采集 CPU、GPU 和内存信息。
- Create: `StatsLite/StatsFormatter.swift`  
  格式化整数、进度、内存和菜单文本。
- Create: `StatsLite/StatsSnapshot.swift`  
  定义系统状态快照数据结构。
- Create: `StatsLite/Info.plist`  
  配置 macOS App 基础属性和 agent 行为。
- Create: `StatsLiteTests/StatsFormatterTests.swift`  
  测试格式化逻辑和主显示值规则。
- Create: `StatsLiteTests/SemiCircleProgressViewModelTests.swift`  
  测试半圆进度数据限制逻辑。

## Task 1: 创建 Xcode 工程骨架

**Files:**
- Create: `StatsLite.xcodeproj/project.pbxproj`
- Create: `StatsLite/Info.plist`
- Create: `StatsLite/StatsLiteApp.swift`
- Create: `StatsLite/AppDelegate.swift`
- Create: `StatsLiteTests/StatsFormatterTests.swift`

- [ ] **Step 1: 创建最小 App 和测试文件**

Create `StatsLite/StatsLiteApp.swift`:

```swift
import SwiftUI

@main
struct StatsLiteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

Create `StatsLite/AppDelegate.swift`:

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
```

Create `StatsLite/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

Create `StatsLiteTests/StatsFormatterTests.swift`:

```swift
import XCTest
@testable import StatsLite

final class StatsFormatterTests: XCTestCase {
    func testProjectLoadsTestBundle() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 2: 创建 `project.pbxproj`**

Create `StatsLite.xcodeproj/project.pbxproj` with one macOS app target named `StatsLite`, one unit test target named `StatsLiteTests`, Swift language version 6.0, deployment target macOS 14.0, and these source memberships:

```text
StatsLite target:
- StatsLite/StatsLiteApp.swift
- StatsLite/AppDelegate.swift
- StatsLite/Info.plist

StatsLiteTests target:
- StatsLiteTests/StatsFormatterTests.swift
```

Use stable UUIDs generated once during implementation. The product bundle identifier should be `com.bc1pjerry.StatsLite`.

- [ ] **Step 3: 构建验证**

Run:

```bash
xcodebuild -project StatsLite.xcodeproj -scheme StatsLite -configuration Debug build
```

Expected: build succeeds and produces `BUILD SUCCEEDED`.

- [ ] **Step 4: 测试验证**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS'
```

Expected: test succeeds and produces `TEST SUCCEEDED`.

- [ ] **Step 5: 提交**

```bash
git add StatsLite.xcodeproj StatsLite StatsLiteTests
git commit -m "feat: 创建 macOS 工程骨架"
```

## Task 2: 添加可测试的数据模型和格式化逻辑

**Files:**
- Create: `StatsLite/StatsSnapshot.swift`
- Create: `StatsLite/StatsFormatter.swift`
- Modify: `StatsLiteTests/StatsFormatterTests.swift`

- [ ] **Step 1: 写失败测试**

Replace `StatsLiteTests/StatsFormatterTests.swift` with:

```swift
import XCTest
@testable import StatsLite

final class StatsFormatterTests: XCTestCase {
    func testPrimaryIntegerRoundsAndClampsCPUUsage() {
        XCTAssertEqual(StatsFormatter.primaryInteger(cpuUsage: -5.2), 0)
        XCTAssertEqual(StatsFormatter.primaryInteger(cpuUsage: 12.4), 12)
        XCTAssertEqual(StatsFormatter.primaryInteger(cpuUsage: 12.5), 13)
        XCTAssertEqual(StatsFormatter.primaryInteger(cpuUsage: 130.0), 100)
    }

    func testProgressFractionClampsToZeroThroughOne() {
        XCTAssertEqual(StatsFormatter.progressFraction(percent: -10), 0)
        XCTAssertEqual(StatsFormatter.progressFraction(percent: 67), 0.67, accuracy: 0.0001)
        XCTAssertEqual(StatsFormatter.progressFraction(percent: 125), 1)
    }

    func testMemorySummaryUsesGigabytes() {
        let text = StatsFormatter.memorySummary(usedBytes: 8_589_934_592, totalBytes: 17_179_869_184)
        XCTAssertEqual(text, "Memory: 8.0 GB / 16.0 GB")
    }

    func testMenuLinesUseSnapshotValues() {
        let snapshot = StatsSnapshot(
            cpuUsagePercent: 67.2,
            gpuName: "Apple M3",
            usedMemoryBytes: 8_589_934_592,
            totalMemoryBytes: 17_179_869_184,
            refreshIntervalSeconds: 2
        )

        XCTAssertEqual(StatsFormatter.cpuMenuTitle(snapshot), "CPU: 67%")
        XCTAssertEqual(StatsFormatter.gpuMenuTitle(snapshot), "GPU: Apple M3")
        XCTAssertEqual(StatsFormatter.memoryMenuTitle(snapshot), "Memory: 8.0 GB / 16.0 GB")
        XCTAssertEqual(StatsFormatter.refreshMenuTitle(snapshot), "Refresh: 2s")
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS' -only-testing:StatsLiteTests/StatsFormatterTests
```

Expected: FAIL because `StatsSnapshot` and `StatsFormatter` do not exist.

- [ ] **Step 3: 实现最小模型和格式化逻辑**

Create `StatsLite/StatsSnapshot.swift`:

```swift
import Foundation

struct StatsSnapshot: Equatable {
    let cpuUsagePercent: Double
    let gpuName: String
    let usedMemoryBytes: UInt64
    let totalMemoryBytes: UInt64
    let refreshIntervalSeconds: Int
}
```

Create `StatsLite/StatsFormatter.swift`:

```swift
import Foundation

enum StatsFormatter {
    static func primaryInteger(cpuUsage: Double) -> Int {
        Int(cpuUsage.rounded()).clamped(to: 0...100)
    }

    static func progressFraction(percent: Int) -> Double {
        Double(percent).clamped(to: 0...100) / 100
    }

    static func memorySummary(usedBytes: UInt64, totalBytes: UInt64) -> String {
        "Memory: \(gigabytesString(usedBytes)) / \(gigabytesString(totalBytes))"
    }

    static func cpuMenuTitle(_ snapshot: StatsSnapshot) -> String {
        "CPU: \(primaryInteger(cpuUsage: snapshot.cpuUsagePercent))%"
    }

    static func gpuMenuTitle(_ snapshot: StatsSnapshot) -> String {
        "GPU: \(snapshot.gpuName)"
    }

    static func memoryMenuTitle(_ snapshot: StatsSnapshot) -> String {
        memorySummary(usedBytes: snapshot.usedMemoryBytes, totalBytes: snapshot.totalMemoryBytes)
    }

    static func refreshMenuTitle(_ snapshot: StatsSnapshot) -> String {
        "Refresh: \(snapshot.refreshIntervalSeconds)s"
    }

    private static func gigabytesString(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

Update `StatsLite.xcodeproj/project.pbxproj` so `StatsLite/StatsSnapshot.swift` and `StatsLite/StatsFormatter.swift` are included in the app target.

- [ ] **Step 4: 运行测试确认通过**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS' -only-testing:StatsLiteTests/StatsFormatterTests
```

Expected: PASS.

- [ ] **Step 5: 提交**

```bash
git add StatsLite/StatsSnapshot.swift StatsLite/StatsFormatter.swift StatsLiteTests/StatsFormatterTests.swift StatsLite.xcodeproj/project.pbxproj
git commit -m "feat: 添加状态格式化逻辑"
```

## Task 3: 添加半圆形菜单栏进度视图

**Files:**
- Create: `StatsLite/SemiCircleProgressView.swift`
- Create: `StatsLiteTests/SemiCircleProgressViewModelTests.swift`
- Modify: `StatsLite.xcodeproj/project.pbxproj`

- [ ] **Step 1: 写失败测试**

Create `StatsLiteTests/SemiCircleProgressViewModelTests.swift`:

```swift
import XCTest
@testable import StatsLite

final class SemiCircleProgressViewModelTests: XCTestCase {
    func testViewModelClampsValueAndProgress() {
        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: -3).displayValue, 0)
        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: 67).displayValue, 67)
        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: 150).displayValue, 100)

        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: -3).progress, 0)
        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: 67).progress, 0.67, accuracy: 0.0001)
        XCTAssertEqual(SemiCircleProgressViewModel(rawValue: 150).progress, 1)
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS' -only-testing:StatsLiteTests/SemiCircleProgressViewModelTests
```

Expected: FAIL because `SemiCircleProgressViewModel` does not exist.

- [ ] **Step 3: 实现视图模型和 SwiftUI 视图**

Create `StatsLite/SemiCircleProgressView.swift`:

```swift
import SwiftUI

struct SemiCircleProgressViewModel: Equatable {
    let displayValue: Int
    let progress: Double

    init(rawValue: Int) {
        let clamped = min(max(rawValue, 0), 100)
        self.displayValue = clamped
        self.progress = Double(clamped) / 100
    }
}

struct SemiCircleProgressView: View {
    let model: SemiCircleProgressViewModel

    init(value: Int) {
        self.model = SemiCircleProgressViewModel(rawValue: value)
    }

    var body: some View {
        ZStack {
            SemiCircleShape(progress: 1)
                .stroke(Color(nsColor: .systemGray), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            SemiCircleShape(progress: model.progress)
                .stroke(Color(red: 0.12, green: 0.54, blue: 0.44), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Text("\(model.displayValue)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(y: 5)
        }
        .frame(width: 42, height: 26)
        .accessibilityLabel("CPU \(model.displayValue) percent")
    }
}

private struct SemiCircleShape: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let radius = min(rect.width / 2 - 7, rect.height - 6)
        let center = CGPoint(x: rect.midX, y: rect.maxY - 6)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + 180 * clampedProgress)

        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
```

Update `StatsLite.xcodeproj/project.pbxproj` so `StatsLite/SemiCircleProgressView.swift` is included in the app target and `StatsLiteTests/SemiCircleProgressViewModelTests.swift` is included in the test target.

- [ ] **Step 4: 运行测试确认通过**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS' -only-testing:StatsLiteTests/SemiCircleProgressViewModelTests
```

Expected: PASS.

- [ ] **Step 5: 提交**

```bash
git add StatsLite/SemiCircleProgressView.swift StatsLiteTests/SemiCircleProgressViewModelTests.swift StatsLite.xcodeproj/project.pbxproj
git commit -m "feat: 添加半圆进度视图"
```

## Task 4: 实现系统信息采集

**Files:**
- Create: `StatsLite/SystemStatsProvider.swift`
- Modify: `StatsLite.xcodeproj/project.pbxproj`

- [ ] **Step 1: 创建采集接口和实现**

Create `StatsLite/SystemStatsProvider.swift`:

```swift
import Foundation
import MachO
import Metal

final class SystemStatsProvider {
    private var previousCPUInfo: processor_info_array_t?
    private var previousCPUInfoCount: mach_msg_type_number_t = 0
    private let refreshIntervalSeconds: Int
    private let gpuName: String

    init(refreshIntervalSeconds: Int = 2) {
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.gpuName = MTLCreateSystemDefaultDevice()?.name ?? "Unavailable"
    }

    deinit {
        if let previousCPUInfo {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), vm_size_t(previousCPUInfoCount))
        }
    }

    func snapshot() -> StatsSnapshot {
        StatsSnapshot(
            cpuUsagePercent: cpuUsagePercent(),
            gpuName: gpuName,
            usedMemoryBytes: usedMemoryBytes(),
            totalMemoryBytes: totalMemoryBytes(),
            refreshIntervalSeconds: refreshIntervalSeconds
        )
    }

    private func cpuUsagePercent() -> Double {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return 0
        }

        defer {
            if let previousCPUInfo {
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCPUInfo), vm_size_t(previousCPUInfoCount))
            }
            previousCPUInfo = cpuInfo
            previousCPUInfoCount = cpuInfoCount
        }

        guard let previousCPUInfo else {
            return 0
        }

        var totalUsage = 0.0

        for cpu in 0..<Int(processorCount) {
            let offset = CPU_STATE_MAX * cpu
            let user = Double(cpuInfo[offset + CPU_STATE_USER] - previousCPUInfo[offset + CPU_STATE_USER])
            let system = Double(cpuInfo[offset + CPU_STATE_SYSTEM] - previousCPUInfo[offset + CPU_STATE_SYSTEM])
            let nice = Double(cpuInfo[offset + CPU_STATE_NICE] - previousCPUInfo[offset + CPU_STATE_NICE])
            let idle = Double(cpuInfo[offset + CPU_STATE_IDLE] - previousCPUInfo[offset + CPU_STATE_IDLE])
            let total = user + system + nice + idle

            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }

        guard processorCount > 0 else {
            return 0
        }

        return min(max((totalUsage / Double(processorCount)) * 100, 0), 100)
    }

    private func usedMemoryBytes() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        return active + inactive + wired + compressed
    }

    private func totalMemoryBytes() -> UInt64 {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &value, &size, nil, 0)
        return value
    }
}
```

Update `StatsLite.xcodeproj/project.pbxproj` so `StatsLite/SystemStatsProvider.swift` is included in the app target and the app links Metal.

- [ ] **Step 2: 构建验证**

Run:

```bash
xcodebuild -project StatsLite.xcodeproj -scheme StatsLite -configuration Debug build
```

Expected: build succeeds. If Swift import or Mach API types fail, fix the imports/types and rerun until `BUILD SUCCEEDED`.

- [ ] **Step 3: 提交**

```bash
git add StatsLite/SystemStatsProvider.swift StatsLite.xcodeproj/project.pbxproj
git commit -m "feat: 添加系统信息采集"
```

## Task 5: 接入菜单栏控制器

**Files:**
- Create: `StatsLite/MenuBarController.swift`
- Modify: `StatsLite/AppDelegate.swift`
- Modify: `StatsLite.xcodeproj/project.pbxproj`

- [ ] **Step 1: 创建菜单栏控制器**

Create `StatsLite/MenuBarController.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let provider: SystemStatsProvider
    private var timer: Timer?
    private var latestSnapshot: StatsSnapshot

    init(provider: SystemStatsProvider = SystemStatsProvider()) {
        self.provider = provider
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.latestSnapshot = provider.snapshot()

        configureStatusItem()
        refresh()
        startTimer()
    }

    deinit {
        timer?.invalidate()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func configureStatusItem() {
        statusItem.length = 46
        statusItem.menu = makeMenu()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        latestSnapshot = provider.snapshot()
        let value = StatsFormatter.primaryInteger(cpuUsage: latestSnapshot.cpuUsagePercent)
        let view = SemiCircleProgressView(value: value)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 42, height: 26)
        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        statusItem.button?.addSubview(hostingView)
        statusItem.button?.frame = hostingView.frame
        statusItem.button?.toolTip = StatsFormatter.cpuMenuTitle(latestSnapshot)
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: StatsFormatter.cpuMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.gpuMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.memoryMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.refreshMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
}
```

- [ ] **Step 2: 接入 AppDelegate**

Replace `StatsLite/AppDelegate.swift` with:

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()
    }
}
```

Update `StatsLite.xcodeproj/project.pbxproj` so `StatsLite/MenuBarController.swift` is included in the app target.

- [ ] **Step 3: 构建验证**

Run:

```bash
xcodebuild -project StatsLite.xcodeproj -scheme StatsLite -configuration Debug build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: 提交**

```bash
git add StatsLite/MenuBarController.swift StatsLite/AppDelegate.swift StatsLite.xcodeproj/project.pbxproj
git commit -m "feat: 接入菜单栏展示"
```

## Task 6: 完整验证和推送

**Files:**
- Modify only files needed for final build fixes.

- [ ] **Step 1: 运行完整测试**

Run:

```bash
xcodebuild test -project StatsLite.xcodeproj -scheme StatsLite -destination 'platform=macOS'
```

Expected: `TEST SUCCEEDED`.

- [ ] **Step 2: 运行完整构建**

Run:

```bash
xcodebuild -project StatsLite.xcodeproj -scheme StatsLite -configuration Debug build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: 检查工作区**

Run:

```bash
git status --short
```

Expected: clean working tree. If there are final fixes, commit them with a minimal Chinese commit message.

- [ ] **Step 4: 推送前先 pull 并 merge**

Run:

```bash
git pull --no-rebase origin main
```

Expected: either `Already up to date.` or a clean merge. If a merge conflict appears, resolve conflicts, run full tests again, then commit the merge.

- [ ] **Step 5: 推送到 remote**

Run:

```bash
git push origin main
```

Expected: local `main` is pushed to `https://github.com/bc1pjerry/StatsLite.git`.

## 自检

- 设计文档中的工程形态、菜单栏半圆进度条、CPU/GPU/内存采集、下拉菜单、测试和验证要求都有对应任务。
- 推送流程已明确包含 `git pull --no-rebase origin main`，并要求处理 merge 后再 `git push origin main`。
- 第一版不包含设置窗口、登录项、历史曲线、多指标仪表或用户自定义主指标。
- 计划没有保留未完成标记或占位任务。
