import Foundation
import CoreLocation
import Observation

enum GPSAccuracy: String {
    case accurate, fair, poor, none

    init(horizontalAccuracy: Double) {
        switch horizontalAccuracy {
        case ..<10: self = .accurate
        case ..<30: self = .fair
        case ..<100: self = .poor
        default: self = .none
        }
    }
}

@Observable
class LocationService: NSObject {
    var currentLocation: CLLocation?
    var heading: CLHeading?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var accuracy: GPSAccuracy = .none
    var isUpdating: Bool = false
    var isAcquiring: Bool = false

    private let locationManager = CLLocationManager()
    private var hasStarted = false
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?

    var locationStream: AsyncStream<CLLocation> {
        AsyncStream { [weak self] continuation in
            self?.locationContinuation = continuation
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        isAcquiring = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        isUpdating = true
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isUpdating = false
        hasStarted = false
        locationContinuation?.finish()
    }

    func setUpdateFrequency(distanceFilter: Double) {
        locationManager.distanceFilter = distanceFilter
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        accuracy = GPSAccuracy(horizontalAccuracy: location.horizontalAccuracy)
        isAcquiring = false
        locationContinuation?.yield(location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if hasStarted {
                manager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        accuracy = .none
    }
}
