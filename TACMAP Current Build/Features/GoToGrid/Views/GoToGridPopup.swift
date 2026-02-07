import SwiftUI
import SwiftData
import CoreLocation

struct GoToGridPopup: View {
    @Binding var isPresented: Bool
    @Environment(MapViewModel.self) private var mapViewModel
    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = GoToGridViewModel()
    @State private var showSaveDialog = false
    @State private var favoriteName = ""

    @Query(filter: #Predicate<SavedGridEntity> { $0.isFavorite }, sort: \SavedGridEntity.createdAt, order: .reverse)
    private var favorites: [SavedGridEntity]

    @Query(filter: #Predicate<SavedGridEntity> { !$0.isFavorite }, sort: \SavedGridEntity.lastUsedAt, order: .reverse)
    private var recents: [SavedGridEntity]

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Popup card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Go To Grid")
                        .font(TacMapTypography.headlineLarge)
                        .foregroundColor(TacMapColors.textPrimary)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: TacMapIcons.close)
                            .foregroundColor(TacMapColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(TacMapColors.backgroundTertiary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, TacMapSpacing.md)
                .padding(.top, TacMapSpacing.md)

                ScrollView {
                    VStack(spacing: TacMapSpacing.md) {
                        // Favorites
                        if !favorites.isEmpty {
                            favoritesSection
                        }

                        // Recents
                        if !recents.isEmpty {
                            recentsSection
                        }

                        // Input Fields
                        inputFieldsSection

                        // Custom MGRS Keyboard
                        MGRSKeyboard(
                            focusedField: viewModel.focusedField,
                            onKey: { viewModel.handleKeyInput($0) },
                            onBackspace: { viewModel.handleBackspace() },
                            onNext: { viewModel.advanceField() }
                        )

                        // Action Buttons
                        HStack(spacing: TacMapSpacing.sm) {
                            SecondaryButton(title: "Save") {
                                showSaveDialog = true
                            }

                            PrimaryButton(title: "GO", isEnabled: viewModel.isValid) {
                                if viewModel.navigateToGrid(mapViewModel: mapViewModel, modelContext: modelContext) {
                                    isPresented = false
                                }
                            }
                        }
                        .padding(.horizontal, TacMapSpacing.md)
                    }
                    .padding(.bottom, TacMapSpacing.md)
                }
            }
            .background(TacMapColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: TacMapLayout.panelCornerRadius))
            .padding(.horizontal, TacMapSpacing.md)
            .padding(.vertical, 60)
        }
        .onAppear {
            if let loc = locationService.currentLocation?.coordinate {
                viewModel.updateDefaults(from: loc)
            }
        }
        .alert("Save Favorite", isPresented: $showSaveDialog) {
            TextField("Name (e.g., OBJ Copper)", text: $favoriteName)
            Button("Save") {
                viewModel.saveFavorite(name: favoriteName, modelContext: modelContext)
                favoriteName = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Favorites Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: TacMapSpacing.xs) {
            HStack {
                Image(systemName: TacMapIcons.favoriteFill)
                    .foregroundColor(TacMapColors.accentPrimary)
                    .font(.system(size: 12))
                Text("Favorites")
                    .font(TacMapTypography.headlineSmall)
                    .foregroundColor(TacMapColors.textSecondary)
            }
            .padding(.horizontal, TacMapSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TacMapSpacing.xs) {
                    ForEach(favorites) { fav in
                        FavoriteGridCard(grid: fav) {
                            jumpToGrid(fav)
                        }
                    }
                }
                .padding(.horizontal, TacMapSpacing.md)
            }
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

            ForEach(recents.prefix(5)) { recent in
                Button(action: { jumpToGrid(recent) }) {
                    HStack {
                        Text("\(recent.zone) \(recent.square) \(recent.easting) \(recent.northing)")
                            .font(TacMapTypography.monoSmall)
                            .foregroundColor(TacMapColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(TacMapColors.textTertiary)
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                    .padding(.vertical, TacMapSpacing.xs)
                }
            }
        }
    }

    // MARK: - Input Fields
    private var inputFieldsSection: some View {
        HStack(spacing: TacMapSpacing.xs) {
            GridInputField(label: "Zone", value: viewModel.zone, placeholder: viewModel.defaultZone, isFocused: viewModel.focusedField == .zone) {
                viewModel.focusedField = .zone
            }
            GridInputField(label: "Sq", value: viewModel.square, placeholder: viewModel.defaultSquare, isFocused: viewModel.focusedField == .square) {
                viewModel.focusedField = .square
            }
            GridInputField(label: "Easting", value: viewModel.easting, placeholder: "00000", isFocused: viewModel.focusedField == .easting) {
                viewModel.focusedField = .easting
            }
            GridInputField(label: "Northing", value: viewModel.northing, placeholder: "00000", isFocused: viewModel.focusedField == .northing) {
                viewModel.focusedField = .northing
            }
        }
        .padding(.horizontal, TacMapSpacing.md)
    }

    private func jumpToGrid(_ grid: SavedGridEntity) {
        let mgrs = grid.mgrsString
        if let coord = CoordinateConverter.fromMGRS(mgrs) {
            let zoom = mapViewModel.zoomLevel < 10 ? 14.0 : mapViewModel.zoomLevel
            mapViewModel.navigateToCoordinate(coord, zoom: zoom)

            grid.lastUsedAt = Date()

            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
            isPresented = false
        }
    }
}

// MARK: - Supporting Views

struct FavoriteGridCard: View {
    let grid: SavedGridEntity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(grid.name ?? "Saved")
                    .font(TacMapTypography.labelSmall)
                    .foregroundColor(TacMapColors.accentPrimary)
                    .lineLimit(1)
                Text("\(grid.zone)\(grid.square)")
                    .font(TacMapTypography.monoCaption)
                    .foregroundColor(TacMapColors.textSecondary)
                Text("\(grid.easting) \(grid.northing)")
                    .font(TacMapTypography.monoCaption)
                    .foregroundColor(TacMapColors.textSecondary)
            }
            .padding(TacMapSpacing.xs)
            .frame(width: 80)
            .background(TacMapColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct GridInputField: View {
    let label: String
    let value: String
    let placeholder: String
    let isFocused: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(TacMapTypography.captionSmall)
                .foregroundColor(TacMapColors.textTertiary)

            Text(value.isEmpty ? placeholder : value)
                .font(TacMapTypography.monoMedium)
                .foregroundColor(value.isEmpty ? TacMapColors.textTertiary : TacMapColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TacMapSpacing.xs)
                .background(TacMapColors.backgroundTertiary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? TacMapColors.accentPrimary : TacMapColors.borderDefault, lineWidth: isFocused ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { onTap() }
        }
    }
}
