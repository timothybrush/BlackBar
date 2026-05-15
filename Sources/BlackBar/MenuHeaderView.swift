import SwiftUI

struct MenuHeaderView: View {
    let snapshot: DashboardSnapshot
    let history: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("vCPU")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Self.vcpuText(self.snapshot.usage.activeVCPU))
                        .font(.system(size: 30, weight: .semibold, design: .monospaced))
                }
                .fixedSize(horizontal: true, vertical: false)
                Spacer()
                UsageSummaryView(samples: self.chartSamples, rangeLabel: self.chartRangeLabel)
                    .padding(.bottom, 2)
            }

            UsageTrendChart(samples: self.chartSamples, rangeLabel: self.chartRangeLabel)
                .frame(height: 74)

            PlatformLegendView(platformUsage: self.snapshot.usage.platformUsage)

            HStack(spacing: 7) {
                Circle()
                    .fill(self.snapshot.isOperational ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(self.snapshot.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 360, alignment: .leading)
    }

    private var chartSamples: [CoreUsageHistorySample] {
        if !snapshot.usage.historySamples.isEmpty {
            return Array(snapshot.usage.historySamples.suffix(96))
        }
        let values = history.isEmpty ? [snapshot.usage.activeVCPU] : Array(history.suffix(96))
        return values.map { value in
            CoreUsageHistorySample(
                amd64: CoreUsage(vcpus: max(0, value), jobs: 0),
                arm64: CoreUsage(vcpus: 0, jobs: 0),
                macos: CoreUsage(vcpus: 0, jobs: 0)
            )
        }
    }

    private var chartRangeLabel: String {
        snapshot.usage.historySamples.isEmpty ? "recent vCPU" : "24h vCPU"
    }

    private static func vcpuText(_ value: Int) -> String {
        String(value)
    }
}

private struct UsageSummaryView: View {
    var samples: [CoreUsageHistorySample]
    var rangeLabel: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(rangeLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("peak \(peak)")
                .font(.caption.monospacedDigit().weight(.semibold))
            Text("avg \(average)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var totals: [Int] {
        samples.map(\.total.vcpus)
    }

    private var peak: Int {
        totals.max() ?? 0
    }

    private var average: Int {
        guard !totals.isEmpty else { return 0 }
        let total = totals.reduce(0, +)
        return Int((Double(total) / Double(totals.count)).rounded())
    }
}

private struct UsageTrendChart: View {
    var samples: [CoreUsageHistorySample]
    var rangeLabel: String

    var body: some View {
        Canvas { context, size in
            let samples = self.samples.isEmpty ? [CoreUsageHistorySample(amd64: .init(vcpus: 0, jobs: 0), arm64: .init(vcpus: 0, jobs: 0), macos: .init(vcpus: 0, jobs: 0))] : self.samples
            let maxTotal = max(samples.map(\.total.vcpus).max() ?? 0, 1)
            let count = samples.count
            let gap: CGFloat = count > 64 ? 1 : 2
            let barWidth = max(1, (size.width - CGFloat(max(count - 1, 0)) * gap) / CGFloat(max(count, 1)))

            self.drawGrid(in: &context, size: size)

            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * (barWidth + gap)
                var bottom = size.height
                self.drawSegment(value: sample.amd64.vcpus, maxTotal: maxTotal, x: x, width: barWidth, bottom: &bottom, size: size, color: .indigo, context: &context)
                self.drawSegment(value: sample.arm64.vcpus, maxTotal: maxTotal, x: x, width: barWidth, bottom: &bottom, size: size, color: .cyan, context: &context)
                self.drawSegment(value: sample.macos.vcpus, maxTotal: maxTotal, x: x, width: barWidth, bottom: &bottom, size: size, color: .pink, context: &context)
            }

            var line = Path()
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * (barWidth + gap) + barWidth / 2
                let y = size.height - (size.height * CGFloat(sample.total.vcpus) / CGFloat(maxTotal))
                if index == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(line, with: .color(.primary.opacity(0.78)), lineWidth: 1.4)
        }
        .accessibilityLabel("\(rangeLabel) usage")
    }

    private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
        for fraction in [0.25, 0.5, 0.75] as [CGFloat] {
            var path = Path()
            let y = size.height * fraction
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.secondary.opacity(0.18)), lineWidth: 1)
        }
    }

    private func drawSegment(
        value: Int,
        maxTotal: Int,
        x: CGFloat,
        width: CGFloat,
        bottom: inout CGFloat,
        size: CGSize,
        color: Color,
        context: inout GraphicsContext)
    {
        guard value > 0 else { return }
        let height = size.height * CGFloat(value) / CGFloat(maxTotal)
        guard height >= 0.5 else { return }
        bottom -= height
        let rect = CGRect(x: x, y: bottom, width: width, height: height)
        context.fill(Path(roundedRect: rect, cornerRadius: min(2, width / 2)), with: .color(color.opacity(0.86)))
    }
}

private struct PlatformLegendView: View {
    var platformUsage: [String: CoreUsage]

    var body: some View {
        HStack(spacing: 10) {
            PlatformLegendItem(label: "amd64", usage: platformUsage["amd64"], color: .indigo)
            PlatformLegendItem(label: "arm64", usage: platformUsage["arm64"], color: .cyan)
            PlatformLegendItem(label: "mac", usage: platformUsage["macos"], color: .pink)
            Spacer(minLength: 0)
        }
    }
}

private struct PlatformLegendItem: View {
    var label: String
    var usage: CoreUsage?
    var color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(usage?.vcpus ?? 0)v/\(usage?.jobs ?? 0)j")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

struct Sparkline: View {
    var values: [Int]

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(self.values.max() ?? 1, 1)
            let count = max(self.values.count, 1)
            let barWidth = max(2, proxy.size.width / CGFloat(max(count, 24)) - 1)

            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(self.values.suffix(48).enumerated()), id: \.offset) { _, value in
                    Capsule()
                        .fill(value == 0 ? Color.secondary.opacity(0.24) : Color.cyan)
                        .frame(
                            width: barWidth,
                            height: max(2, proxy.size.height * CGFloat(value) / CGFloat(maxValue))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}
