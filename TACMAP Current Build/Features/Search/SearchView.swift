import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack {
                Text("Search coming in V2.1")
                    .font(TacMapTypography.bodyMedium)
                    .foregroundColor(TacMapColors.textTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TacMapColors.backgroundPrimary)
            .searchable(text: $searchText, prompt: "Search markers, grids...")
            .navigationTitle("Search")
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
