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

    func testMenuBarLayoutCentersTwoCompactViewsWithOnePointHorizontalPadding() {
        let container = CGRect(x: 0, y: 0, width: 78, height: 26)
        let frame = MenuBarItemLayout.contentFrame(in: container)

        XCTAssertEqual(MenuBarItemLayout.horizontalPadding, 1)
        XCTAssertEqual(MenuBarItemLayout.itemSpacing, 4)
        XCTAssertEqual(MenuBarItemLayout.statusItemLength, SemiCircleProgressLayout.viewSize.width * 2 + MenuBarItemLayout.itemSpacing + 2)
        XCTAssertEqual(frame.origin.x, (container.width - MenuBarItemLayout.contentSize.width) / 2)
        XCTAssertEqual(frame.origin.y, (container.height - SemiCircleProgressLayout.viewSize.height) / 2)
        XCTAssertEqual(frame.size.width, MenuBarItemLayout.contentSize.width)
        XCTAssertEqual(frame.size.height, SemiCircleProgressLayout.viewSize.height)
    }

    func testMenuBarLayoutUsesSelectedMetricCount() {
        XCTAssertEqual(MenuBarItemLayout.metricCount(for: .cpuAndMemory), 2)
        XCTAssertEqual(MenuBarItemLayout.metricCount(for: .cpuOnly), 1)
        XCTAssertEqual(MenuBarItemLayout.metricCount(for: .memoryOnly), 1)

        XCTAssertEqual(
            MenuBarItemLayout.contentSize(for: .cpuOnly).width,
            SemiCircleProgressLayout.viewSize.width
        )
        XCTAssertEqual(
            MenuBarItemLayout.contentSize(for: .cpuAndMemory).width,
            SemiCircleProgressLayout.viewSize.width * 2 + MenuBarItemLayout.itemSpacing
        )
    }
}
