import SwiftUI

struct JobMenuRowView: View {
    let run: WorkflowRunUsage
    let isFallback: Bool
    let open: () -> Void

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: self.statusIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(self.statusColor)
                .frame(width: 16, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(self.primaryTitle)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    Text(self.statusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(self.statusTextColor)
                        .lineLimit(1)
                }

                HStack(spacing: 7) {
                    Text("\(self.run.activeVCPU) vCPU")
                        .fontWeight(.semibold)
                        .monospacedDigit()

                    Text(self.run.repository)

                    if let pullRequestNumber = self.run.pullRequestNumber {
                        Text("#\(pullRequestNumber)")
                    }

                    if let branchName = self.run.branchName, !branchName.isEmpty {
                        Text(branchName)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .font(.caption)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(1)

                HStack(spacing: 7) {
                    if let actorLogin = self.run.actorLogin, !actorLogin.isEmpty {
                        Label(actorLogin, systemImage: "person.crop.circle")
                            .labelStyle(.titleAndIcon)
                    }

                    if let runnerLabel {
                        Text(runnerLabel)
                    }

                    if let shortSHA {
                        Text(shortSHA)
                            .fontDesign(.monospaced)
                    }

                    if let commitSubject {
                        Text(commitSubject)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer(minLength: 8)

                    if let timingLabel {
                        Text(timingLabel)
                            .monospacedDigit()
                    }
                }
                .font(.caption2)
                .foregroundStyle(MenuHighlightStyle.tertiary(self.isHighlighted))
                .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: self.open)
    }

    private var primaryTitle: String {
        self.run.title.isEmpty ? self.run.workflowName : self.run.title
    }

    private var normalizedStatus: String {
        let status = self.run.status.isEmpty ? self.run.jobs.first?.status ?? "" : self.run.status
        return status.lowercased().replacingOccurrences(of: "-", with: "_")
    }

    private var statusLabel: String {
        switch self.normalizedStatus {
        case "in_progress":
            return "running"
        case "queued":
            return "queued"
        case "success":
            return self.isFallback ? "latest" : "success"
        case "failure":
            return "failed"
        case "cancelled", "canceled":
            return "cancelled"
        case "skipped":
            return "skipped"
        default:
            return self.normalizedStatus.isEmpty ? "job" : self.normalizedStatus.replacingOccurrences(of: "_", with: " ")
        }
    }

    private var statusIcon: String {
        switch self.normalizedStatus {
        case "in_progress", "queued":
            return "play.circle"
        case "success":
            return "checkmark.circle"
        case "failure":
            return "xmark.circle"
        case "cancelled", "canceled", "skipped":
            return "minus.circle"
        default:
            return "circle"
        }
    }

    private var statusColor: Color {
        switch self.normalizedStatus {
        case "in_progress", "queued":
            return .blue
        case "success":
            return .green
        case "failure":
            return .red
        case "cancelled", "canceled", "skipped":
            return .secondary
        default:
            return .orange
        }
    }

    private var statusTextColor: Color {
        self.isHighlighted ? .white.opacity(0.86) : self.statusColor
    }

    private var runnerLabel: String? {
        if let runnerName = self.run.runnerName, !runnerName.isEmpty {
            return runnerName
        }
        guard let runnerType = self.run.runnerType, !runnerType.isEmpty else { return nil }
        return runnerType
    }

    private var shortSHA: String? {
        guard let sha = self.run.commitSHA, !sha.isEmpty else { return nil }
        return String(sha.prefix(7))
    }

    private var commitSubject: String? {
        guard let message = self.run.commitMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty
        else { return nil }
        return message.components(separatedBy: .newlines).first
    }

    private var timingLabel: String? {
        if let durationSeconds = self.run.durationSeconds, durationSeconds > 0 {
            return Self.durationString(seconds: durationSeconds)
        }
        guard let updatedAt = self.run.updatedAt ?? self.run.startedAt else { return nil }
        return Self.relativeFormatter.localizedString(for: updatedAt, relativeTo: Date())
    }

    private static func durationString(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
