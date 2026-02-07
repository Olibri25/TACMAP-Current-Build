import Foundation
import SwiftData

@Model
class FolderEntity {
    var id: UUID = UUID()
    var name: String = "Folder"
    var color: String = "#FF6B35"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var userId: String?
    var syncStatus: String = "local"

    @Relationship(deleteRule: .cascade, inverse: \WaypointEntity.folder)
    var waypoints: [WaypointEntity]? = []

    @Relationship(deleteRule: .cascade, inverse: \PhotoEntity.folder)
    var photos: [PhotoEntity]? = []

    @Relationship(deleteRule: .cascade, inverse: \RouteEntity.folder)
    var routes: [RouteEntity]? = []

    @Relationship(deleteRule: .cascade, inverse: \TacticalGraphicEntity.folder)
    var graphics: [TacticalGraphicEntity]? = []

    init(name: String, color: String = "#FF6B35") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
    }
}
