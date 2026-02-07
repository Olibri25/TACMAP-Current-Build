import SwiftUI

struct ScaleBar: View {
    let metersPerPixel: Double
    private let barWidth: CGFloat = 80

    private var scaleDistance: Double {
        let rawMeters = metersPerPixel * Double(barWidth)
        let niceValues: [Double] = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000]
        return niceValues.min(by: { abs($0 - rawMeters) < abs($1 - rawMeters) }) ?? rawMeters
    }

    private var adjustedWidth: CGFloat {
        CGFloat(scaleDistance / metersPerPixel)
    }

    private var label: String {
        DistanceCalculator.formatDistance(scaleDistance)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(TacMapTypography.captionSmall)
                .foregroundColor(TacMapColors.textSecondary)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(TacMapColors.textSecondary)
                    .frame(width: min(adjustedWidth, 120), height: 2)
                Rectangle()
                    .fill(TacMapColors.textSecondary)
                    .frame(width: 1, height: 6)
            }
        }
        .padding(TacMapSpacing.xxs)
    }
}
