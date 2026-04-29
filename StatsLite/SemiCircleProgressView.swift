import SwiftUI

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

    init(value: Int) {
        self.model = SemiCircleProgressViewModel(rawValue: value)
    }

    var body: some View {
        ZStack {
            SemiCircleShape(progress: 1)
                .stroke(Color(nsColor: .systemGray), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            SemiCircleShape(progress: model.progress)
                .stroke(Color(red: 0.12, green: 0.54, blue: 0.44), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            Text("\(model.displayValue)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .offset(y: 5)
        }
        .frame(width: 42, height: 26)
        .accessibilityLabel("CPU \(model.displayValue) percent")
    }
}

private struct SemiCircleShape: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let radius = min(rect.width / 2 - 7, rect.height - 6)
        let center = CGPoint(x: rect.midX, y: rect.maxY - 6)
        let startAngle = Angle.degrees(180)
        let endAngle = Angle.degrees(180 + 180 * clampedProgress)

        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}
