import SwiftUI
import SwiftData
import CoreLocation

struct MyContentPanel: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaypointEntity.createdAt, order: .reverse) private var waypoints: [WaypointEntity]
    @Query(sort: \RouteEntity.createdAt, order: .reverse) private var routes: [RouteEntity]
    @Query(sort: \MilitarySymbolEntity.createdAt, order: .reverse) private var symbols: [MilitarySymbolEntity]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TacMapSpacing.md) {
                Text("My Content")
                    .font(TacMapTypography.headlineLarge)
                    .foregroundColor(TacMapColors.textPrimary)
                    .padding(.horizontal, TacMapSpacing.md)

                if waypoints.isEmpty && routes.isEmpty && symbols.isEmpty {
                    emptyState
                } else {
                    if !waypoints.isEmpty {
                        contentSection(title: "Waypoints (\(waypoints.count))") {
                            ForEach(waypoints) { wp in
                                ContentRow(icon: wp.icon, iconColor: Color(hex: wp.color), title: wp.name, subtitle: CoordinateConverter.toMGRS(CLLocationCoordinate2D(latitude: wp.latitude, longitude: wp.longitude), precision: 4))
                            }
                        }
                    }
                    if !symbols.isEmpty {
                        contentSection(title: "Symbols (\(symbols.count))") {
                            ForEach(symbols) { sym in
                                ContentRow(icon: "shield.fill", iconColor: sym.affiliationEnum.color, title: sym.name, subtitle: sym.affiliation)
                            }
                        }
                    }
                    if !routes.isEmpty {
                        contentSection(title: "Routes (\(routes.count))") {
                            ForEach(routes) { route in
                                ContentRow(icon: "point.topleft.down.to.point.bottomright.curvepath", iconColor: Color(hex: route.color), title: route.name, subtitle: "\(route.points.count) points")
                            }
                        }
                    }
                }
            }
            .padding(.top, TacMapSpacing.sm)
        }
    }

    private var emptyState: some View {
        VStack(spacing: TacMapSpacing.md) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(TacMapColors.textTertiary)
            Text("No content yet")
                .font(TacMapTypography.bodyMedium)
                .foregroundColor(TacMapColors.textSecondary)
            Text("Use Quick Drop to place markers and symbols")
                .font(TacMapTypography.bodySmall)
                .foregroundColor(TacMapColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, TacMapSpacing.xxxl)
    }

    @ViewBuilder
    private func contentSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: TacMapSpacing.xs) {
            Text(title)
                .font(TacMapTypography.headlineSmall)
                .foregroundColor(TacMapColors.textSecondary)
                .padding(.horizontal, TacMapSpacing.md)

            content()
        }
    }
}

struct ContentRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: TacMapSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TacMapTypography.bodyMedium)
                    .foregroundColor(TacMapColors.textPrimary)
                Text(subtitle)
                    .font(TacMapTypography.captionSmall)
                    .foregroundColor(TacMapColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(TacMapColors.textTertiary)
        }
        .padding(.horizontal, TacMapSpacing.md)
        .padding(.vertical, TacMapSpacing.xs)
    }
}
