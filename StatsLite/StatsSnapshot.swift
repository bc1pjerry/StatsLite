import Foundation

struct StatsSnapshot: Equatable {
    let cpuUsagePercent: Double
    let gpuName: String
    let usedMemoryBytes: UInt64
    let totalMemoryBytes: UInt64
    let refreshIntervalSeconds: Int

    static let placeholder = StatsSnapshot(
        cpuUsagePercent: 0,
        gpuName: "Unavailable",
        usedMemoryBytes: 0,
        totalMemoryBytes: 0,
        refreshIntervalSeconds: 2
    )
}
