import Foundation
import CoreLocation

enum DistanceCalculator {
    private static let earthRadius: Double = 6371000 // meters

    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        return earthRadius * c
    }

    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    static func destination(from: CLLocationCoordinate2D, bearing: Double, distance: Double) -> CLLocationCoordinate2D {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let brng = bearing * .pi / 180
        let d = distance / earthRadius

        let lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(brng))
        let lon2 = lon1 + atan2(sin(brng) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }

    static func routeDistance(points: [CLLocationCoordinate2D]) -> Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0
        for i in 0..<points.count-1 {
            total += distance(from: points[i], to: points[i+1])
        }
        return total
    }

    static func polygonArea(vertices: [CLLocationCoordinate2D]) -> Double {
        guard vertices.count >= 3 else { return 0 }
        var area: Double = 0
        let n = vertices.count
        for i in 0..<n {
            let j = (i + 1) % n
            area += vertices[i].longitude * vertices[j].latitude
            area -= vertices[j].longitude * vertices[i].latitude
        }
        area = abs(area) / 2.0
        let avgLat = vertices.map(\.latitude).reduce(0, +) / Double(n)
        let metersPerDegLat = 111320.0
        let metersPerDegLon = 111320.0 * cos(avgLat * .pi / 180)
        return area * metersPerDegLat * metersPerDegLon
    }

    static func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    static func formatBearing(_ degrees: Double) -> String {
        return String(format: "%03.0f\u{00B0}", degrees)
    }
}
