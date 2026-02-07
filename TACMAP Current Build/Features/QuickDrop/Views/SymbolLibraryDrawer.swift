import SwiftUI

struct SymbolLibraryDrawer: View {
    @Environment(\.dismiss) private var dismiss
    let onSymbolSelected: (SymbolDefinition) -> Void

    @State private var selectedAffiliation: Affiliation = .friendly
    @State private var selectedCategory: SymbolCategory?
    @State private var searchText: String = ""
    @State private var selectedEchelon: Echelon = .squad

    private var allSymbols: [SymbolDefinition] {
        var results: [SymbolDefinition] = []
        for unitType in UnitType.allCases {
            let def = SymbolDefinition(
                affiliation: selectedAffiliation,
                unitType: unitType,
                echelon: selectedEchelon
            )
            results.append(def)
        }
        return results
    }

    private var filteredSymbols: [SymbolDefinition] {
        var symbols = allSymbols
        if let category = selectedCategory {
            symbols = symbols.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            symbols = symbols.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
        return symbols
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
                .padding(.top, TacMapSpacing.xs)

                // Affiliation tabs
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
                    .padding(.vertical, TacMapSpacing.xs)
                }

                // Echelon picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TacMapSpacing.xs) {
                        ForEach(Echelon.allCases) { ech in
                            Button(action: { selectedEchelon = ech }) {
                                Text(ech.displayName)
                                    .font(TacMapTypography.labelSmall)
                                    .foregroundColor(selectedEchelon == ech ? TacMapColors.textInverse : TacMapColors.textSecondary)
                                    .padding(.horizontal, TacMapSpacing.xs)
                                    .padding(.vertical, TacMapSpacing.xxxs)
                                    .background(selectedEchelon == ech ? TacMapColors.accentPrimary : TacMapColors.backgroundTertiary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                }

                // Symbol grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: TacMapSpacing.xs) {
                        ForEach(filteredSymbols) { symbol in
                            Button(action: {
                                onSymbolSelected(symbol)
                                dismiss()
                            }) {
                                VStack(spacing: TacMapSpacing.xxs) {
                                    Image(systemName: symbol.unitType.sfSymbol)
                                        .font(.system(size: 28))
                                        .foregroundColor(symbol.affiliation.color)
                                        .frame(width: 50, height: 50)
                                        .background(symbol.affiliation.fillColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text(symbol.displayName)
                                        .font(TacMapTypography.captionSmall)
                                        .foregroundColor(TacMapColors.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TacMapSpacing.xs)
                                .background(TacMapColors.backgroundTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                    .padding(.top, TacMapSpacing.xs)
                }
            }
            .background(TacMapColors.backgroundPrimary)
            .navigationTitle("Symbol Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
