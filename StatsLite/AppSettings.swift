import Combine
import Foundation
import SwiftUI

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case oneSecond = 1
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10

    var id: Int {
        rawValue
    }

    var label: String {
        "\(rawValue)s"
    }

    var seconds: Int {
        rawValue
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }
}

enum AccentColorPreset: String, CaseIterable, Identifiable {
    case teal
    case blue
    case orange

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .teal:
            return "Teal"
        case .blue:
            return "Blue"
        case .orange:
            return "Orange"
        }
    }

    var color: Color {
        switch self {
        case .teal:
            return Color(red: 0.12, green: 0.54, blue: 0.44)
        case .blue:
            return Color(red: 0.23, green: 0.45, blue: 0.78)
        case .orange:
            return Color(red: 0.78, green: 0.44, blue: 0.23)
        }
    }
}

enum MetricLayout: String, CaseIterable, Identifiable {
    case cpuAndMemory
    case cpuOnly
    case memoryOnly

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .cpuAndMemory:
            return "CPU + Memory"
        case .cpuOnly:
            return "CPU only"
        case .memoryOnly:
            return "Memory only"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    enum Keys {
        static let refreshInterval = "refreshIntervalSeconds"
        static let accentColorPreset = "accentColorPreset"
        static let metricLayout = "metricLayout"
    }

    private let defaults: UserDefaults

    @Published var refreshInterval: RefreshInterval {
        didSet {
            defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval)
        }
    }

    @Published var accentColorPreset: AccentColorPreset {
        didSet {
            defaults.set(accentColorPreset.rawValue, forKey: Keys.accentColorPreset)
        }
    }

    @Published var metricLayout: MetricLayout {
        didSet {
            defaults.set(metricLayout.rawValue, forKey: Keys.metricLayout)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.refreshInterval = RefreshInterval(rawValue: defaults.integer(forKey: Keys.refreshInterval)) ?? .twoSeconds
        self.accentColorPreset = defaults.string(forKey: Keys.accentColorPreset).flatMap(AccentColorPreset.init(rawValue:)) ?? .teal
        self.metricLayout = defaults.string(forKey: Keys.metricLayout).flatMap(MetricLayout.init(rawValue:)) ?? .cpuAndMemory
    }
}
