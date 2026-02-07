import SwiftUI
import SwiftData
import MapboxMaps
import CoreLocation

struct MapContainerView: View {
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(DependencyContainer.self) private var dependencies
    @Environment(\.modelContext) private var modelContext

    @Query private var waypoints: [WaypointEntity]
    @Query private var symbols: [MilitarySymbolEntity]
    @Query private var routes: [RouteEntity]
    @Query private var graphics: [TacticalGraphicEntity]

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

            // MARK: - Waypoint Annotations
            if mapViewModel.showWaypoints {
                PointAnnotationGroup(waypoints, id: \.id) { wp in
                    PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: wp.latitude, longitude: wp.longitude))
                        .image(.init(image: waypointImage(for: wp), name: "wp-\(wp.icon)-\(wp.color)"))
                        .iconAnchor(.bottom)
                        .onTapGesture {
                            mapViewModel.selectedMarker = .waypoint(wp)
                        }
                }
                .iconAllowOverlap(true)
                .iconOffset(x: 0, y: 4)
            }

            // MARK: - Military Symbol Annotations
            if mapViewModel.showSymbols {
                PointAnnotationGroup(symbols, id: \.id) { sym in
                    PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: sym.latitude, longitude: sym.longitude))
                        .image(.init(image: symbolImage(for: sym), name: "sym-\(sym.symbolCode)-\(sym.affiliation)-\(sym.echelon ?? "none")"))
                        .onTapGesture {
                            mapViewModel.selectedMarker = .militarySymbol(sym)
                        }
                }
                .iconAllowOverlap(true)
            }

            // MARK: - Route Polylines
            if mapViewModel.showRoutes {
                PolylineAnnotationGroup(routes, id: \.id) { route in
                    var annotation = PolylineAnnotation(lineCoordinates: routeCoordinates(for: route))
                    annotation.lineColor = StyleColor(UIColor(hex: route.color))
                    annotation.lineWidth = route.lineWidth
                    annotation.lineJoin = .round
                    return annotation
                }
                .lineCap(.round)
            }

            // MARK: - Tactical Graphic Lines
            if mapViewModel.showGraphics {
                PolylineAnnotationGroup(lineGraphics, id: \.id) { graphic in
                    var annotation = PolylineAnnotation(lineCoordinates: graphicCoordinates(for: graphic))
                    annotation.lineColor = StyleColor(graphicUIColor(for: graphic))
                    annotation.lineWidth = 3.0
                    annotation.lineJoin = .round
                    return annotation
                }
                .lineCap(.round)

                // MARK: - Tactical Graphic Polygons
                PolygonAnnotationGroup(areaGraphics, id: \.id) { graphic in
                    let coords = closedRing(for: graphic)
                    var annotation = PolygonAnnotation(polygon: Polygon(outerRing: Ring(coordinates: coords)))
                    annotation.fillColor = StyleColor(graphicUIColor(for: graphic).withAlphaComponent(0.25))
                    annotation.fillOutlineColor = StyleColor(graphicUIColor(for: graphic))
                    return annotation
                }
            }
        }
        .mapStyle(mapStyle)
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(
                position: .topRight,
                margins: CGPoint(x: 16, y: 48)
            )
        ))
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

    // MARK: - Computed Filters

    private var lineGraphics: [TacticalGraphicEntity] {
        graphics.filter { !$0.graphicType.isArea }
    }

    private var areaGraphics: [TacticalGraphicEntity] {
        graphics.filter { $0.graphicType.isArea }
    }

    // MARK: - Image Helpers

    private func waypointImage(for wp: WaypointEntity) -> UIImage {
        let size = CGSize(width: 36, height: 44)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let pinColor = UIColor(hex: wp.color)

            // Pin body (circle)
            let bodyRect = CGRect(x: 2, y: 2, width: 32, height: 32)
            let path = UIBezierPath(ovalIn: bodyRect)
            pinColor.setFill()
            path.fill()

            // Pin point (triangle at bottom)
            let triangle = UIBezierPath()
            triangle.move(to: CGPoint(x: 12, y: 30))
            triangle.addLine(to: CGPoint(x: 18, y: 44))
            triangle.addLine(to: CGPoint(x: 24, y: 30))
            triangle.close()
            pinColor.setFill()
            triangle.fill()

            // Icon
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            if let sfImage = UIImage(systemName: wp.icon, withConfiguration: config) {
                let tinted = sfImage.withTintColor(.white, renderingMode: .alwaysOriginal)
                let iconSize = tinted.size
                let iconRect = CGRect(
                    x: (size.width - iconSize.width) / 2,
                    y: (32 - iconSize.height) / 2 + 2,
                    width: iconSize.width,
                    height: iconSize.height
                )
                tinted.draw(in: iconRect)
            }
        }
    }

    private func symbolImage(for sym: MilitarySymbolEntity) -> UIImage {
        let unitType = UnitType(rawValue: sym.symbolCode) ?? .infantry
        let definition = SymbolDefinition(
            affiliation: sym.affiliationEnum,
            unitType: unitType,
            echelon: sym.echelonEnum
        )
        return dependencies.symbolRenderer.render(symbol: definition, size: CGSize(width: 48, height: 48))
    }

    // MARK: - Coordinate Helpers

    private func routeCoordinates(for route: RouteEntity) -> [CLLocationCoordinate2D] {
        route.points.compactMap { point in
            guard point.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
    }

    private func graphicCoordinates(for graphic: TacticalGraphicEntity) -> [CLLocationCoordinate2D] {
        graphic.points.compactMap { point in
            guard point.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
    }

    private func closedRing(for graphic: TacticalGraphicEntity) -> [CLLocationCoordinate2D] {
        var coords = graphicCoordinates(for: graphic)
        guard coords.count >= 3 else { return coords }
        if let first = coords.first, let last = coords.last,
           first.latitude != last.latitude || first.longitude != last.longitude {
            coords.append(first)
        }
        return coords
    }

    private func graphicUIColor(for graphic: TacticalGraphicEntity) -> UIColor {
        if let hex = graphic.colorHex {
            return UIColor(hex: hex)
        }
        return UIColor(graphic.graphicType.defaultColor)
    }

    // MARK: - Map Style

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
