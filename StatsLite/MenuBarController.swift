import AppKit
import Combine
import SwiftUI

enum MenuBarItemLayout {
    static let horizontalPadding: CGFloat = 1
    static let itemSpacing: CGFloat = 4

    static var contentSize: CGSize {
        contentSize(for: .cpuAndMemory)
    }

    static func metricCount(for layout: MetricLayout) -> CGFloat {
        switch layout {
        case .cpuAndMemory:
            return 2
        case .cpuOnly, .memoryOnly:
            return 1
        }
    }

    static func contentSize(for layout: MetricLayout) -> CGSize {
        let count = metricCount(for: layout)
        return CGSize(
            width: SemiCircleProgressLayout.viewSize.width * count + itemSpacing * max(count - 1, 0),
            height: SemiCircleProgressLayout.viewSize.height
        )
    }

    static var statusItemLength: CGFloat {
        statusItemLength(for: .cpuAndMemory)
    }

    static func statusItemLength(for layout: MetricLayout) -> CGFloat {
        contentSize(for: layout).width + horizontalPadding * 2
    }

    static func contentFrame(in containerBounds: CGRect) -> NSRect {
        contentFrame(in: containerBounds, layout: .cpuAndMemory)
    }

    static func contentFrame(in containerBounds: CGRect, layout: MetricLayout) -> NSRect {
        let contentSize = contentSize(for: layout)
        return NSRect(
            x: (containerBounds.width - contentSize.width) / 2,
            y: (containerBounds.height - contentSize.height) / 2,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let provider: SystemStatsProvider
    private let settings: AppSettings
    private let statsState: StatsState
    private var timer: Timer?
    private var latestSnapshot: StatsSnapshot
    private var hostingView: NSHostingView<MenuBarStatsView>?
    private var cancellables = Set<AnyCancellable>()

    init(provider: SystemStatsProvider = SystemStatsProvider(), settings: AppSettings = AppSettings(), statsState: StatsState = StatsState()) {
        self.provider = provider
        self.settings = settings
        self.statsState = statsState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.latestSnapshot = provider.snapshot(refreshIntervalSeconds: settings.refreshInterval.seconds)
        self.statsState.snapshot = latestSnapshot

        configureStatusItem()
        observeSettings()
        refresh()
        startTimer()
    }

    private func configureStatusItem() {
        statusItem.length = MenuBarItemLayout.statusItemLength(for: settings.metricLayout)
        statusItem.menu = makeMenu()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval.timeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func observeSettings() {
        settings.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.startTimer()
                    self?.refresh()
                }
            }
            .store(in: &cancellables)

        settings.$accentColorPreset
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
            .store(in: &cancellables)

        settings.$metricLayout
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        latestSnapshot = provider.snapshot(refreshIntervalSeconds: settings.refreshInterval.seconds)
        statsState.snapshot = latestSnapshot
        let cpuValue = StatsFormatter.primaryInteger(cpuUsage: latestSnapshot.cpuUsagePercent)
        let memoryValue = StatsFormatter.memoryUsageInteger(
            usedBytes: latestSnapshot.usedMemoryBytes,
            totalBytes: latestSnapshot.totalMemoryBytes
        )
        updateStatusButton(cpuValue: cpuValue, memoryValue: memoryValue)
        statusItem.length = MenuBarItemLayout.statusItemLength(for: settings.metricLayout)
        statusItem.button?.toolTip = "\(StatsFormatter.cpuMenuTitle(latestSnapshot)) | Memory: \(memoryValue)%"
        statusItem.menu = makeMenu()
    }

    private func updateStatusButton(cpuValue: Int, memoryValue: Int) {
        let view = MenuBarStatsView(
            cpuValue: cpuValue,
            memoryValue: memoryValue,
            metricLayout: settings.metricLayout,
            accentColor: settings.accentColorPreset.color
        )

        if let hostingView {
            hostingView.rootView = view
            if let button = statusItem.button {
                hostingView.frame = MenuBarItemLayout.contentFrame(in: button.bounds, layout: settings.metricLayout)
            }
            return
        }

        guard let button = statusItem.button else {
            return
        }

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = MenuBarItemLayout.contentFrame(in: button.bounds, layout: settings.metricLayout)
        hostingView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        self.hostingView = hostingView

        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(hostingView)
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: StatsFormatter.cpuMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.gpuMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.memoryMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: StatsFormatter.refreshMenuTitle(latestSnapshot), action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
