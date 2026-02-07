import Foundation

enum Echelon: String, Codable, CaseIterable, Identifiable {
    case team
    case squad
    case section
    case platoon
    case company
    case battalion
    case brigade

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var symbol: String {
        switch self {
        case .team: return "\u{00D8}"      // Ø
        case .squad: return "\u{2022}"     // •
        case .section: return "\u{2022}\u{2022}"   // ••
        case .platoon: return "\u{2022}\u{2022}\u{2022}" // •••
        case .company: return "I"
        case .battalion: return "II"
        case .brigade: return "X"
        }
    }
}
