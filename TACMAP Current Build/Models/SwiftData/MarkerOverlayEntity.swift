import Foundation
import SwiftData

@Model
class MarkerOverlayEntity {
    var id: UUID = UUID()
    var markerId: UUID = UUID()
    var markerType: String = "waypoint"
    var configJSON: Data = Data()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    init(markerId: UUID, markerType: String, config: MarkerOverlayConfig? = nil) {
        self.id = UUID()
        self.markerId = markerId
        self.markerType = markerType
        self.updatedAt = Date()
        self.syncStatus = "local"
        if let config, let data = try? JSONEncoder().encode(config) {
            self.configJSON = data
        }
    }

    var config: MarkerOverlayConfig {
        get {
            (try? JSONDecoder().decode(MarkerOverlayConfig.self, from: configJSON)) ?? MarkerOverlayConfig()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                configJSON = data
            }
        }
    }
}

struct MarkerOverlayConfig: Codable {
    var rangeRings: RangeRingsConfig = RangeRingsConfig()
    var redCircle: REDCircleConfig = REDCircleConfig()
    var sectorOfFire: SectorOfFireConfig = SectorOfFireConfig()
}

struct RangeRingsConfig: Codable {
    var rings: [Double] = []
    var isVisible: Bool = false
}

struct REDCircleConfig: Codable {
    var radius: Double = 0
    var weaponSystem: String?
    var isVisible: Bool = false
}

struct SectorOfFireConfig: Codable {
    var direction: Double = 0
    var arcWidth: Double = 60
    var range: Double = 500
    var isVisible: Bool = false
}
