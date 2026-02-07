import SwiftUI

struct CoordinateLabel: View {
    let mgrs: String
    let elevation: Double?

    var body: some View {
        HStack(spacing: TacMapSpacing.xs) {
            Text(mgrs)
                .font(TacMapTypography.monoSmall)
                .foregroundColor(TacMapColors.textPrimary)

            if let elevation {
                Text("\(Int(elevation))m")
                    .font(TacMapTypography.monoSmall)
                    .foregroundColor(TacMapColors.textSecondary)
            }
        }
        .padding(.horizontal, TacMapSpacing.sm)
        .padding(.vertical, TacMapSpacing.xxs)
        .background(TacMapColors.backgroundElevated.opacity(0.85))
        .clipShape(Capsule())
    }
}
