import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let provider: SystemStatsProvider
    private var timer: Timer?
    private var latestSnapshot: StatsSnapshot
    private var hostingView: NSHostingView<SemiCircleProgressView>?

    init(provider: SystemStatsProvider = SystemStatsProvider()) {
        self.provider = provider
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.latestSnapshot = provider.snapshot()

        configureStatusItem()
        refresh()
        startTimer()
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
        updateStatusButton(value: value)
        statusItem.button?.toolTip = StatsFormatter.cpuMenuTitle(latestSnapshot)
        statusItem.menu = makeMenu()
    }

    private func updateStatusButton(value: Int) {
        let view = SemiCircleProgressView(value: value)

        if let hostingView {
            hostingView.rootView = view
            return
        }

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 2, y: 0, width: 42, height: 26)
        hostingView.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        self.hostingView = hostingView

        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        statusItem.button?.addSubview(hostingView)
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
