import SwiftUI
import CoreLocation
import SwiftData
import Observation

enum QuickDropState {
    case collapsed
    case radialOpen
    case drawMode
    case symbolLibrary
}

enum QuickDropAction: String, CaseIterable {
    case marker
    case symbol
    case draw

    var icon: String {
        switch self {
        case .marker: return "mappin.circle.fill"
        case .symbol: return "shield.fill"
        case .draw: return "pencil.line"
        }
    }

    var label: String {
        switch self {
        case .marker: return "Marker"
        case .symbol: return "Symbol"
        case .draw: return "Draw"
        }
    }

    var color: Color {
        switch self {
        case .marker: return TacMapColors.accentPrimary
        case .symbol: return TacMapColors.accentSecondary
        case .draw: return TacMapColors.success
        }
    }
}

@Observable
class QuickDropManager {
    var state: QuickDropState = .collapsed
    var drawPoints: [CLLocationCoordinate2D] = []
    var selectedAction: QuickDropAction?

    func selectAction(_ action: QuickDropAction, mapViewModel: MapViewModel) {
        selectedAction = action
        switch action {
        case .marker:
            placeMarker(at: mapViewModel.centerCoordinate, mapViewModel: mapViewModel)
            state = .collapsed
        case .symbol:
            state = .symbolLibrary
        case .draw:
            state = .drawMode
            drawPoints = []
        }
    }

    func placeMarker(at coordinate: CLLocationCoordinate2D, mapViewModel: MapViewModel) {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        // Waypoint creation handled by caller with modelContext
    }

    // MARK: - Drawing

    func addDrawPoint(at coordinate: CLLocationCoordinate2D) {
        drawPoints.append(coordinate)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func undoLastPoint() {
        guard !drawPoints.isEmpty else { return }
        drawPoints.removeLast()
    }

    func completeDraw() -> [[Double]]? {
        guard drawPoints.count >= 2 else { return nil }
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        let points = drawPoints.map { [$0.latitude, $0.longitude] }
        drawPoints = []
        state = .collapsed
        return points
    }

    func cancelDraw() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
        drawPoints = []
        state = .collapsed
    }

    func toggle() {
        if state == .collapsed {
            state = .radialOpen
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } else {
            state = .collapsed
        }
    }
}
