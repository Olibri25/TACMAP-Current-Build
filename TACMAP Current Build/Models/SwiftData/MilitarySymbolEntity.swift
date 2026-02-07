import Foundation
import SwiftData

@Model
class MilitarySymbolEntity {
    var id: UUID = UUID()
    var symbolCode: String = ""
    var name: String = "Symbol"
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double?
    var affiliation: String = "friendly"
    var echelon: String?
    var modifier: String?
    var uniqueDesignator: String?
    var notes: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(name: String, symbolCode: String, latitude: Double, longitude: Double, affiliation: Affiliation, echelon: Echelon? = nil) {
        self.id = UUID()
        self.name = name
        self.symbolCode = symbolCode
        self.latitude = latitude
        self.longitude = longitude
        self.affiliation = affiliation.rawValue
        self.echelon = echelon?.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }

    var affiliationEnum: Affiliation {
        Affiliation(rawValue: affiliation) ?? .unknown
    }

    var echelonEnum: Echelon? {
        guard let echelon else { return nil }
        return Echelon(rawValue: echelon)
    }
}
