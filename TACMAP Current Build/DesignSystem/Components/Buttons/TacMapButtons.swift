import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TacMapTypography.labelLarge)
                .foregroundColor(isEnabled ? TacMapColors.textInverse : TacMapColors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TacMapSpacing.sm)
                .background(isEnabled ? TacMapColors.accentPrimary : TacMapColors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TacMapTypography.labelLarge)
                .foregroundColor(TacMapColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TacMapSpacing.sm)
                .background(TacMapColors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct IconButton: View {
    let icon: String
    var size: CGFloat = TacMapLayout.floatingControlSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: TacMapIcons.sizeMedium))
                .foregroundColor(TacMapColors.textPrimary)
                .frame(width: size, height: size)
                .background(TacMapColors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.floatingControlCornerRadius))
        }
    }
}
