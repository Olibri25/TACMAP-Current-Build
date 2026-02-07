import SwiftUI

struct OfflineMapsPanel: View {
    var body: some View {
        VStack(spacing: TacMapSpacing.md) {
            Text("Offline Maps")
                .font(TacMapTypography.headlineLarge)
                .foregroundColor(TacMapColors.textPrimary)

            Spacer()

            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(TacMapColors.textTertiary)

            Text("Coming Soon")
                .font(TacMapTypography.headlineMedium)
                .foregroundColor(TacMapColors.textSecondary)

            Text("Offline map downloads will be available in a future update.")
                .font(TacMapTypography.bodyMedium)
                .foregroundColor(TacMapColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TacMapSpacing.xxl)

            Spacer()
        }
        .padding(.top, TacMapSpacing.sm)
    }
}
