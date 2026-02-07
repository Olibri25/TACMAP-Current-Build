import SwiftUI

struct SettingsPanel: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var s = settings

        ScrollView {
            VStack(alignment: .leading, spacing: TacMapSpacing.md) {
                Text("Settings")
                    .font(TacMapTypography.headlineLarge)
                    .foregroundColor(TacMapColors.textPrimary)
                    .padding(.horizontal, TacMapSpacing.md)

                // Units
                settingsSection("Units") {
                    SettingsPicker(title: "Distance", selection: $s.distanceUnit, options: ["m", "km", "ft", "mi", "nm"])
                    SettingsPicker(title: "Elevation", selection: $s.elevationUnit, options: ["m", "ft"])
                    SettingsPicker(title: "Temperature", selection: $s.temperatureUnit, options: ["F", "C"])
                }

                // Coordinates
                settingsSection("Coordinates") {
                    HStack {
                        Text("Format")
                            .font(TacMapTypography.bodyMedium)
                            .foregroundColor(TacMapColors.textPrimary)
                        Spacer()
                        Picker("", selection: $s.coordinateFormat) {
                            ForEach(CoordinateFormat.allCases) { fmt in
                                Text(fmt.displayName).tag(fmt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal, TacMapSpacing.md)
                }

                // Map
                settingsSection("Map") {
                    Toggle("Show Grid Overlay", isOn: $s.defaultGridOverlay)
                        .padding(.horizontal, TacMapSpacing.md)
                    Toggle("Show Contour Lines", isOn: $s.showContourLines)
                        .padding(.horizontal, TacMapSpacing.md)
                    Toggle("Show Hillshade", isOn: $s.showHillshade)
                        .padding(.horizontal, TacMapSpacing.md)
                    Toggle("Show 3D Buildings", isOn: $s.show3DBuildings)
                        .padding(.horizontal, TacMapSpacing.md)
                }

                // Display
                settingsSection("Display") {
                    SettingsPicker(title: "Symbol Size", selection: $s.symbolSize, options: ["small", "medium", "large"])
                }

                // GPS
                settingsSection("GPS") {
                    SettingsPicker(title: "Update Frequency", selection: $s.gpsUpdateFrequency, options: ["fast", "normal", "batterySaver"])
                    Toggle("Show Accuracy Circle", isOn: $s.showAccuracyCircle)
                        .padding(.horizontal, TacMapSpacing.md)
                }

                // Reset
                Button(action: { settings.resetToDefaults() }) {
                    Text("Reset to Defaults")
                        .font(TacMapTypography.labelLarge)
                        .foregroundColor(TacMapColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TacMapSpacing.sm)
                }
                .padding(.horizontal, TacMapSpacing.md)
                .padding(.bottom, TacMapSpacing.xxl)
            }
            .padding(.top, TacMapSpacing.sm)
        }
        .tint(TacMapColors.accentPrimary)
    }

    @ViewBuilder
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: TacMapSpacing.xs) {
            Text(title)
                .font(TacMapTypography.headlineSmall)
                .foregroundColor(TacMapColors.textSecondary)
                .padding(.horizontal, TacMapSpacing.md)
            content()
        }
    }
}

struct SettingsPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Text(title)
                .font(TacMapTypography.bodyMedium)
                .foregroundColor(TacMapColors.textPrimary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .tint(TacMapColors.accentPrimary)
        }
        .padding(.horizontal, TacMapSpacing.md)
    }
}
