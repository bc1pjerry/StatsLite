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

    func testMenuBarLayoutKeepsCompactViewWithPadding() {
        XCTAssertEqual(SemiCircleProgressLayout.viewSize.width, 28)
        XCTAssertEqual(SemiCircleProgressLayout.viewSize.height, 20)
        XCTAssertEqual(SemiCircleProgressLayout.strokeWidth, 3)
        XCTAssertEqual(SemiCircleProgressLayout.textSize, 6)

        XCTAssertEqual(MenuBarItemLayout.statusItemLength, 32)
        XCTAssertEqual(MenuBarItemLayout.contentFrame.origin.x, 2)
        XCTAssertEqual(MenuBarItemLayout.contentFrame.origin.y, 1)
        XCTAssertEqual(MenuBarItemLayout.contentFrame.size.width, SemiCircleProgressLayout.viewSize.width)
        XCTAssertEqual(MenuBarItemLayout.contentFrame.size.height, SemiCircleProgressLayout.viewSize.height)
    }
}
