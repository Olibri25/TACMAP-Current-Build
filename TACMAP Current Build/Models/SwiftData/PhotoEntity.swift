import Foundation
import SwiftData

@Model
class PhotoEntity {
    var id: UUID = UUID()
    var fileName: String = ""
    var caption: String?
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var bearing: Double?
    var createdAt: Date = Date()
    var folder: FolderEntity?
    var userId: String?
    var syncStatus: String = "local"

    init(fileName: String) {
        self.id = UUID()
        self.fileName = fileName
        self.createdAt = Date()
        self.syncStatus = "local"
    }
}
