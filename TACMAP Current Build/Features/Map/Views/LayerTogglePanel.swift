import SwiftUI

struct LayerTogglePanel: View {
    @Environment(MapViewModel.self) private var mapViewModel

    var body: some View {
        @Bindable var vm = mapViewModel

        NavigationStack {
            List {
                Section("Map Layers") {
                    Toggle("Satellite", isOn: $vm.showSatellite)
                    Toggle("Terrain", isOn: $vm.showTerrain)
                    Toggle("Streets", isOn: $vm.showStreets)
                    Toggle("MGRS Grid", isOn: $vm.showMGRSGrid)
                    Toggle("Contours", isOn: $vm.showElevationContours)
                }

                Section("Annotations") {
                    Toggle("Waypoints", isOn: $vm.showWaypoints)
                    Toggle("Routes", isOn: $vm.showRoutes)
                    Toggle("Symbols", isOn: $vm.showSymbols)
                    Toggle("Graphics", isOn: $vm.showGraphics)
                    Toggle("Targets", isOn: $vm.showTargets)
                    Toggle("Range Rings", isOn: $vm.showRangeRings)
                }
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        mapViewModel.isShowingLayerPanel = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
