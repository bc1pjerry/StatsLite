import SwiftUI

enum SemiCircleProgressLayout {
    static let viewSize = CGSize(width: 30, height: 20)
    static let strokeWidth: CGFloat = 3
    static let textSize: CGFloat = 8
    static let textYOffset: CGFloat = 3
    static let radiusHorizontalInset: CGFloat = 5
    static let radiusBottomInset: CGFloat = 5
}

struct SemiCircleProgressViewModel: Equatable {
    let displayValue: Int
    let progress: Double

    init(rawValue: Int) {
        let clamped = min(max(rawValue, 0), 100)
        self.displayValue = clamped
        self.progress = Double(clamped) / 100
    }
}

struct SemiCircleProgressView: View {
    let model: SemiCircleProgressViewModel
    private let accentColor: Color
    private let accessibilityName: String

    init(value: Int, accentColor: Color = Color(red: 0.12, green: 0.54, blue: 0.44), accessibilityName: String = "CPU") {
        self.model = SemiCircleProgressViewModel(rawValue: value)
        self.accentColor = accentColor
        self.accessibilityName = accessibilityName
    }

    var body: some View {
        ZStack {
            SemiCircleShape(progress: 1)
                .stroke(Color(nsColor: .systemGray), style: StrokeStyle(lineWidth: SemiCircleProgressLayout.strokeWidth, lineCap: .round))

            SemiCircleShape(progress: model.progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: SemiCircleProgressLayout.strokeWidth, lineCap: .round))

            Text("\(model.displayValue)")
                .font(.system(size: SemiCircleProgressLayout.textSize, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(y: SemiCircleProgressLayout.textYOffset)
        }
        .frame(width: SemiCircleProgressLayout.viewSize.width, height: SemiCircleProgressLayout.viewSize.height)
        .accessibilityLabel("\(accessibilityName) \(model.displayValue) percent")
    }
}

struct MenuBarStatsView: View {
    let cpuValue: Int
    let memoryValue: Int
    let metricLayout: MetricLayout
    let accentColor: Color

    var body: some View {
        HStack(spacing: MenuBarItemLayout.itemSpacing) {
            if metricLayout != .memoryOnly {
                SemiCircleProgressView(value: cpuValue, accentColor: accentColor, accessibilityName: "CPU")
            }

            if metricLayout != .cpuOnly {
                SemiCircleProgressView(value: memoryValue, accentColor: accentColor, accessibilityName: "Memory")
            }
        }
        .frame(width: MenuBarItemLayout.contentSize(for: metricLayout).width, height: MenuBarItemLayout.contentSize(for: metricLayout).height)
    }
}

private struct SemiCircleShape: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let radius = min(rect.width / 2 - SemiCircleProgressLayout.radiusHorizontalInset, rect.height - SemiCircleProgressLayout.radiusBottomInset)
        let center = CGPoint(x: rect.midX, y: rect.maxY - SemiCircleProgressLayout.radiusBottomInset)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + 180 * clampedProgress)

        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
