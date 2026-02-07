import SwiftUI

enum TacMapTypography {
    // MARK: - Display
    static let displayLarge = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let displaySmall = Font.system(size: 24, weight: .semibold)

    // MARK: - Headline
    static let headlineLarge = Font.system(size: 20, weight: .semibold)
    static let headlineMedium = Font.system(size: 17, weight: .semibold)
    static let headlineSmall = Font.system(size: 15, weight: .semibold)

    // MARK: - Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Label
    static let labelLarge = Font.system(size: 15, weight: .medium)
    static let labelMedium = Font.system(size: 13, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)

    // MARK: - Monospace
    static let monoLarge = Font.system(size: 17, weight: .medium, design: .monospaced)
    static let monoMedium = Font.system(size: 15, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoCaption = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let monoDisplay = Font.system(size: 20, weight: .bold, design: .monospaced)

    // MARK: - Caption
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionSmall = Font.system(size: 10, weight: .regular)
}

// MARK: - View Modifiers
extension View {
    func displayLarge() -> some View { font(TacMapTypography.displayLarge) }
    func displayMedium() -> some View { font(TacMapTypography.displayMedium) }
    func displaySmall() -> some View { font(TacMapTypography.displaySmall) }
    func headlineLarge() -> some View { font(TacMapTypography.headlineLarge) }
    func headlineMedium() -> some View { font(TacMapTypography.headlineMedium) }
    func headlineSmall() -> some View { font(TacMapTypography.headlineSmall) }
    func bodyLarge() -> some View { font(TacMapTypography.bodyLarge) }
    func bodyMedium() -> some View { font(TacMapTypography.bodyMedium) }
    func bodySmall() -> some View { font(TacMapTypography.bodySmall) }
    func labelLarge() -> some View { font(TacMapTypography.labelLarge) }
    func labelMedium() -> some View { font(TacMapTypography.labelMedium) }
    func labelSmall() -> some View { font(TacMapTypography.labelSmall) }
    func monoLarge() -> some View { font(TacMapTypography.monoLarge) }
    func monoMedium() -> some View { font(TacMapTypography.monoMedium) }
    func monoSmall() -> some View { font(TacMapTypography.monoSmall) }
}
