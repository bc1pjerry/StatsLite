import Foundation

enum StatsFormatter {
    static func primaryInteger(cpuUsage: Double) -> Int {
        Int(cpuUsage.rounded()).clamped(to: 0...100)
    }

    static func memoryUsageInteger(usedBytes: UInt64, totalBytes: UInt64) -> Int {
        guard totalBytes > 0 else {
            return 0
        }

        let percent = Double(usedBytes) / Double(totalBytes) * 100
        return Int(percent.rounded()).clamped(to: 0...100)
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
