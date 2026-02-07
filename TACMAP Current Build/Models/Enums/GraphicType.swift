import SwiftUI

enum GraphicType: String, Codable, CaseIterable, Identifiable {
    case phaseLine
    case boundary
    case objective
    case assemblyArea
    case checkpoint
    case ambush
    case block
    case attackByFire
    case supportByFire
    case routeClear
    case routeSupply
    case freeformLine
    case freeformPolygon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .phaseLine: return "Phase Line"
        case .boundary: return "Boundary"
        case .objective: return "Objective"
        case .assemblyArea: return "Assembly Area"
        case .checkpoint: return "Checkpoint"
        case .ambush: return "Ambush"
        case .block: return "Block"
        case .attackByFire: return "Attack by Fire"
        case .supportByFire: return "Support by Fire"
        case .routeClear: return "Route (Clear)"
        case .routeSupply: return "Route (Supply)"
        case .freeformLine: return "Freeform Line"
        case .freeformPolygon: return "Freeform Polygon"
        }
    }

    var isArea: Bool {
        switch self {
        case .objective, .assemblyArea, .freeformPolygon: return true
        default: return false
        }
    }

    var defaultColor: Color {
        switch self {
        case .phaseLine, .boundary: return TacMapColors.phaseLine
        case .objective: return TacMapColors.objective
        case .assemblyArea: return TacMapColors.assemblyArea
        case .ambush, .block, .attackByFire, .supportByFire: return TacMapColors.danger
        case .checkpoint: return TacMapColors.accentPrimary
        case .routeClear, .routeSupply: return TacMapColors.route
        case .freeformLine, .freeformPolygon: return TacMapColors.accentSecondary
        }
    }
}
