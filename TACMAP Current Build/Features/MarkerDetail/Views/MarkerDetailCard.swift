import SwiftUI
import CoreLocation

enum MarkerDetailDetent {
    case hidden, collapsed, expanded, full

    var fraction: CGFloat {
        switch self {
        case .hidden: return 0
        case .collapsed: return 0.20
        case .expanded: return 0.60
        case .full: return 0.90
        }
    }
}

struct MarkerDetailCard: View {
    let marker: MarkerSelection
    @Binding var isPresented: Bool
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var detent: MarkerDetailDetent = .collapsed
    @State private var showDeleteConfirmation = false

    private var distanceFromUser: String? {
        guard let userLoc = locationService.currentLocation else { return nil }
        let dist = DistanceCalculator.distance(from: userLoc.coordinate, to: marker.coordinate)
        let bearing = DistanceCalculator.bearing(from: userLoc.coordinate, to: marker.coordinate)
        return "\(DistanceCalculator.formatDistance(dist)) / \(DistanceCalculator.formatBearing(bearing))"
    }

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height * detent.fraction

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    Capsule()
                        .fill(TacMapColors.textTertiary)
                        .frame(width: 36, height: 5)
                        .padding(.top, TacMapSpacing.xs)

                    ScrollView {
                        VStack(alignment: .leading, spacing: TacMapSpacing.md) {
                            // Header
                            headerSection

                            if detent == .expanded || detent == .full {
                                Divider().background(TacMapColors.borderDefault)

                                // Overlays section placeholder
                                overlaysSection

                                Divider().background(TacMapColors.borderDefault)

                                // Actions
                                actionsSection
                            }
                        }
                        .padding(.horizontal, TacMapSpacing.md)
                        .padding(.top, TacMapSpacing.sm)
                    }
                }
                .frame(height: max(height, 0))
                .background(TacMapColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.panelCornerRadius, style: .continuous))
            }
            .animation(TacMapAnimation.panel, value: detent)
        }
        .confirmationDialog("Delete Marker?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteMarker()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: TacMapSpacing.sm) {
            Image(systemName: marker.iconName)
                .font(.system(size: 24))
                .foregroundColor(marker.iconColor)
                .frame(width: 40, height: 40)
                .background(marker.iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(marker.name)
                    .font(TacMapTypography.headlineMedium)
                    .foregroundColor(TacMapColors.textPrimary)

                Button(action: {
                    UIPasteboard.general.string = marker.mgrsGrid
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    HStack(spacing: 4) {
                        Text(marker.mgrsGrid)
                            .font(TacMapTypography.monoSmall)
                        Image(systemName: TacMapIcons.copy)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(TacMapColors.accentPrimary)
                }

                if let dist = distanceFromUser {
                    Text(dist)
                        .font(TacMapTypography.captionSmall)
                        .foregroundColor(TacMapColors.textTertiary)
                }
            }

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: TacMapIcons.close)
                    .foregroundColor(TacMapColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(TacMapColors.backgroundTertiary)
                    .clipShape(Circle())
            }
        }
        .onTapGesture {
            withAnimation(TacMapAnimation.panel) {
                detent = detent == .collapsed ? .expanded : .collapsed
            }
        }
    }

    // MARK: - Overlays
    private var overlaysSection: some View {
        VStack(alignment: .leading, spacing: TacMapSpacing.xs) {
            Text("Overlays")
                .font(TacMapTypography.headlineSmall)
                .foregroundColor(TacMapColors.textSecondary)

            Text("Range rings, RED circles, and sectors of fire can be configured here.")
                .font(TacMapTypography.bodySmall)
                .foregroundColor(TacMapColors.textTertiary)
        }
    }

    // MARK: - Actions
    private var actionsSection: some View {
        VStack(spacing: TacMapSpacing.xs) {
            Button(action: {
                mapViewModel.navigateToCoordinate(marker.coordinate)
            }) {
                HStack {
                    Image(systemName: TacMapIcons.goToGrid)
                    Text("Go To Grid")
                }
                .font(TacMapTypography.labelLarge)
                .foregroundColor(TacMapColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TacMapSpacing.sm)
                .background(TacMapColors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: TacMapIcons.delete)
                    Text("Delete Marker")
                }
                .font(TacMapTypography.labelLarge)
                .foregroundColor(TacMapColors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TacMapSpacing.sm)
                .background(TacMapColors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func deleteMarker() {
        // Delete from SwiftData based on marker type
        switch marker {
        case .waypoint(let entity):
            modelContext.delete(entity)
        case .militarySymbol(let entity):
            modelContext.delete(entity)
        }
        isPresented = false
    }
}
