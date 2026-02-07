import Foundation

enum UnitType: String, Codable, CaseIterable, Identifiable {
    case infantry
    case armor
    case artillery
    case cavalry
    case engineer
    case signal
    case medical
    case aviation
    case airDefense
    case supply
    case maintenance
    case reconnaissance
    case specialOperations
    case headquarters

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .infantry: return "Infantry"
        case .armor: return "Armor"
        case .artillery: return "Artillery"
        case .cavalry: return "Cavalry"
        case .engineer: return "Engineer"
        case .signal: return "Signal"
        case .medical: return "Medical"
        case .aviation: return "Aviation"
        case .airDefense: return "Air Defense"
        case .supply: return "Supply"
        case .maintenance: return "Maintenance"
        case .reconnaissance: return "Reconnaissance"
        case .specialOperations: return "Special Operations"
        case .headquarters: return "Headquarters"
        }
    }

    var sfSymbol: String {
        switch self {
        case .infantry: return "figure.walk"
        case .armor: return "shield.lefthalf.filled"
        case .artillery: return "scope"
        case .cavalry: return "hare"
        case .engineer: return "wrench.and.screwdriver"
        case .signal: return "antenna.radiowaves.left.and.right"
        case .medical: return "cross.case"
        case .aviation: return "airplane"
        case .airDefense: return "shield.checkered"
        case .supply: return "shippingbox"
        case .maintenance: return "wrench"
        case .reconnaissance: return "eye"
        case .specialOperations: return "bolt.shield"
        case .headquarters: return "star.circle"
        }
    }

    var category: SymbolCategory {
        switch self {
        case .infantry, .armor, .cavalry, .reconnaissance:
            return .maneuver
        case .artillery:
            return .fireSupport
        case .aviation:
            return .aviation
        case .engineer, .signal, .airDefense:
            return .combatSupport
        case .medical, .supply, .maintenance:
            return .combatServiceSupport
        case .specialOperations:
            return .specialOperations
        case .headquarters:
            return .commandControl
        }
    }
}

enum SymbolCategory: String, CaseIterable, Identifiable {
    case maneuver = "Maneuver"
    case fireSupport = "Fire Support"
    case aviation = "Aviation"
    case combatSupport = "Combat Support"
    case combatServiceSupport = "Combat Service Support"
    case specialOperations = "Special Operations"
    case commandControl = "Command & Control"

    var id: String { rawValue }
}
