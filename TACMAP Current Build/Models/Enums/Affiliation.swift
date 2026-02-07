import SwiftUI

enum Affiliation: String, Codable, CaseIterable, Identifiable {
    case friendly
    case hostile
    case neutral
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .hostile: return "Hostile"
        case .neutral: return "Neutral"
        case .unknown: return "Unknown"
        }
    }

    var symbolPrefix: String {
        switch self {
        case .friendly: return "F"
        case .hostile: return "H"
        case .neutral: return "N"
        case .unknown: return "U"
        }
    }

    var color: Color {
        TacMapColors.affiliationColor(self)
    }

    var fillColor: Color {
        TacMapColors.affiliationFill(self)
    }
}
