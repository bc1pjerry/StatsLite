import XCTest
@testable import StatsLite

@MainActor
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
