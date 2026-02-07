import Foundation
import SwiftData

@Model
class TacticalGraphicEntity {
    var id: UUID = UUID()
    var graphicTypeRaw: String = "freeformLine"
    var name: String = "Graphic"
    var pointsData: Data = Data()
    var colorHex: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var folder: FolderEntity?
    var userId: String?
    var syncStatus: String = "local"

    init(name: String, graphicType: GraphicType, points: [[Double]]) {
        self.id = UUID()
        self.name = name
        self.graphicTypeRaw = graphicType.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
        if let data = try? JSONEncoder().encode(points) {
            self.pointsData = data
        }
    }

    var graphicType: GraphicType {
        GraphicType(rawValue: graphicTypeRaw) ?? .freeformLine
    }

    var points: [[Double]] {
        (try? JSONDecoder().decode([[Double]].self, from: pointsData)) ?? []
    }
}
