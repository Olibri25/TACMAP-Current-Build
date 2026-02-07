import Foundation
import SwiftData

@Model
class ObservationPostEntity {
    var id: UUID = UUID()
    var name: String = "OP"
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double?
    var observerId: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(name: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }
}
