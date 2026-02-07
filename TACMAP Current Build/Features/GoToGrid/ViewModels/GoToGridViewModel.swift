import SwiftUI
import CoreLocation
import SwiftData
import Observation

@Observable
class GoToGridViewModel {
    // MARK: - Input Fields
    var zone: String = ""
    var square: String = ""
    var easting: String = ""
    var northing: String = ""

    // MARK: - Focus
    enum Field: Int, CaseIterable {
        case zone, square, easting, northing
    }
    var focusedField: Field? = .easting

    // MARK: - Default zone/square from current location
    var defaultZone: String = "18T"
    var defaultSquare: String = "WL"

    // MARK: - Validation
    var isValid: Bool {
        let z = zone.isEmpty ? defaultZone : zone
        let s = square.isEmpty ? defaultSquare : square
        let e = easting
        let n = northing
        guard z.count >= 2, s.count == 2, !e.isEmpty, !n.isEmpty else { return false }
        guard e.allSatisfy(\.isNumber), n.allSatisfy(\.isNumber) else { return false }
        return true
    }

    var fullMGRS: String {
        let z = zone.isEmpty ? defaultZone : zone
        let s = square.isEmpty ? defaultSquare : square
        return "\(z)\(s)\(easting)\(northing)"
    }

    var displayMGRS: String {
        let z = zone.isEmpty ? defaultZone : zone
        let s = square.isEmpty ? defaultSquare : square
        return "\(z) \(s) \(easting) \(northing)"
    }

    // MARK: - Navigation

    func targetCoordinate() -> CLLocationCoordinate2D? {
        guard isValid else { return nil }
        return CoordinateConverter.fromMGRS(fullMGRS)
    }

    func navigateToGrid(mapViewModel: MapViewModel, modelContext: ModelContext) -> Bool {
        guard let coord = targetCoordinate() else {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            return false
        }

        // Save as recent
        let recent = SavedGridEntity(
            mgrsString: fullMGRS,
            zone: zone.isEmpty ? defaultZone : zone,
            square: square.isEmpty ? defaultSquare : square,
            easting: easting,
            northing: northing,
            isFavorite: false
        )
        modelContext.insert(recent)

        // Trim to 20 recents
        trimRecents(modelContext: modelContext)

        // Jump
        let targetZoom = mapViewModel.zoomLevel < 10 ? 14.0 : mapViewModel.zoomLevel
        mapViewModel.navigateToCoordinate(coord, zoom: targetZoom)

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        return true
    }

    func saveFavorite(name: String, modelContext: ModelContext) {
        guard isValid else { return }
        let fav = SavedGridEntity(
            mgrsString: fullMGRS,
            zone: zone.isEmpty ? defaultZone : zone,
            square: square.isEmpty ? defaultSquare : square,
            easting: easting,
            northing: northing,
            isFavorite: true,
            name: name.isEmpty ? nil : name
        )
        modelContext.insert(fav)
    }

    // MARK: - Keyboard Input

    func handleKeyInput(_ key: String) {
        guard let field = focusedField else { return }
        switch field {
        case .zone:
            if zone.count < 3 { zone += key }
            if zone.count >= 3 { focusedField = .square }
        case .square:
            if square.count < 2 { square += key.uppercased() }
            if square.count >= 2 { focusedField = .easting }
        case .easting:
            if easting.count < 5 { easting += key }
            if easting.count >= 4 && easting.count < 5 {
                // Auto-advance at 4, 5th digit is manual
            }
            if easting.count >= 4 { focusedField = .northing }
        case .northing:
            if northing.count < 5 { northing += key }
        }
    }

    func handleBackspace() {
        guard let field = focusedField else { return }
        switch field {
        case .zone:
            if !zone.isEmpty { zone.removeLast() }
        case .square:
            if !square.isEmpty { square.removeLast() }
            else { focusedField = .zone }
        case .easting:
            if !easting.isEmpty { easting.removeLast() }
            else { focusedField = .square }
        case .northing:
            if !northing.isEmpty { northing.removeLast() }
            else { focusedField = .easting }
        }
    }

    func advanceField() {
        guard let current = focusedField, let nextIdx = Field(rawValue: current.rawValue + 1) else { return }
        focusedField = nextIdx
    }

    func clear() {
        zone = ""
        square = ""
        easting = ""
        northing = ""
        focusedField = .easting
    }

    func updateDefaults(from location: CLLocationCoordinate2D) {
        let mgrs = CoordinateConverter.toMGRS(location, precision: 5)
        let parts = mgrs.split(separator: " ")
        if parts.count >= 2 {
            defaultZone = String(parts[0].prefix(parts[0].count - 2) + parts[0].suffix(2).prefix(1))
            // Actually parse zone and square from MGRS
            let clean = mgrs.replacingOccurrences(of: " ", with: "")
            if clean.count >= 5 {
                var idx = clean.startIndex
                var zStr = ""
                while idx < clean.endIndex && clean[idx].isNumber {
                    zStr.append(clean[idx])
                    idx = clean.index(after: idx)
                }
                if idx < clean.endIndex {
                    zStr.append(clean[idx]) // lat band
                    idx = clean.index(after: idx)
                }
                defaultZone = zStr
                if clean.distance(from: idx, to: clean.endIndex) >= 2 {
                    let sq1 = clean[idx]
                    idx = clean.index(after: idx)
                    let sq2 = clean[idx]
                    defaultSquare = "\(sq1)\(sq2)"
                }
            }
        }
    }

    private func trimRecents(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SavedGridEntity>(
            predicate: #Predicate { !$0.isFavorite },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        if let recents = try? modelContext.fetch(descriptor), recents.count > 20 {
            for grid in recents.dropFirst(20) {
                modelContext.delete(grid)
            }
        }
    }
}
