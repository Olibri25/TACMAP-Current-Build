import Foundation
import SwiftData

@Model
class RouteEntity {
    var id: UUID = UUID()
    var name: String = "Route"
    var routeType: String = "standard"
    var color: String = "#3B9EFF"
    var lineWidth: Double = 3.0
    var notes: String?
    var pointsData: Data = Data()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var folder: FolderEntity?
    var userId: String?
    var syncStatus: String = "local"

    init(name: String, points: [[Double]]) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = "local"
        if let data = try? JSONEncoder().encode(points) {
            self.pointsData = data
        }
    }

    var points: [[Double]] {
        (try? JSONDecoder().decode([[Double]].self, from: pointsData)) ?? []
    }
}
