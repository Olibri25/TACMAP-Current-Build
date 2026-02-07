import SwiftUI

struct MenuView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    menuRow(icon: "map", title: "Map Settings")
                    menuRow(icon: "folder", title: "My Content")
                    menuRow(icon: "scope", title: "Fire Support")
                }

                Section {
                    menuRow(icon: "square.and.arrow.up", title: "Export Data")
                    menuRow(icon: "square.and.arrow.down", title: "Import Data")
                }

                Section {
                    menuRow(icon: "info.circle", title: "About TacMap")
                    menuRow(icon: "questionmark.circle", title: "Help")
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: TacMapSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(TacMapColors.accentPrimary)
                .frame(width: 24)
            Text(title)
                .foregroundColor(TacMapColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(TacMapColors.textTertiary)
        }
    }
}
