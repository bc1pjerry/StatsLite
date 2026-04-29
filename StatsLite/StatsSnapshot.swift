import Foundation

struct StatsSnapshot: Equatable {
    let cpuUsagePercent: Double
    let gpuName: String
    let usedMemoryBytes: UInt64
    let totalMemoryBytes: UInt64
    let refreshIntervalSeconds: Int
}
