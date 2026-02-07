import UIKit
import SwiftUI

protocol MilitarySymbolRenderer {
    func render(symbol: SymbolDefinition, size: CGSize) -> UIImage
}

struct SymbolDefinition: Codable, Identifiable {
    let affiliation: Affiliation
    let unitType: UnitType
    let echelon: Echelon?
    var isPinned: Bool = false

    var id: String { "\(affiliation.rawValue)_\(unitType.rawValue)_\(echelon?.rawValue ?? "none")" }

    var displayName: String {
        var parts = [unitType.displayName]
        if let echelon { parts.append("(\(echelon.displayName))") }
        return parts.joined(separator: " ")
    }

    var abbreviation: String {
        "\(affiliation.symbolPrefix)-\(unitType.rawValue.prefix(3).uppercased())"
    }

    var category: SymbolCategory { unitType.category }
}

class SFSymbolRenderer: MilitarySymbolRenderer {
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 200
    }

    func render(symbol: SymbolDefinition, size: CGSize) -> UIImage {
        let key = "\(symbol.id)_\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let bgColor = uiColor(for: symbol.affiliation).withAlphaComponent(0.3)
            let borderColor = uiColor(for: symbol.affiliation)

            // Frame shape based on affiliation
            let path: UIBezierPath
            switch symbol.affiliation {
            case .friendly:
                path = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 4), cornerRadius: 4)
            case .hostile:
                path = diamondPath(in: rect.insetBy(dx: 2, dy: 2))
            case .neutral:
                path = UIBezierPath(rect: rect.insetBy(dx: 2, dy: 4))
            case .unknown:
                path = quatrefoilPath(in: rect.insetBy(dx: 2, dy: 2))
            }

            bgColor.setFill()
            path.fill()
            borderColor.setStroke()
            path.lineWidth = 2
            path.stroke()

            // SF Symbol icon
            let symbolName = symbol.unitType.sfSymbol
            let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.4, weight: .medium)
            if let sfImage = UIImage(systemName: symbolName, withConfiguration: config) {
                let tinted = sfImage.withTintColor(borderColor, renderingMode: .alwaysOriginal)
                let iconSize = tinted.size
                let iconRect = CGRect(
                    x: (size.width - iconSize.width) / 2,
                    y: (size.height - iconSize.height) / 2,
                    width: iconSize.width,
                    height: iconSize.height
                )
                tinted.draw(in: iconRect)
            }

            // Echelon indicator
            if let echelon = symbol.echelon {
                let echelonText = echelon.symbol as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size.width * 0.2, weight: .bold),
                    .foregroundColor: borderColor
                ]
                let textSize = echelonText.size(withAttributes: attrs)
                echelonText.draw(
                    at: CGPoint(x: (size.width - textSize.width) / 2, y: 0),
                    withAttributes: attrs
                )
            }
        }

        cache.setObject(image, forKey: key)
        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Helpers

    private func uiColor(for affiliation: Affiliation) -> UIColor {
        switch affiliation {
        case .friendly: return UIColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 1.0)
        case .hostile: return UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
        case .neutral: return UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        case .unknown: return UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
        }
    }

    private func diamondPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.close()
        return path
    }

    private func quatrefoilPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
        return path
    }
}
