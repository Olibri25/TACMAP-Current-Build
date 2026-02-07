import Foundation

enum TargetType: String, Codable, CaseIterable, Identifiable {
    case point
    case linear
    case area
    case groupOfTargets
    case series

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .point: return "Point"
        case .linear: return "Linear"
        case .area: return "Area"
        case .groupOfTargets: return "Group of Targets"
        case .series: return "Series"
        }
    }
}
