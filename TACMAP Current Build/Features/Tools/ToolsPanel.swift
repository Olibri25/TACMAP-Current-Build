import SwiftUI

struct ToolsPanel: View {
    @Environment(MapViewModel.self) private var mapViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TacMapSpacing.md) {
                Text("Tools")
                    .font(TacMapTypography.headlineLarge)
                    .foregroundColor(TacMapColors.textPrimary)
                    .padding(.horizontal, TacMapSpacing.md)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: TacMapSpacing.sm) {
                    ToolCard(icon: TacMapIcons.goToGrid, title: "Go To Grid") {
                        mapViewModel.isShowingGoToGrid = true
                    }
                    ToolCard(icon: TacMapIcons.ruler, title: "Measure") {
                        // Measure tool
                    }
                    ToolCard(icon: TacMapIcons.target, title: "Targets") {
                        // Target planning
                    }
                    ToolCard(icon: "line.diagonal", title: "Draw") {
                        // Draw mode
                    }
                    ToolCard(icon: "circle.dashed", title: "Range Ring") {
                        // Range ring tool
                    }
                    ToolCard(icon: TacMapIcons.layers, title: "Layers") {
                        mapViewModel.isShowingLayerPanel = true
                    }
                }
                .padding(.horizontal, TacMapSpacing.md)
            }
            .padding(.top, TacMapSpacing.sm)
        }
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: TacMapSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: TacMapIcons.sizeLarge))
                    .foregroundColor(TacMapColors.accentPrimary)

                Text(title)
                    .font(TacMapTypography.labelSmall)
                    .foregroundColor(TacMapColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TacMapSpacing.sm)
            .background(TacMapColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
