import SwiftUI

struct QuickDropView: View {
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var manager = QuickDropManager()

    var body: some View {
        ZStack {
            switch manager.state {
            case .collapsed:
                // FAB
                fabButton

            case .radialOpen:
                // Radial menu
                radialMenu

            case .drawMode:
                // Draw toolbar
                drawToolbar

            case .symbolLibrary:
                EmptyView()
            }
        }
        .sheet(isPresented: Binding(
            get: { manager.state == .symbolLibrary },
            set: { if !$0 { manager.state = .collapsed } }
        )) {
            SymbolLibraryDrawer(onSymbolSelected: { definition in
                let symbol = MilitarySymbolEntity(
                    name: definition.displayName,
                    symbolCode: definition.id,
                    latitude: mapViewModel.centerCoordinate.latitude,
                    longitude: mapViewModel.centerCoordinate.longitude,
                    affiliation: definition.affiliation,
                    echelon: definition.echelon
                )
                modelContext.insert(symbol)
                manager.state = .collapsed
            })
        }
    }

    private var fabButton: some View {
        Button(action: { manager.toggle() }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(TacMapColors.textInverse)
                .frame(width: 56, height: 56)
                .background(TacMapColors.accentPrimary)
                .clipShape(Circle())
                .shadow(color: TacMapColors.accentPrimary.opacity(0.4), radius: 8, y: 4)
        }
    }

    private var radialMenu: some View {
        HStack(alignment: .bottom, spacing: TacMapSpacing.sm) {
            VStack(alignment: .trailing, spacing: TacMapSpacing.xs) {
                ForEach(Array(QuickDropAction.allCases.reversed()), id: \.rawValue) { action in
                    Button(action: {
                        if action == .marker {
                            let wp = WaypointEntity(
                                name: "Waypoint",
                                latitude: mapViewModel.centerCoordinate.latitude,
                                longitude: mapViewModel.centerCoordinate.longitude
                            )
                            modelContext.insert(wp)
                            let feedback = UINotificationFeedbackGenerator()
                            feedback.notificationOccurred(.success)
                            manager.state = .collapsed
                        } else {
                            manager.selectAction(action, mapViewModel: mapViewModel)
                        }
                    }) {
                        HStack(spacing: TacMapSpacing.xs) {
                            Image(systemName: action.icon)
                                .foregroundColor(action.color)
                            Text(action.label)
                                .font(TacMapTypography.labelMedium)
                                .foregroundColor(TacMapColors.textPrimary)
                        }
                        .padding(.horizontal, TacMapSpacing.sm)
                        .padding(.vertical, TacMapSpacing.xs)
                        .background(TacMapColors.backgroundElevated)
                        .clipShape(Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Close button — same size/position as FAB
            Button(action: { manager.state = .collapsed }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(TacMapColors.textInverse)
                    .frame(width: 56, height: 56)
                    .background(TacMapColors.accentPrimary)
                    .clipShape(Circle())
                    .shadow(color: TacMapColors.accentPrimary.opacity(0.4), radius: 8, y: 4)
            }
        }
        .animation(TacMapAnimation.bounce, value: manager.state == .radialOpen)
    }

    private var drawToolbar: some View {
        HStack(spacing: TacMapSpacing.sm) {
            // Undo
            Button(action: { manager.undoLastPoint() }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(TacMapColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(TacMapColors.backgroundElevated)
                    .clipShape(Circle())
            }
            .disabled(manager.drawPoints.isEmpty)

            // Point count
            Text("\(manager.drawPoints.count) pts")
                .font(TacMapTypography.monoSmall)
                .foregroundColor(TacMapColors.textSecondary)

            // Add point
            Button(action: {
                manager.addDrawPoint(at: mapViewModel.centerCoordinate)
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(TacMapColors.accentPrimary)
            }

            // Cancel
            Button(action: { manager.cancelDraw() }) {
                Image(systemName: "xmark")
                    .foregroundColor(TacMapColors.error)
                    .frame(width: 40, height: 40)
                    .background(TacMapColors.backgroundElevated)
                    .clipShape(Circle())
            }

            // Complete
            Button(action: {
                if let points = manager.completeDraw() {
                    let graphic = TacticalGraphicEntity(name: "Graphic", graphicType: .freeformLine, points: points)
                    modelContext.insert(graphic)
                }
            }) {
                Image(systemName: "checkmark")
                    .foregroundColor(TacMapColors.success)
                    .frame(width: 40, height: 40)
                    .background(TacMapColors.backgroundElevated)
                    .clipShape(Circle())
            }
            .disabled(manager.drawPoints.count < 2)
        }
        .padding(TacMapSpacing.sm)
        .background(TacMapColors.backgroundSecondary.opacity(0.95))
        .clipShape(Capsule())
    }
}
