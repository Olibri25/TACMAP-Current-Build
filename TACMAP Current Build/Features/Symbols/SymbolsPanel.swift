import SwiftUI

struct SymbolsPanel: View {
    @State private var selectedAffiliation: Affiliation = .friendly
    @State private var searchText: String = ""
    @State private var selectedCategory: SymbolCategory?

    private var filteredTypes: [UnitType] {
        var types = UnitType.allCases
        if let category = selectedCategory {
            types = types.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            types = types.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
        return types
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TacMapSpacing.md) {
                Text("Symbol Library")
                    .font(TacMapTypography.headlineLarge)
                    .foregroundColor(TacMapColors.textPrimary)
                    .padding(.horizontal, TacMapSpacing.md)

                // Search
                HStack {
                    Image(systemName: TacMapIcons.search)
                        .foregroundColor(TacMapColors.textTertiary)
                    TextField("Search symbols...", text: $searchText)
                        .foregroundColor(TacMapColors.textPrimary)
                }
                .padding(TacMapSpacing.xs)
                .background(TacMapColors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, TacMapSpacing.md)

                // Affiliation Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TacMapSpacing.xs) {
                        ForEach(Affiliation.allCases) { aff in
                            Button(action: { selectedAffiliation = aff }) {
                                Text(aff.displayName)
                                    .font(TacMapTypography.labelMedium)
                                    .foregroundColor(selectedAffiliation == aff ? TacMapColors.textInverse : aff.color)
                                    .padding(.horizontal, TacMapSpacing.sm)
                                    .padding(.vertical, TacMapSpacing.xxs)
                                    .background(selectedAffiliation == aff ? aff.color : aff.color.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                }

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TacMapSpacing.xs) {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .font(TacMapTypography.labelSmall)
                                .foregroundColor(selectedCategory == nil ? TacMapColors.textInverse : TacMapColors.textSecondary)
                                .padding(.horizontal, TacMapSpacing.xs)
                                .padding(.vertical, TacMapSpacing.xxxs)
                                .background(selectedCategory == nil ? TacMapColors.accentPrimary : TacMapColors.backgroundTertiary)
                                .clipShape(Capsule())
                        }
                        ForEach(SymbolCategory.allCases) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat.rawValue)
                                    .font(TacMapTypography.labelSmall)
                                    .foregroundColor(selectedCategory == cat ? TacMapColors.textInverse : TacMapColors.textSecondary)
                                    .padding(.horizontal, TacMapSpacing.xs)
                                    .padding(.vertical, TacMapSpacing.xxxs)
                                    .background(selectedCategory == cat ? TacMapColors.accentPrimary : TacMapColors.backgroundTertiary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                }

                // Symbol Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: TacMapSpacing.xs) {
                    ForEach(filteredTypes) { unitType in
                        SymbolCard(unitType: unitType, affiliation: selectedAffiliation)
                    }
                }
                .padding(.horizontal, TacMapSpacing.md)
            }
            .padding(.top, TacMapSpacing.sm)
        }
    }
}

struct SymbolCard: View {
    let unitType: UnitType
    let affiliation: Affiliation

    var body: some View {
        VStack(spacing: TacMapSpacing.xxs) {
            Image(systemName: unitType.sfSymbol)
                .font(.system(size: 24))
                .foregroundColor(affiliation.color)
                .frame(width: 44, height: 44)
                .background(affiliation.fillColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(unitType.displayName)
                .font(TacMapTypography.captionSmall)
                .foregroundColor(TacMapColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TacMapSpacing.xs)
        .background(TacMapColors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
