import Foundation

enum MapMode: String, Codable, CaseIterable {
    case twoD
    case threeD
    case hybrid

    var is3DEnabled: Bool {
        self == .threeD
    }

    var showContours: Bool {
        self == .hybrid
    }

    var next: MapMode {
        switch self {
        case .twoD: return .threeD
        case .threeD: return .hybrid
        case .hybrid: return .twoD
        }
    }

    var displayName: String {
        switch self {
        case .twoD: return "2D"
        case .threeD: return "3D"
        case .hybrid: return "Topo"
        }
    }

    var iconName: String {
        switch self {
        case .twoD: return "map"
        case .threeD: return "cube"
        case .hybrid: return "mountain.2"
        }
    }
}
