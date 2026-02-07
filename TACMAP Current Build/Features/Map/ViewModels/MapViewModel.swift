import SwiftUI
import CoreLocation
import Observation

@Observable
class MapViewModel {
    // MARK: - Camera State
    var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 39.0, longitude: -77.0)
    var zoomLevel: Double = 14.0
    var mapHeading: Double = 0
    var mapPitch: Double = 0

    // MARK: - Map Mode
    var mapMode: MapMode = .twoD
    var terrainExaggeration: Double = 1.5

    // MARK: - Following
    var isFollowingLocation: Bool = true

    // MARK: - Layer Toggles
    var showSatellite: Bool = true
    var showTerrain: Bool = true
    var showStreets: Bool = false
    var showMGRSGrid: Bool = true
    var showElevationContours: Bool = false

    // MARK: - Annotation Toggles
    var showWaypoints: Bool = true
    var showRoutes: Bool = true
    var showSymbols: Bool = true
    var showGraphics: Bool = true
    var showTargets: Bool = true
    var showRangeRings: Bool = true

    // MARK: - Selection
    var selectedMarker: MarkerSelection?
    var isShowingLayerPanel: Bool = false
    var isShowingGoToGrid: Bool = false

    // MARK: - Elevation
    var centerElevation: Double?

    // MARK: - MGRS Display
    var centerMGRS: String {
        CoordinateConverter.toMGRS(centerCoordinate)
    }

    // MARK: - Camera Throttle
    private var lastCameraUpdate: Date = .distantPast
    private let cameraThrottleInterval: TimeInterval = 0.066 // ~15fps
    private var pendingCameraUpdate: Task<Void, Never>?

    // MARK: - Computed
    var mapStyleURI: String {
        switch mapMode {
        case .twoD: return showSatellite ? "mapbox://styles/mapbox/satellite-v9" : "mapbox://styles/mapbox/dark-v11"
        case .threeD: return "mapbox://styles/mapbox/satellite-streets-v12"
        case .hybrid: return "mapbox://styles/mapbox/outdoors-v12"
        }
    }

    var metersPerPixel: Double {
        156543.03392 * cos(centerCoordinate.latitude * .pi / 180) / pow(2.0, zoomLevel)
    }

    // MARK: - Navigation

    func navigateToCoordinate(_ coordinate: CLLocationCoordinate2D, zoom: Double? = nil) {
        centerCoordinate = coordinate
        if let zoom { zoomLevel = zoom }
        isFollowingLocation = false
    }

    func centerOnLocation(_ location: CLLocation) {
        centerCoordinate = location.coordinate
        isFollowingLocation = true
    }

    func resetNorth() {
        mapHeading = 0
    }

    func cycleMapMode() {
        mapMode = mapMode.next
    }

    // MARK: - Camera Updates (trailing-edge debounce)

    func updateCamera(center: CLLocationCoordinate2D, zoom: Double, heading: Double, pitch: Double) {
        let now = Date()
        if now.timeIntervalSince(lastCameraUpdate) >= cameraThrottleInterval {
            applyCameraUpdate(center: center, zoom: zoom, heading: heading, pitch: pitch)
        } else {
            pendingCameraUpdate?.cancel()
            pendingCameraUpdate = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(66))
                guard !Task.isCancelled else { return }
                self?.applyCameraUpdate(center: center, zoom: zoom, heading: heading, pitch: pitch)
            }
        }
    }

    private func applyCameraUpdate(center: CLLocationCoordinate2D, zoom: Double, heading: Double, pitch: Double) {
        lastCameraUpdate = Date()
        centerCoordinate = center
        zoomLevel = zoom
        mapHeading = heading
        mapPitch = pitch
    }

    // MARK: - Waypoint Placement

    func placeWaypoint(at coordinate: CLLocationCoordinate2D, name: String = "Waypoint") -> WaypointEntity {
        let waypoint = WaypointEntity(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        return waypoint
    }

    // MARK: - Check follow distance

    func checkFollowDistance(userLocation: CLLocation?) {
        guard isFollowingLocation, let userLocation else { return }
        let mapLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        if mapLocation.distance(from: userLocation) > 50 {
            isFollowingLocation = false
        }
    }
}

// MARK: - Marker Selection

enum MarkerSelection: Identifiable {
    case waypoint(WaypointEntity)
    case militarySymbol(MilitarySymbolEntity)

    var id: UUID {
        switch self {
        case .waypoint(let w): return w.id
        case .militarySymbol(let s): return s.id
        }
    }

    var name: String {
        switch self {
        case .waypoint(let w): return w.name
        case .militarySymbol(let s): return s.name
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .waypoint(let w): return CLLocationCoordinate2D(latitude: w.latitude, longitude: w.longitude)
        case .militarySymbol(let s): return CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
        }
    }

    var iconName: String {
        switch self {
        case .waypoint(let w): return w.icon
        case .militarySymbol: return "shield.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .waypoint(let w): return Color(hex: w.color)
        case .militarySymbol(let s): return s.affiliationEnum.color
        }
    }

    var notes: String? {
        switch self {
        case .waypoint(let w): return w.notes
        case .militarySymbol(let s): return s.notes
        }
    }

    var mgrsGrid: String {
        CoordinateConverter.toMGRS(coordinate)
    }

    var markerType: String {
        switch self {
        case .waypoint: return "waypoint"
        case .militarySymbol: return "symbol"
        }
    }
}
