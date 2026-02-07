import SwiftUI

struct MapCrosshair: View {
    var color: Color = TacMapColors.crosshair
    var size: CGFloat = 40
    var lineWidth: CGFloat = 1.5

    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(color)
                .frame(width: size, height: lineWidth)

            // Vertical line
            Rectangle()
                .fill(color)
                .frame(width: lineWidth, height: size)

            // Center dot
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)

            // Gap circle (mask out center)
            Circle()
                .fill(TacMapColors.backgroundPrimary.opacity(0.01))
                .frame(width: 8, height: 8)
        }
        .allowsHitTesting(false)
    }
}
