import SwiftUI
import CoreLocation

enum NavigationTab: String, CaseIterable {
    case offlineMaps
    case myContent
    case tools
    case symbols
    case settings

    var icon: String {
        switch self {
        case .offlineMaps: return TacMapIcons.offlineMaps
        case .myContent: return TacMapIcons.folder
        case .tools: return TacMapIcons.tools
        case .symbols: return TacMapIcons.shield
        case .settings: return TacMapIcons.settings
        }
    }

    var selectedIcon: String {
        switch self {
        case .offlineMaps: return TacMapIcons.offlineMapsFill
        case .myContent: return TacMapIcons.folderFill
        case .tools: return TacMapIcons.toolsFill
        case .symbols: return TacMapIcons.shieldFill
        case .settings: return TacMapIcons.settingsFill
        }
    }

    var title: String {
        switch self {
        case .offlineMaps: return "Offline"
        case .myContent: return "Content"
        case .tools: return "Tools"
        case .symbols: return "Symbols"
        case .settings: return "Settings"
        }
    }
}

struct ContentView: View {
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(LocationService.self) private var locationService
    @Environment(AppSettings.self) private var settings

    @State private var selectedTab: NavigationTab = .tools
    @State private var panelDetent: PanelDetent = .hidden
    @State private var isShowingMenu: Bool = false
    @State private var isShowingSearch: Bool = false
    @State private var showCopiedToast: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Layer 1: Full-screen map
                MapContainerView()
                    .ignoresSafeArea()

                // Layer 2: Top Controls Bar
                VStack {
                    TopControlsBar(
                        mgrs: mapViewModel.centerMGRS,
                        showCopiedToast: showCopiedToast,
                        onMenuTap: { isShowingMenu = true },
                        onSearchTap: { isShowingSearch = true },
                        onLayersTap: { mapViewModel.isShowingLayerPanel = true },
                        onGoToGridTap: { mapViewModel.isShowingGoToGrid = true },
                        onCopyGridTap: { copyGridToClipboard() }
                    )
                    .padding(.top, TacMapSpacing.xxs)
                    .padding(.horizontal, TacMapSpacing.sm)

                    Spacer()
                }

                // Layer 2a: Elevation label (center, below top bar)
                if let elev = mapViewModel.centerElevation {
                    VStack {
                        Text("\(Int(elev))m")
                            .font(TacMapTypography.captionSmall)
                            .foregroundColor(TacMapColors.textSecondary)
                            .padding(.horizontal, TacMapSpacing.xs)
                            .padding(.vertical, 2)
                            .background(TacMapColors.backgroundPrimary.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.top, 44)
                        Spacer()
                    }
                }

                // Layer 2b: Floating Controls — Bottom Right (Elevation, Map Mode, Location)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingControlsBottomRight(
                            mapMode: mapViewModel.mapMode,
                            isFollowingLocation: mapViewModel.isFollowingLocation,
                            terrainExaggeration: Binding(
                                get: { mapViewModel.terrainExaggeration },
                                set: { mapViewModel.terrainExaggeration = $0 }
                            ),
                            onLocationTap: {
                                if let loc = locationService.currentLocation {
                                    mapViewModel.centerOnLocation(loc)
                                }
                            },
                            onMapModeTap: { mapViewModel.cycleMapMode() }
                        )
                        .padding(.trailing, TacMapLayout.floatingControlMargin)
                    }
                    .padding(.bottom, panelDetent == .hidden ? 126 : geometry.size.height * panelDetent.fraction + 120)
                }

                // Layer 2c: Scale Bar (bottom left)
                VStack {
                    Spacer()
                    HStack {
                        ScaleBar(metersPerPixel: mapViewModel.metersPerPixel)
                            .padding(.leading, TacMapSpacing.md)
                            .padding(.bottom, 56)
                        Spacer()
                    }
                }

                // Layer 3: Quick Drop FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        QuickDropView()
                            .padding(.trailing, TacMapSpacing.md)
                            .padding(.bottom, panelDetent == .hidden ? 58 : geometry.size.height * panelDetent.fraction + 52)
                    }
                }

                // Layer 4: Slide-up Panel + Bottom Nav
                VStack(spacing: 0) {
                    Spacer()

                    // Panel
                    SlideUpPanel(detent: $panelDetent) {
                        tabContent
                    }

                    // Bottom Navigation Bar
                    BottomNavigationBar(
                        selectedTab: selectedTab,
                        onTabSelected: { tab in
                            handleTabSelection(tab)
                        }
                    )
                    .background(TacMapColors.backgroundPrimary)
                }

                // Layer 5: Marker Detail Card
                if mapViewModel.selectedMarker != nil {
                    MarkerDetailCard(
                        marker: mapViewModel.selectedMarker!,
                        isPresented: Binding(
                            get: { mapViewModel.selectedMarker != nil },
                            set: { if !$0 { mapViewModel.selectedMarker = nil } }
                        )
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
                }

                // Layer 6: (removed — Go To Grid is now a .sheet)
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $isShowingMenu) { MenuView() }
        .sheet(isPresented: $isShowingSearch) { SearchView() }
        .sheet(isPresented: Binding(
            get: { mapViewModel.isShowingLayerPanel },
            set: { mapViewModel.isShowingLayerPanel = $0 }
        )) {
            LayerTogglePanel()
        }
        .sheet(isPresented: Binding(
            get: { mapViewModel.isShowingGoToGrid },
            set: { mapViewModel.isShowingGoToGrid = $0 }
        )) {
            GoToGridSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(TacMapColors.backgroundSecondary)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            locationService.start()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .offlineMaps: OfflineMapsPanel()
        case .myContent: MyContentPanel()
        case .tools: ToolsPanel()
        case .symbols: SymbolsPanel()
        case .settings: SettingsPanel()
        }
    }

    private func copyGridToClipboard() {
        UIPasteboard.general.string = mapViewModel.centerMGRS
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        withAnimation(TacMapAnimation.fade) {
            showCopiedToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(TacMapAnimation.fade) {
                showCopiedToast = false
            }
        }
    }

    private func handleTabSelection(_ tab: NavigationTab) {
        let impact = UISelectionFeedbackGenerator()
        impact.selectionChanged()

        if tab == selectedTab {
            panelDetent = panelDetent == .hidden ? .partial : .hidden
        } else {
            selectedTab = tab
            if panelDetent == .hidden {
                panelDetent = .partial
            }
        }
    }
}

// MARK: - Top Controls Bar

struct TopControlsBar: View {
    let mgrs: String
    let showCopiedToast: Bool
    let onMenuTap: () -> Void
    let onSearchTap: () -> Void
    let onLayersTap: () -> Void
    let onGoToGridTap: () -> Void
    let onCopyGridTap: () -> Void

    var body: some View {
        HStack {
            // Menu button
            Button(action: onMenuTap) {
                Image(systemName: TacMapIcons.menu)
                    .font(.system(size: TacMapIcons.sizeMedium))
                    .foregroundColor(TacMapColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(TacMapColors.backgroundElevated.opacity(0.85))
                    .clipShape(Circle())
            }

            // Layers pill
            Button(action: onLayersTap) {
                HStack(spacing: 4) {
                    Image(systemName: TacMapIcons.layers)
                        .font(.system(size: 12))
                    Text("Layers")
                        .font(TacMapTypography.labelSmall)
                }
                .foregroundColor(TacMapColors.textPrimary)
                .padding(.horizontal, TacMapSpacing.xs)
                .padding(.vertical, TacMapSpacing.xxs)
                .background(TacMapColors.backgroundElevated.opacity(0.85))
                .clipShape(Capsule())
            }

            // Go To Grid pill + Copy button with centered toast
            VStack(spacing: TacMapSpacing.xxxs) {
                HStack(spacing: TacMapSpacing.xxs) {
                    // Go To Grid / MGRS coordinate pill
                    Button(action: onGoToGridTap) {
                        HStack(spacing: 4) {
                            Image(systemName: TacMapIcons.goToGrid)
                                .font(.system(size: 12))
                            Text(mgrs.isEmpty ? "Grid" : mgrs)
                                .font(TacMapTypography.labelSmall)
                                .lineLimit(1)
                        }
                        .foregroundColor(TacMapColors.accentPrimary)
                        .padding(.horizontal, TacMapSpacing.xs)
                        .padding(.vertical, TacMapSpacing.xxs)
                        .background(TacMapColors.backgroundElevated.opacity(0.85))
                        .clipShape(Capsule())
                    }

                    // Copy grid button
                    Button(action: onCopyGridTap) {
                        Image(systemName: TacMapIcons.copy)
                            .font(.system(size: 12))
                            .foregroundColor(TacMapColors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(TacMapColors.backgroundElevated.opacity(0.85))
                            .clipShape(Circle())
                    }
                }

                // Toast centered below grid pill + copy button
                if showCopiedToast {
                    Text("Copied!")
                        .font(TacMapTypography.captionSmall)
                        .foregroundColor(TacMapColors.textPrimary)
                        .padding(.horizontal, TacMapSpacing.xs)
                        .padding(.vertical, TacMapSpacing.xxxs)
                        .background(TacMapColors.backgroundElevated)
                        .clipShape(Capsule())
                        .transition(.opacity.animation(TacMapAnimation.fade))
                }
            }

            Spacer()

            // Search
            Button(action: onSearchTap) {
                Image(systemName: TacMapIcons.search)
                    .font(.system(size: TacMapIcons.sizeMedium))
                    .foregroundColor(TacMapColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(TacMapColors.backgroundElevated.opacity(0.85))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {
    let selectedTab: NavigationTab
    let onTabSelected: (NavigationTab) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(TacMapColors.borderSubtle)
                .frame(height: 0.5)

            HStack {
                ForEach(NavigationTab.allCases, id: \.rawValue) { tab in
                    Button(action: { onTabSelected(tab) }) {
                        VStack(spacing: 1) {
                            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: TacMapLayout.bottomNavIconSize))
                                .foregroundColor(selectedTab == tab ? TacMapColors.accentPrimary : TacMapColors.textTertiary)

                            Text(tab.title)
                                .font(TacMapTypography.captionSmall)
                                .foregroundColor(selectedTab == tab ? TacMapColors.accentPrimary : TacMapColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, TacMapSpacing.xxs)
            .padding(.bottom, TacMapSpacing.xxxs)
        }
    }
}
