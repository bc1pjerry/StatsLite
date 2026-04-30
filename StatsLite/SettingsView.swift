import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case appearance
    case metrics

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general:
            return "常规"
        case .appearance:
            return "外观"
        case .metrics:
            return "指标"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .appearance:
            return "paintpalette"
        case .metrics:
            return "gauge.with.dots.needle.bottom.50percent"
        }
    }
}

private enum SettingsTheme {
    static let background = Color(red: 0.08, green: 0.10, blue: 0.12)
    static let sidebar = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let panel = Color(red: 0.12, green: 0.15, blue: 0.18)
    static let panelBorder = Color.white.opacity(0.08)
    static let secondaryText = Color(red: 0.58, green: 0.64, blue: 0.70)
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var statsState: StatsState
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsSection.allCases) { section in
                    Label(section.title, systemImage: section.systemImage)
                        .tag(section)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(SettingsTheme.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 152, max: 180)
        } detail: {
            detailView(for: selection ?? .general)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(SettingsTheme.background)
        }
        .frame(width: 680, height: 430)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(for: section)

                switch section {
                case .general:
                    generalPanel
                case .appearance:
                    appearancePanel
                case .metrics:
                    metricsPanel
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }

    private func header(for section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)

            Text(subtitle(for: section))
                .font(.callout)
                .foregroundStyle(SettingsTheme.secondaryText)
        }
    }

    private func subtitle(for section: SettingsSection) -> String {
        switch section {
        case .general:
            return "控制菜单栏数据刷新节奏"
        case .appearance:
            return "调整菜单栏仪表和指标卡强调色"
        case .metrics:
            return "查看当前状态并选择菜单栏显示内容"
        }
    }

    private var generalPanel: some View {
        SettingsPanel(title: "刷新间隔", subtitle: "更短的间隔会让读数更实时，也会略微增加采样频率。") {
            Picker("刷新间隔", selection: $settings.refreshInterval) {
                ForEach(RefreshInterval.allCases) { interval in
                    Text(interval.label).tag(interval)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.large)

            SettingReadout(title: "当前", value: "\(settings.refreshInterval.seconds) 秒")
        }
    }

    private var appearancePanel: some View {
        SettingsPanel(title: "强调色", subtitle: "颜色会同步用于菜单栏半圆仪表和设置窗口指标卡。") {
            HStack(spacing: 12) {
                ForEach(AccentColorPreset.allCases) { preset in
                    AccentColorButton(
                        preset: preset,
                        isSelected: preset == settings.accentColorPreset
                    ) {
                        settings.accentColorPreset = preset
                    }
                }
            }
        }
    }

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPanel(title: "菜单栏指标", subtitle: "GPU 当前只有设备名称，第一版先保留在详情中。") {
                Picker("菜单栏指标", selection: $settings.metricLayout) {
                    ForEach(MetricLayout.allCases) { layout in
                        Text(layout.title).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                MetricCard(
                    title: "CPU",
                    value: "\(StatsFormatter.primaryInteger(cpuUsage: statsState.snapshot.cpuUsagePercent))%",
                    detail: "Processor load",
                    accentColor: settings.accentColorPreset.color
                )
                MetricCard(
                    title: "Memory",
                    value: "\(StatsFormatter.memoryUsageInteger(usedBytes: statsState.snapshot.usedMemoryBytes, totalBytes: statsState.snapshot.totalMemoryBytes))%",
                    detail: StatsFormatter.memorySummary(usedBytes: statsState.snapshot.usedMemoryBytes, totalBytes: statsState.snapshot.totalMemoryBytes),
                    accentColor: settings.accentColorPreset.color
                )
                MetricCard(
                    title: "GPU",
                    value: statsState.snapshot.gpuName,
                    detail: "Default graphics device",
                    accentColor: settings.accentColorPreset.color
                )
            }
        }
    }
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SettingsTheme.secondaryText)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(SettingsTheme.panelBorder)
        )
    }
}

private struct SettingReadout: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(SettingsTheme.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.callout)
    }
}

private struct AccentColorButton: View {
    let preset: AccentColorPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(preset.color)
                        .frame(width: 34, height: 34)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                Text(preset.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : SettingsTheme.secondaryText)
            }
            .frame(width: 86, height: 74)
            .background(isSelected ? preset.color.opacity(0.18) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? preset.color.opacity(0.7) : SettingsTheme.panelBorder)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SettingsTheme.secondaryText)

            Text(value)
                .font(.system(size: value.count > 8 ? 16 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(title == "CPU" ? accentColor : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(SettingsTheme.secondaryText)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .background(SettingsTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(SettingsTheme.panelBorder)
        )
    }
}
