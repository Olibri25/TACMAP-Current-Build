import Foundation
import SwiftData

@Model
class WaypointEntity {
    var id: UUID = UUID()
    var name: String = "Waypoint"
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double?
    var notes: String?
    var color: String = "#FF6B35"
    var icon: String = "mappin"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var folder: FolderEntity?
    var userId: String?
    var syncStatus: String = "local"

    init(name: String, latitude: Double, longitude: Double, altitude: Double? = nil, color: String = "#FF6B35", icon: String = "mappin") {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }
}
