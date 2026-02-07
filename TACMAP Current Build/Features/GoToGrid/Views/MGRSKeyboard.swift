import SwiftUI

struct MGRSKeyboard: View {
    let focusedField: GoToGridViewModel.Field?
    let onKey: (String) -> Void
    let onBackspace: () -> Void
    let onNext: () -> Void

    private var keys: [String] {
        guard let field = focusedField else { return [] }
        switch field {
        case .zone:
            return ["1","2","3","4","5","6","7","8","9","0","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X"]
        case .square:
            return ["A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z"]
        case .easting, .northing:
            return ["1","2","3","4","5","6","7","8","9","0"]
        }
    }

    private var columns: Int {
        guard let field = focusedField else { return 5 }
        switch field {
        case .zone: return 10
        case .square: return 8
        case .easting, .northing: return 5
        }
    }

    var body: some View {
        VStack(spacing: TacMapSpacing.xxs) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: TacMapSpacing.xxxs), count: columns), spacing: TacMapSpacing.xxxs) {
                ForEach(keys, id: \.self) { key in
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onKey(key)
                    }) {
                        Text(key)
                            .font(TacMapTypography.monoMedium)
                            .foregroundColor(TacMapColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(TacMapColors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            HStack(spacing: TacMapSpacing.xs) {
                // Backspace
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onBackspace()
                }) {
                    Image(systemName: "delete.backward")
                        .font(.system(size: 16))
                        .foregroundColor(TacMapColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(TacMapColors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Next
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onNext()
                }) {
                    Text("Next")
                        .font(TacMapTypography.labelMedium)
                        .foregroundColor(TacMapColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(TacMapColors.accentPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, TacMapSpacing.md)
    }
}
