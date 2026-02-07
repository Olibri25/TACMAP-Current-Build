import SwiftUI
import UIKit

enum TacMapColors {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color(hex: "0D0D0F")
    static let backgroundSecondary = Color(hex: "1A1A1E")
    static let backgroundTertiary = Color(hex: "252529")
    static let backgroundElevated = Color(hex: "2C2C31")

    // MARK: - Surfaces
    static let surfaceOverlay = Color(hex: "1E1E22")
    static let surfaceTranslucent = Color(hex: "1E1E22").opacity(0.85)
    static let surfaceGlass = Color.white.opacity(0.08)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0A5")
    static let textTertiary = Color(hex: "6B6B70")
    static let textInverse = Color(hex: "0D0D0F")

    // MARK: - Accents
    static let accentPrimary = Color(hex: "FF6B35")
    static let accentSecondary = Color(hex: "3B9EFF")

    // MARK: - Affiliation (MIL-STD-2525D)
    static func affiliationColor(_ affiliation: Affiliation) -> Color {
        switch affiliation {
        case .friendly: return Color(hex: "80C0FF")
        case .hostile: return Color(hex: "FF8080")
        case .neutral: return Color(hex: "80FF80")
        case .unknown: return Color(hex: "FFFF80")
        }
    }

    static func affiliationFill(_ affiliation: Affiliation) -> Color {
        affiliationColor(affiliation).opacity(0.3)
    }

    // MARK: - Tactical Graphics
    static let phaseLine = Color(hex: "80C0FF")
    static let objective = Color(hex: "FF8080")
    static let assemblyArea = Color(hex: "80FF80")
    static let fireSupport = Color(hex: "FF6B35")
    static let danger = Color(hex: "FF3333")
    static let caution = Color(hex: "FFAA00")

    // MARK: - Semantic
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FF9800")
    static let error = Color(hex: "F44336")
    static let info = Color(hex: "2196F3")

    // MARK: - GPS Accuracy
    static let gpsAccurate = Color(hex: "4CAF50")
    static let gpsFair = Color(hex: "FF9800")
    static let gpsPoor = Color(hex: "F44336")
    static let gpsNone = Color(hex: "6B6B70")

    // MARK: - Map Overlays
    static let crosshair = Color.white
    static let gridLines = Color.white.opacity(0.4)
    static let contours = Color(hex: "8B7355")
    static let route = Color(hex: "3B9EFF")
    static let losVisible = Color(hex: "4CAF50")
    static let losBlocked = Color(hex: "F44336")

    // MARK: - Borders
    static let borderDefault = Color(hex: "3A3A3F")
    static let borderSubtle = Color(hex: "2A2A2F")
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
