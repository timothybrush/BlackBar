import SwiftUI

struct StatusMenuActionRowView: View {
    let status: BlacksmithStatus
    let open: () -> Void

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .frame(width: 16, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Open Blacksmith Status")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(self.status.badgeLabel)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(StatusPalette.foreground(for: self.status, isHighlighted: self.isHighlighted))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(StatusPalette.background(for: self.status, isHighlighted: self.isHighlighted))
                        )
                        .lineLimit(1)
                }

                if self.status.hasActiveNotice {
                    Text("\(self.status.noticeKind): \(self.status.noticeTitle ?? self.status.label)")
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture(perform: self.open)
    }
}
