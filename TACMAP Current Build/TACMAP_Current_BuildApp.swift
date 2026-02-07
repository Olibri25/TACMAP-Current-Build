import SwiftUI
import SwiftData
import MapboxMaps

@main
struct TacMapApp: App {
    @State private var mapViewModel = MapViewModel()
    @State private var locationService = LocationService()
    @State private var settings = AppSettings()
    @State private var container = DependencyContainer()

    init() {
        setupMapbox()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(mapViewModel)
                .environment(locationService)
                .environment(settings)
                .environment(container)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Mapbox Setup

    private func setupMapbox() {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String,
              token.hasPrefix("pk.") else {
            fatalError("Missing or invalid Mapbox access token in Info.plist. Token must start with 'pk.'")
        }
        MapboxOptions.accessToken = token
    }

    // MARK: - SwiftData Container

    private var sharedModelContainer: ModelContainer {
        let schema = Schema([
            WaypointEntity.self,
            RouteEntity.self,
            FolderEntity.self,
            PhotoEntity.self,
            MilitarySymbolEntity.self,
            TacticalGraphicEntity.self,
            PlannedTargetEntity.self,
            MarkerOverlayEntity.self,
            FireMissionEntity.self,
            ObservationPostEntity.self,
            SavedGridEntity.self
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Attempt recovery: delete corrupted store and retry
            let storeURL = URL.applicationDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after recovery attempt: \(error)")
            }
        }
    }
}
