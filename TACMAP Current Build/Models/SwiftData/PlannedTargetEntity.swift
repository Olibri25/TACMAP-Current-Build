import Foundation
import SwiftData

@Model
class PlannedTargetEntity {
    var id: UUID = UUID()
    var targetNumber: String = ""
    var name: String = "Target"
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double?
    var targetDescription: String?
    var targetType: String = "point"
    var priority: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(targetNumber: String, name: String, latitude: Double, longitude: Double, targetType: TargetType = .point) {
        self.id = UUID()
        self.targetNumber = targetNumber
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.targetType = targetType.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }

    var targetTypeEnum: TargetType {
        TargetType(rawValue: targetType) ?? .point
    }
}
