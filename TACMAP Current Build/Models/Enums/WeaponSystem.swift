import Foundation

enum WeaponSystem: String, Codable, CaseIterable, Identifiable {
    case mortars
    case fieldArtillery
    case mlrs = "MLRS"
    case himars = "HIMARS"
    case ngf = "NGF"
    case cas = "CAS"
    case ac130 = "AC130"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mortars: return "Mortars (60/81/120mm)"
        case .fieldArtillery: return "Field Artillery (105/155mm)"
        case .mlrs: return "MLRS"
        case .himars: return "HIMARS"
        case .ngf: return "Naval Gunfire"
        case .cas: return "Close Air Support"
        case .ac130: return "AC-130"
        }
    }

    var maxRangeMeters: Double {
        switch self {
        case .mortars: return 7_200
        case .fieldArtillery: return 30_000
        case .mlrs: return 70_000
        case .himars: return 300_000
        case .ngf: return 38_000
        case .cas: return 0
        case .ac130: return 0
        }
    }

    var redRadiusMeters: Double {
        switch self {
        case .mortars: return 100
        case .fieldArtillery: return 200
        case .mlrs: return 400
        case .himars: return 200
        case .ngf: return 250
        case .cas: return 300
        case .ac130: return 150
        }
    }
}
