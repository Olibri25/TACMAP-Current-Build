import SwiftUI

struct GPSIndicator: View {
    let accuracy: GPSAccuracy
    let isAcquiring: Bool

    var body: some View {
        HStack(spacing: TacMapSpacing.xxs) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)
                .opacity(isAcquiring ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAcquiring)

            Text(accuracy.rawValue.uppercased())
                .font(TacMapTypography.captionSmall)
                .foregroundColor(TacMapColors.textSecondary)
        }
    }

    private var indicatorColor: Color {
        switch accuracy {
        case .accurate: return TacMapColors.gpsAccurate
        case .fair: return TacMapColors.gpsFair
        case .poor: return TacMapColors.gpsPoor
        case .none: return TacMapColors.gpsNone
        }
    }
}
