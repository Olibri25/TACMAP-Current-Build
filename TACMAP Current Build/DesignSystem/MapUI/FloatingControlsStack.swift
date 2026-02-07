import SwiftUI

// MARK: - Bottom-Right Controls (Elevation, Map Mode, Location)

struct FloatingControlsBottomRight: View {
    let mapMode: MapMode
    let isFollowingLocation: Bool
    @Binding var terrainExaggeration: Double
    let onLocationTap: () -> Void
    let onMapModeTap: () -> Void

    var body: some View {
        VStack(spacing: TacMapLayout.floatingControlSpacing) {
            // Elevation slider (3D only)
            if mapMode.is3DEnabled {
                VStack(spacing: TacMapSpacing.xxs) {
                    Image(systemName: "mountain.2")
                        .font(.system(size: 10))
                        .foregroundColor(TacMapColors.textSecondary)

                    CustomSlider(value: $terrainExaggeration, range: 1.0...3.0)
                        .frame(height: 80)

                    Text(String(format: "%.1fx", terrainExaggeration))
                        .font(TacMapTypography.captionSmall)
                        .foregroundColor(TacMapColors.textSecondary)
                }
                .padding(.vertical, TacMapSpacing.xxs)
                .frame(width: TacMapLayout.floatingControlSize)
                .background(TacMapColors.backgroundElevated.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.floatingControlCornerRadius))
            }

            // Map Mode
            FloatingControlButton(
                icon: mapMode.iconName,
                label: mapMode.displayName
            ) {
                onMapModeTap()
            }

            // Location
            FloatingControlButton(
                icon: isFollowingLocation ? TacMapIcons.locationFill : TacMapIcons.location,
                isActive: isFollowingLocation
            ) {
                onLocationTap()
            }
        }
    }
}

// MARK: - Shared Components

struct FloatingControlButton: View {
    let icon: String
    var label: String? = nil
    var isActive: Bool = false
    var rotation: Double = 0
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: TacMapIcons.sizeMedium))
                    .rotationEffect(.degrees(rotation))

                if let label {
                    Text(label)
                        .font(TacMapTypography.captionSmall)
                }
            }
            .foregroundColor(isActive ? TacMapColors.accentPrimary : TacMapColors.textPrimary)
            .frame(width: TacMapLayout.floatingControlSize, height: TacMapLayout.floatingControlSize)
            .background(TacMapColors.backgroundElevated.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.floatingControlCornerRadius))
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)

            ZStack(alignment: .bottom) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(TacMapColors.textTertiary)
                    .frame(width: 3)

                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(TacMapColors.accentPrimary)
                    .frame(width: 3, height: height * normalized)

                // Thumb
                Circle()
                    .fill(TacMapColors.accentPrimary)
                    .frame(width: 14, height: 14)
                    .offset(y: -(height * normalized - 7))
            }
            .frame(maxWidth: .infinity)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let normalized = 1 - min(max(drag.location.y / height, 0), 1)
                        value = range.lowerBound + normalized * (range.upperBound - range.lowerBound)
                    }
            )
        }
    }
}
