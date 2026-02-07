import Foundation
import Observation

@Observable
class AppSettings {
    // MARK: - Units
    var distanceUnit: String = "m" { didSet { scheduleSave() } }
    var speedUnit: String = "km/h" { didSet { scheduleSave() } }
    var elevationUnit: String = "m" { didSet { scheduleSave() } }
    var temperatureUnit: String = "F" { didSet { scheduleSave() } }

    // MARK: - Coordinates
    var coordinateFormat: CoordinateFormat = .mgrs { didSet { scheduleSave() } }

    // MARK: - Map
    var defaultMapMode: MapMode = .twoD { didSet { scheduleSave() } }
    var defaultGridOverlay: Bool = true { didSet { scheduleSave() } }
    var contourInterval: Int = 20 { didSet { scheduleSave() } }
    var northReference: String = "true" { didSet { scheduleSave() } }
    var magneticDeclination: Double = 0 { didSet { scheduleSave() } }
    var autoMagneticDeclination: Bool = true { didSet { scheduleSave() } }

    // MARK: - Display
    var symbolSize: String = "medium" { didSet { scheduleSave() } }
    var labelSize: String = "medium" { didSet { scheduleSave() } }
    var show3DBuildings: Bool = false { didSet { scheduleSave() } }
    var showContourLines: Bool = true { didSet { scheduleSave() } }
    var showHillshade: Bool = true { didSet { scheduleSave() } }

    // MARK: - GPS
    var gpsUpdateFrequency: String = "normal" { didSet { scheduleSave() } }
    var showAccuracyCircle: Bool = true { didSet { scheduleSave() } }

    var symbolSizePoints: CGFloat {
        switch symbolSize {
        case "small": return 24
        case "large": return 48
        default: return 36
        }
    }

    var gpsDistanceFilter: Double {
        switch gpsUpdateFrequency {
        case "fast": return 1
        case "batterySaver": return 10
        default: return 5
        }
    }

    // MARK: - Persistence
    private var saveTask: Task<Void, Never>?

    init() {
        load()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.performSave()
        }
    }

    func saveNow() {
        saveTask?.cancel()
        performSave()
    }

    private func performSave() {
        let defaults = UserDefaults.standard
        defaults.set(distanceUnit, forKey: "distanceUnit")
        defaults.set(speedUnit, forKey: "speedUnit")
        defaults.set(elevationUnit, forKey: "elevationUnit")
        defaults.set(temperatureUnit, forKey: "temperatureUnit")
        defaults.set(coordinateFormat.rawValue, forKey: "coordinateFormat")
        defaults.set(defaultMapMode.rawValue, forKey: "defaultMapMode")
        defaults.set(defaultGridOverlay, forKey: "defaultGridOverlay")
        defaults.set(contourInterval, forKey: "contourInterval")
        defaults.set(symbolSize, forKey: "symbolSize")
        defaults.set(labelSize, forKey: "labelSize")
        defaults.set(show3DBuildings, forKey: "show3DBuildings")
        defaults.set(showContourLines, forKey: "showContourLines")
        defaults.set(showHillshade, forKey: "showHillshade")
        defaults.set(gpsUpdateFrequency, forKey: "gpsUpdateFrequency")
        defaults.set(showAccuracyCircle, forKey: "showAccuracyCircle")
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let v = defaults.string(forKey: "distanceUnit") { distanceUnit = v }
        if let v = defaults.string(forKey: "speedUnit") { speedUnit = v }
        if let v = defaults.string(forKey: "elevationUnit") { elevationUnit = v }
        if let v = defaults.string(forKey: "temperatureUnit") { temperatureUnit = v }
        if let v = defaults.string(forKey: "coordinateFormat"), let f = CoordinateFormat(rawValue: v) { coordinateFormat = f }
        if let v = defaults.string(forKey: "defaultMapMode"), let m = MapMode(rawValue: v) { defaultMapMode = m }
        defaultGridOverlay = defaults.object(forKey: "defaultGridOverlay") as? Bool ?? true
        if defaults.object(forKey: "contourInterval") != nil { contourInterval = defaults.integer(forKey: "contourInterval") }
        if let v = defaults.string(forKey: "symbolSize") { symbolSize = v }
        if let v = defaults.string(forKey: "labelSize") { labelSize = v }
        show3DBuildings = defaults.bool(forKey: "show3DBuildings")
        showContourLines = defaults.object(forKey: "showContourLines") as? Bool ?? true
        showHillshade = defaults.object(forKey: "showHillshade") as? Bool ?? true
        if let v = defaults.string(forKey: "gpsUpdateFrequency") { gpsUpdateFrequency = v }
        showAccuracyCircle = defaults.object(forKey: "showAccuracyCircle") as? Bool ?? true
    }

    func resetToDefaults() {
        distanceUnit = "m"
        speedUnit = "km/h"
        elevationUnit = "m"
        temperatureUnit = "F"
        coordinateFormat = .mgrs
        defaultMapMode = .twoD
        defaultGridOverlay = true
        contourInterval = 20
        symbolSize = "medium"
        labelSize = "medium"
        show3DBuildings = false
        showContourLines = true
        showHillshade = true
        gpsUpdateFrequency = "normal"
        showAccuracyCircle = true
        saveNow()
    }
}
