import SwiftUI
import MapboxMaps
import CoreLocation

struct MapContainerView: View {
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var viewport: Viewport = .camera(center: CLLocationCoordinate2D(latitude: 39.0, longitude: -77.0), zoom: 14)

    var body: some View {
        ZStack {
            // Layer 1: Mapbox Map
            mapView
                .ignoresSafeArea()

            // Layer 2: Crosshair
            MapCrosshair()
        }
    }

    @ViewBuilder
    private var mapView: some View {
        Map(viewport: $viewport) {
            Puck2D(bearing: .heading)
        }
        .mapStyle(mapStyle)
        .onCameraChanged { event in
            mapViewModel.updateCamera(
                center: event.cameraState.center,
                zoom: event.cameraState.zoom,
                heading: event.cameraState.bearing,
                pitch: event.cameraState.pitch
            )
        }
        .additionalSafeAreaInsets(.bottom, 0)
        .onAppear {
            syncViewportFromViewModel()
        }
        .onChange(of: mapViewModel.mapMode) { _, _ in
            syncViewportFromViewModel()
        }
    }

    private var mapStyle: MapStyle {
        switch mapViewModel.mapMode {
        case .twoD:
            return mapViewModel.showSatellite ? .satellite : .dark
        case .threeD:
            return .satelliteStreets
        case .hybrid:
            return .outdoors
        }
    }

    private func syncViewportFromViewModel() {
        viewport = .camera(
            center: mapViewModel.centerCoordinate,
            zoom: mapViewModel.zoomLevel,
            bearing: mapViewModel.mapHeading,
            pitch: mapViewModel.mapPitch
        )
    }
}
