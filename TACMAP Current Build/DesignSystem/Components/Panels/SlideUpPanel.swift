import SwiftUI

enum PanelDetent: Equatable {
    case hidden
    case partial
    case expanded

    var fraction: CGFloat {
        switch self {
        case .hidden: return 0
        case .partial: return 0.35
        case .expanded: return 0.65
        }
    }
}

struct SlideUpPanel<Content: View>: View {
    @Binding var detent: PanelDetent
    let content: () -> Content

    @State private var dragOffset: CGFloat = 0
    private let velocityThreshold: CGFloat = 500

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height - geometry.safeAreaInsets.top
            let panelHeight = maxHeight * detent.fraction

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    dragHandle

                    // Content
                    content()
                        .frame(maxWidth: .infinity)
                }
                .frame(height: max(panelHeight + dragOffset, 0))
                .background(TacMapColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.panelCornerRadius, style: .continuous))
                .gesture(panelDragGesture(maxHeight: maxHeight))
            }
            .animation(TacMapAnimation.panel, value: detent)
        }
    }

    private var dragHandle: some View {
        VStack(spacing: TacMapSpacing.xs) {
            Capsule()
                .fill(TacMapColors.textTertiary)
                .frame(width: 36, height: 5)
                .padding(.top, TacMapSpacing.xs)
        }
    }

    private func panelDragGesture(maxHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = -value.translation.height
            }
            .onEnded { value in
                let velocity = -value.predictedEndTranslation.height / max(value.time.timeIntervalSinceNow, 0.001)
                dragOffset = 0

                if velocity > velocityThreshold {
                    // Swipe up - expand
                    expandOneLevel()
                } else if velocity < -velocityThreshold {
                    // Swipe down - collapse
                    collapseOneLevel()
                } else {
                    // Snap to nearest detent
                    let currentHeight = maxHeight * detent.fraction - value.translation.height
                    let currentFraction = currentHeight / maxHeight
                    snapToNearest(fraction: currentFraction)
                }
            }
    }

    private func expandOneLevel() {
        switch detent {
        case .hidden: detent = .partial
        case .partial: detent = .expanded
        case .expanded: break
        }
    }

    private func collapseOneLevel() {
        switch detent {
        case .expanded: detent = .partial
        case .partial: detent = .hidden
        case .hidden: break
        }
    }

    private func snapToNearest(fraction: CGFloat) {
        let detents: [PanelDetent] = [.hidden, .partial, .expanded]
        let nearest = detents.min(by: { abs($0.fraction - fraction) < abs($1.fraction - fraction) })!
        detent = nearest
    }
}
