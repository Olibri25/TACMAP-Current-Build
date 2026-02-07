import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Recent Grid Item

struct RecentGridItem: Identifiable {
    let id: UUID
    let mgrs: String
    let name: String
    let type: String        // "WP", "SYM", "TGT", "OP", "GRID"
    let typeIcon: String    // SF Symbol
    let date: Date
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Go To Grid Sheet

struct GoToGridSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = GoToGridViewModel()
    @State private var showSaveDialog = false
    @State private var favoriteName = ""

    enum FocusField: Hashable {
        case zone, square, easting, northing
    }
    @FocusState private var focusedField: FocusField?

    // MARK: - Queries for unified recents
    @Query(filter: #Predicate<SavedGridEntity> { !$0.isFavorite }, sort: \SavedGridEntity.lastUsedAt, order: .reverse)
    private var recentGrids: [SavedGridEntity]

    @Query(sort: \WaypointEntity.createdAt, order: .reverse)
    private var waypoints: [WaypointEntity]

    @Query(sort: \MilitarySymbolEntity.createdAt, order: .reverse)
    private var symbols: [MilitarySymbolEntity]

    @Query(sort: \PlannedTargetEntity.createdAt, order: .reverse)
    private var targets: [PlannedTargetEntity]

    @Query(sort: \ObservationPostEntity.createdAt, order: .reverse)
    private var observationPosts: [ObservationPostEntity]

    // MARK: - Unified recents
    private var recentItems: [RecentGridItem] {
        var items: [RecentGridItem] = []

        for wp in waypoints.prefix(5) {
            let coord = CLLocationCoordinate2D(latitude: wp.latitude, longitude: wp.longitude)
            let mgrs = CoordinateConverter.toMGRS(coord, precision: 5)
            items.append(RecentGridItem(
                id: wp.id, mgrs: mgrs, name: wp.name,
                type: "WP", typeIcon: TacMapIcons.waypoint,
                date: wp.createdAt, coordinate: coord
            ))
        }

        for sym in symbols.prefix(5) {
            let coord = CLLocationCoordinate2D(latitude: sym.latitude, longitude: sym.longitude)
            let mgrs = CoordinateConverter.toMGRS(coord, precision: 5)
            items.append(RecentGridItem(
                id: sym.id, mgrs: mgrs, name: sym.name,
                type: "SYM", typeIcon: TacMapIcons.shield,
                date: sym.createdAt, coordinate: coord
            ))
        }

        for tgt in targets.prefix(5) {
            let coord = CLLocationCoordinate2D(latitude: tgt.latitude, longitude: tgt.longitude)
            let mgrs = CoordinateConverter.toMGRS(coord, precision: 5)
            items.append(RecentGridItem(
                id: tgt.id, mgrs: mgrs, name: tgt.name,
                type: "TGT", typeIcon: TacMapIcons.target,
                date: tgt.createdAt, coordinate: coord
            ))
        }

        for op in observationPosts.prefix(5) {
            let coord = CLLocationCoordinate2D(latitude: op.latitude, longitude: op.longitude)
            let mgrs = CoordinateConverter.toMGRS(coord, precision: 5)
            items.append(RecentGridItem(
                id: op.id, mgrs: mgrs, name: op.name,
                type: "OP", typeIcon: "eye",
                date: op.createdAt, coordinate: coord
            ))
        }

        for grid in recentGrids.prefix(5) {
            let mgrs = "\(grid.zone) \(grid.square) \(grid.easting) \(grid.northing)"
            if let coord = CoordinateConverter.fromMGRS(grid.mgrsString) {
                items.append(RecentGridItem(
                    id: grid.id, mgrs: mgrs, name: grid.name ?? "Grid",
                    type: "GRID", typeIcon: TacMapIcons.goToGrid,
                    date: grid.lastUsedAt, coordinate: coord
                ))
            }
        }

        return items.sorted { $0.date > $1.date }.prefix(8).map { $0 }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable recents
                if !recentItems.isEmpty {
                    ScrollView {
                        recentsSection
                            .padding(.top, TacMapSpacing.sm)
                    }
                    .scrollDismissesKeyboard(.never)
                } else {
                    Spacer()
                }

                Divider()
                    .overlay(TacMapColors.borderSubtle)

                // Pinned input area
                inputSection
                    .padding(.horizontal, TacMapSpacing.md)
                    .padding(.top, TacMapSpacing.sm)
                    .padding(.bottom, TacMapSpacing.xs)
            }
            .navigationTitle("Go To Grid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: TacMapIcons.close)
                            .foregroundColor(TacMapColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(TacMapColors.backgroundTertiary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear {
            if let loc = locationService.currentLocation?.coordinate {
                viewModel.updateDefaults(from: loc)
            }
            focusedField = .easting
        }
        .onChange(of: focusedField) { _, newValue in
            if newValue == nil {
                focusedField = .easting
            }
        }
        .alert("Save Grid", isPresented: $showSaveDialog) {
            TextField("Name (e.g., OBJ Copper)", text: $favoriteName)
            Button("Save") {
                viewModel.saveFavorite(name: favoriteName, modelContext: modelContext)
                favoriteName = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Recents Section

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: TacMapSpacing.xs) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(TacMapColors.textTertiary)
                    .font(.system(size: 12))
                Text("Recent")
                    .font(TacMapTypography.headlineSmall)
                    .foregroundColor(TacMapColors.textSecondary)
            }
            .padding(.horizontal, TacMapSpacing.md)

            ForEach(recentItems) { item in
                Button(action: { navigateToItem(item) }) {
                    HStack(spacing: TacMapSpacing.xs) {
                        Image(systemName: item.typeIcon)
                            .font(.system(size: 14))
                            .foregroundColor(TacMapColors.accentPrimary)
                            .frame(width: 24)

                        Text(item.type)
                            .font(TacMapTypography.labelSmall)
                            .foregroundColor(TacMapColors.textTertiary)
                            .frame(width: 36, alignment: .leading)

                        Text(item.mgrs)
                            .font(TacMapTypography.monoSmall)
                            .foregroundColor(TacMapColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        if item.type != "GRID" {
                            Text(item.name)
                                .font(TacMapTypography.captionSmall)
                                .foregroundColor(TacMapColors.textTertiary)
                                .lineLimit(1)
                        }

                        Image(systemName: TacMapIcons.chevronRight)
                            .font(.system(size: 10))
                            .foregroundColor(TacMapColors.textTertiary)
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                    .padding(.vertical, TacMapSpacing.xs)
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: TacMapSpacing.sm) {
            // Field labels
            HStack(spacing: TacMapSpacing.xs) {
                Text("Zone")
                    .font(TacMapTypography.captionSmall)
                    .foregroundColor(TacMapColors.textTertiary)
                    .frame(width: 52)
                Text("Sq")
                    .font(TacMapTypography.captionSmall)
                    .foregroundColor(TacMapColors.textTertiary)
                    .frame(width: 44)
                Text("Easting")
                    .font(TacMapTypography.captionSmall)
                    .foregroundColor(TacMapColors.textTertiary)
                    .frame(maxWidth: .infinity)
                Text("Northing")
                    .font(TacMapTypography.captionSmall)
                    .foregroundColor(TacMapColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }

            // Input fields
            HStack(spacing: TacMapSpacing.xs) {
                // Zone
                TextField(viewModel.defaultZone, text: $viewModel.zone)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .font(TacMapTypography.monoMedium)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
                    .padding(.vertical, TacMapSpacing.xs)
                    .background(TacMapColors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .zone ? TacMapColors.accentPrimary : TacMapColors.borderDefault, lineWidth: focusedField == .zone ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .zone)
                    .onChange(of: viewModel.zone) { _, newValue in
                        // Filter: allow digits + one letter (lat band)
                        let filtered = String(newValue.prefix(3)).uppercased()
                        if filtered != newValue { viewModel.zone = filtered }
                        if filtered.count >= 3 { focusedField = .square }
                    }

                // Square
                TextField(viewModel.defaultSquare, text: $viewModel.square)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .font(TacMapTypography.monoMedium)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
                    .padding(.vertical, TacMapSpacing.xs)
                    .background(TacMapColors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .square ? TacMapColors.accentPrimary : TacMapColors.borderDefault, lineWidth: focusedField == .square ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .square)
                    .onChange(of: viewModel.square) { _, newValue in
                        let filtered = String(newValue.prefix(2).filter { $0.isLetter }).uppercased()
                        if filtered != newValue { viewModel.square = filtered }
                        if filtered.count >= 2 { focusedField = .easting }
                    }

                // Easting
                TextField("00000", text: $viewModel.easting)
                    .keyboardType(.numberPad)
                    .font(TacMapTypography.monoMedium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TacMapSpacing.xs)
                    .background(TacMapColors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .easting ? TacMapColors.accentPrimary : TacMapColors.borderDefault, lineWidth: focusedField == .easting ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .easting)
                    .onChange(of: viewModel.easting) { _, newValue in
                        let filtered = String(newValue.prefix(5).filter { $0.isNumber })
                        if filtered != newValue { viewModel.easting = filtered }
                    }

                // Northing
                TextField("00000", text: $viewModel.northing)
                    .keyboardType(.numberPad)
                    .font(TacMapTypography.monoMedium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TacMapSpacing.xs)
                    .background(TacMapColors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .northing ? TacMapColors.accentPrimary : TacMapColors.borderDefault, lineWidth: focusedField == .northing ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .northing)
                    .onChange(of: viewModel.northing) { _, newValue in
                        let filtered = String(newValue.prefix(5).filter { $0.isNumber })
                        if filtered != newValue { viewModel.northing = filtered }
                    }
            }

            // Action buttons
            HStack(spacing: TacMapSpacing.xs) {
                SecondaryButton(title: "Save") {
                    showSaveDialog = true
                }

                // Next button
                Button(action: { advanceFocus() }) {
                    Text("Next")
                        .font(TacMapTypography.labelLarge)
                        .foregroundColor(TacMapColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TacMapSpacing.sm)
                        .background(TacMapColors.accentPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                PrimaryButton(title: "GO", action: {
                    if viewModel.navigateToGrid(mapViewModel: mapViewModel, modelContext: modelContext) {
                        dismiss()
                    }
                }, isEnabled: viewModel.isValid)
            }
        }
    }

    // MARK: - Actions

    private func navigateToItem(_ item: RecentGridItem) {
        let zoom = mapViewModel.zoomLevel < 10 ? 14.0 : mapViewModel.zoomLevel
        mapViewModel.navigateToCoordinate(item.coordinate, zoom: zoom)

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        dismiss()
    }

    private func advanceFocus() {
        switch focusedField {
        case .zone: focusedField = .square
        case .square: focusedField = .easting
        case .easting: focusedField = .northing
        case .northing: focusedField = .easting
        case nil: focusedField = .zone
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
