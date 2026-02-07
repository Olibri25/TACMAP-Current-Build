import Foundation
import CoreLocation

enum CoordinateConverter {
    // WGS84 constants
    private static let a: Double = 6378137.0
    private static let f: Double = 1.0 / 298.257223563
    private static let e2: Double = 2 * (1.0 / 298.257223563) - (1.0 / 298.257223563) * (1.0 / 298.257223563)
    private static let k0: Double = 0.9996

    // MARK: - MGRS

    static func toMGRS(_ coordinate: CLLocationCoordinate2D, precision: Int = 5) -> String {
        let utm = toUTM(coordinate)
        let latBand = mgrsLatBand(latitude: coordinate.latitude)
        let gridSquare = mgrsGridSquare(zone: utm.zone, easting: utm.easting, northing: utm.northing)
        let e = Int(utm.easting) % 100_000
        let n = Int(utm.northing) % 100_000

        let factor = Int(pow(10.0, Double(5 - precision)))
        let eStr = String(format: "%0\(precision)d", e / max(factor, 1))
        let nStr = String(format: "%0\(precision)d", n / max(factor, 1))

        return "\(utm.zone)\(latBand) \(gridSquare) \(eStr) \(nStr)"
    }

    static func fromMGRS(_ mgrs: String) -> CLLocationCoordinate2D? {
        let clean = mgrs.replacingOccurrences(of: " ", with: "").uppercased()
        guard clean.count >= 5 else { return nil }

        var idx = clean.startIndex
        // Parse zone number
        var zoneStr = ""
        while idx < clean.endIndex && clean[idx].isNumber {
            zoneStr.append(clean[idx])
            idx = clean.index(after: idx)
        }
        guard let zone = Int(zoneStr), zone >= 1, zone <= 60 else { return nil }

        // Parse lat band
        guard idx < clean.endIndex else { return nil }
        let latBand = clean[idx]
        idx = clean.index(after: idx)

        // Parse 100km grid square (2 letters)
        guard clean.distance(from: idx, to: clean.endIndex) >= 2 else { return nil }
        let col = clean[idx]
        idx = clean.index(after: idx)
        let row = clean[idx]
        idx = clean.index(after: idx)

        // Remaining digits split into easting/northing
        let digits = String(clean[idx...])
        guard digits.count % 2 == 0 else { return nil }
        let half = digits.count / 2
        guard half <= 5 else { return nil }

        let eStr = String(digits.prefix(half))
        let nStr = String(digits.suffix(half))

        guard let eVal = Int(eStr), let nVal = Int(nStr) else { return nil }
        let multiplier = Int(pow(10.0, Double(5 - half)))
        let easting100k = eVal * multiplier
        let northing100k = nVal * multiplier

        // Convert grid square to full UTM
        let colIndex = Int(col.asciiValue! - Character("A").asciiValue!)
        let setNumber = (zone - 1) % 6
        let colOrigin = (setNumber % 3) * 8 + 1
        var e100k = (colIndex - colOrigin + 1)
        if e100k < 0 { e100k += 24 }
        let fullEasting = Double(e100k * 100_000 + easting100k)

        let rowIndex = Int(row.asciiValue! - Character("A").asciiValue!)
        let rowOrigin = (setNumber % 2 == 0) ? 0 : 5
        var n100k = (rowIndex - rowOrigin)
        if n100k < 0 { n100k += 20 }

        let latBandMin = latBandMinNorthing(latBand)
        var fullNorthing = Double(n100k * 100_000 + northing100k)
        while fullNorthing < latBandMin {
            fullNorthing += 2_000_000
        }

        let utm = UTMCoordinate(zone: zone, hemisphere: coordinate.latitude >= 0 ? .north : .south, easting: fullEasting, northing: fullNorthing)
        return fromUTM(utm)
    }

    // MARK: - UTM

    struct UTMCoordinate {
        let zone: Int
        let hemisphere: Hemisphere
        let easting: Double
        let northing: Double

        enum Hemisphere { case north, south }
    }

    static func toUTM(_ coordinate: CLLocationCoordinate2D) -> UTMCoordinate {
        let lat = coordinate.latitude * .pi / 180
        let lon = coordinate.longitude * .pi / 180

        var zone = Int((coordinate.longitude + 180) / 6) + 1
        // Norway/Svalbard special zones
        if coordinate.latitude >= 56 && coordinate.latitude < 64 && coordinate.longitude >= 3 && coordinate.longitude < 12 {
            zone = 32
        }
        if coordinate.latitude >= 72 && coordinate.latitude < 84 {
            if coordinate.longitude >= 0 && coordinate.longitude < 9 { zone = 31 }
            else if coordinate.longitude >= 9 && coordinate.longitude < 21 { zone = 33 }
            else if coordinate.longitude >= 21 && coordinate.longitude < 33 { zone = 35 }
            else if coordinate.longitude >= 33 && coordinate.longitude < 42 { zone = 37 }
        }

        let lonOrigin = Double((zone - 1) * 6 - 180 + 3) * .pi / 180
        let ep2 = e2 / (1 - e2)

        let N = a / sqrt(1 - e2 * sin(lat) * sin(lat))
        let T = tan(lat) * tan(lat)
        let C = ep2 * cos(lat) * cos(lat)
        let A = cos(lat) * (lon - lonOrigin)
        let M = a * ((1 - e2/4 - 3*e2*e2/64 - 5*e2*e2*e2/256) * lat
            - (3*e2/8 + 3*e2*e2/32 + 45*e2*e2*e2/1024) * sin(2*lat)
            + (15*e2*e2/256 + 45*e2*e2*e2/1024) * sin(4*lat)
            - (35*e2*e2*e2/3072) * sin(6*lat))

        let easting = k0 * N * (A + (1-T+C)*A*A*A/6 + (5-18*T+T*T+72*C-58*ep2)*A*A*A*A*A/120) + 500000
        var northing = k0 * (M + N * tan(lat) * (A*A/2 + (5-T+9*C+4*C*C)*A*A*A*A/24 + (61-58*T+T*T+600*C-330*ep2)*A*A*A*A*A*A/720))

        if coordinate.latitude < 0 {
            northing += 10_000_000
        }

        return UTMCoordinate(zone: zone, hemisphere: coordinate.latitude >= 0 ? .north : .south, easting: easting, northing: northing)
    }

    static func fromUTM(_ utm: UTMCoordinate) -> CLLocationCoordinate2D {
        let ep2 = e2 / (1 - e2)
        let e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2))

        let x = utm.easting - 500000
        var y = utm.northing
        if utm.hemisphere == .south { y -= 10_000_000 }

        let lonOrigin = Double((utm.zone - 1) * 6 - 180 + 3)

        let M = y / k0
        let mu = M / (a * (1 - e2/4 - 3*e2*e2/64 - 5*e2*e2*e2/256))
        let phi1 = mu + (3*e1/2 - 27*e1*e1*e1/32) * sin(2*mu)
            + (21*e1*e1/16 - 55*e1*e1*e1*e1/32) * sin(4*mu)
            + (151*e1*e1*e1/96) * sin(6*mu)

        let N1 = a / sqrt(1 - e2 * sin(phi1) * sin(phi1))
        let T1 = tan(phi1) * tan(phi1)
        let C1 = ep2 * cos(phi1) * cos(phi1)
        let R1 = a * (1 - e2) / pow(1 - e2 * sin(phi1) * sin(phi1), 1.5)
        let D = x / (N1 * k0)

        let lat = phi1 - (N1 * tan(phi1) / R1) * (D*D/2 - (5+3*T1+10*C1-4*C1*C1-9*ep2)*D*D*D*D/24 + (61+90*T1+298*C1+45*T1*T1-252*ep2-3*C1*C1)*D*D*D*D*D*D/720)
        let lon = (D - (1+2*T1+C1)*D*D*D/6 + (5-2*C1+28*T1-3*C1*C1+8*ep2+24*T1*T1)*D*D*D*D*D/120) / cos(phi1)

        return CLLocationCoordinate2D(
            latitude: lat * 180 / .pi,
            longitude: lon * 180 / .pi + lonOrigin
        )
    }

    // MARK: - Formatting

    static func format(_ coordinate: CLLocationCoordinate2D, as format: CoordinateFormat) -> String {
        switch format {
        case .mgrs: return toMGRS(coordinate)
        case .utm:
            let utm = toUTM(coordinate)
            return "\(utm.zone)\(mgrsLatBand(latitude: coordinate.latitude)) \(Int(utm.easting)) \(Int(utm.northing))"
        case .decimalDegrees:
            return String(format: "%.6f\u{00B0} %@, %.6f\u{00B0} %@",
                          abs(coordinate.latitude), coordinate.latitude >= 0 ? "N" : "S",
                          abs(coordinate.longitude), coordinate.longitude >= 0 ? "E" : "W")
        case .degreesMinutesSeconds:
            return formatDMS(coordinate)
        }
    }

    static func formatDMS(_ coordinate: CLLocationCoordinate2D) -> String {
        func toDMS(_ value: Double, positive: String, negative: String) -> String {
            let abs = abs(value)
            let d = Int(abs)
            let mFull = (abs - Double(d)) * 60
            let m = Int(mFull)
            let s = (mFull - Double(m)) * 60
            let dir = value >= 0 ? positive : negative
            return String(format: "%d\u{00B0}%02d'%05.2f\"%@", d, m, s, dir)
        }
        return "\(toDMS(coordinate.latitude, positive: "N", negative: "S")) \(toDMS(coordinate.longitude, positive: "E", negative: "W"))"
    }

    // MARK: - Helpers

    private static func mgrsLatBand(latitude: Double) -> Character {
        let bands: [Character] = Array("CDEFGHJKLMNPQRSTUVWX")
        let idx = min(max(Int((latitude + 80) / 8), 0), bands.count - 1)
        return bands[idx]
    }

    private static func mgrsGridSquare(zone: Int, easting: Double, northing: Double) -> String {
        let setNumber = (zone - 1) % 6
        let colOrigin = (setNumber % 3) * 8 + 1
        let e100k = Int(easting / 100_000)
        let colLetter = Character(UnicodeScalar(Int(Character("A").asciiValue!) + (colOrigin + e100k - 1) % 24)!)

        let rowOrigin = (setNumber % 2 == 0) ? 0 : 5
        let n100k = Int(northing / 100_000) % 20
        var rowChar = rowOrigin + n100k
        if rowChar >= 20 { rowChar -= 20 }
        // Skip I and O
        var asciiVal = Int(Character("A").asciiValue!) + rowChar
        if asciiVal >= Int(Character("I").asciiValue!) { asciiVal += 1 }
        if asciiVal >= Int(Character("O").asciiValue!) { asciiVal += 1 }
        let rowLetter = Character(UnicodeScalar(asciiVal)!)

        return "\(colLetter)\(rowLetter)"
    }

    private static func latBandMinNorthing(_ band: Character) -> Double {
        let bandIndex = Int(band.asciiValue! - Character("C").asciiValue!)
        return Double(bandIndex) * 8.0 * 111_000
    }

    private static var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
