import Foundation
import SwiftData

@Model
class FireMissionEntity {
    var id: UUID = UUID()
    var missionNumber: String = ""
    var targetId: UUID?
    var weaponSystem: String = "fieldArtillery"
    var ammoType: String?
    var volume: Int = 1
    var method: String?
    var status: String = "planned"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(missionNumber: String, weaponSystem: WeaponSystem, targetId: UUID? = nil) {
        self.id = UUID()
        self.missionNumber = missionNumber
        self.weaponSystem = weaponSystem.rawValue
        self.targetId = targetId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }
}
