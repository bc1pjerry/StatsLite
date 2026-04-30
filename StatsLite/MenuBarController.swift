import AppKit
import SwiftUI

enum MenuBarItemLayout {
    static let horizontalPadding: CGFloat = 1
    static let itemSpacing: CGFloat = 4

    static var contentSize: CGSize {
        CGSize(
            width: SemiCircleProgressLayout.viewSize.width * 2 + itemSpacing,
            height: SemiCircleProgressLayout.viewSize.height
        )
    }

    static var statusItemLength: CGFloat {
        contentSize.width + horizontalPadding * 2
    }

    static func contentFrame(in containerBounds: CGRect) -> NSRect {
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
    private var timer: Timer?
    private var latestSnapshot: StatsSnapshot
    private var hostingView: NSHostingView<MenuBarStatsView>?

    init(provider: SystemStatsProvider = SystemStatsProvider()) {
        self.provider = provider
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.latestSnapshot = provider.snapshot()

        configureStatusItem()
        refresh()
        startTimer()
    }

    private func configureStatusItem() {
        statusItem.length = MenuBarItemLayout.statusItemLength
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
        let cpuValue = StatsFormatter.primaryInteger(cpuUsage: latestSnapshot.cpuUsagePercent)
        let memoryValue = StatsFormatter.memoryUsageInteger(
            usedBytes: latestSnapshot.usedMemoryBytes,
            totalBytes: latestSnapshot.totalMemoryBytes
        )
        updateStatusButton(cpuValue: cpuValue, memoryValue: memoryValue)
        statusItem.button?.toolTip = "\(StatsFormatter.cpuMenuTitle(latestSnapshot)) | Memory: \(memoryValue)%"
        statusItem.menu = makeMenu()
    }

    private func updateStatusButton(cpuValue: Int, memoryValue: Int) {
        let view = MenuBarStatsView(cpuValue: cpuValue, memoryValue: memoryValue)

        if let hostingView {
            hostingView.rootView = view
            if let button = statusItem.button {
                hostingView.frame = MenuBarItemLayout.contentFrame(in: button.bounds)
            }
            return
        }

        guard let button = statusItem.button else {
            return
        }

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = MenuBarItemLayout.contentFrame(in: button.bounds)
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
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
}
