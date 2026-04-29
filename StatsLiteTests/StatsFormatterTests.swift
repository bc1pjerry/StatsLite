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
