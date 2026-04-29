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
