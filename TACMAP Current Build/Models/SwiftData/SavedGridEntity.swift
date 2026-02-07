import Foundation
import SwiftData

@Model
class SavedGridEntity {
    var id: UUID = UUID()
    var mgrsString: String = ""
    var zone: String = ""
    var square: String = ""
    var easting: String = ""
    var northing: String = ""
    var name: String?
    var isFavorite: Bool = false
    var lastUsedAt: Date = Date()
    var createdAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(mgrsString: String, zone: String, square: String, easting: String, northing: String, isFavorite: Bool = false, name: String? = nil) {
        self.id = UUID()
        self.mgrsString = mgrsString
        self.zone = zone
        self.square = square
        self.easting = easting
        self.northing = northing
        self.isFavorite = isFavorite
        self.name = name
        self.lastUsedAt = Date()
        self.createdAt = Date()
        self.syncStatus = "local"
    }
}
