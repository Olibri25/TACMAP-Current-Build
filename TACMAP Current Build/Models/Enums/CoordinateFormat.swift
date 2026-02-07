import Foundation

enum CoordinateFormat: String, Codable, CaseIterable, Identifiable {
    case mgrs
    case utm
    case decimalDegrees
    case degreesMinutesSeconds

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mgrs: return "MGRS"
        case .utm: return "UTM"
        case .decimalDegrees: return "DD"
        case .degreesMinutesSeconds: return "DMS"
        }
    }

    var example: String {
        switch self {
        case .mgrs: return "18T WL 12345 67890"
        case .utm: return "18T 512345 4367890"
        case .decimalDegrees: return "39.4567\u{00B0} N, 77.1234\u{00B0} W"
        case .degreesMinutesSeconds: return "39\u{00B0}27'24\"N 77\u{00B0}07'24\"W"
        }
    }
}
