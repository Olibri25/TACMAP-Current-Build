import Foundation

@Observable
class DependencyContainer {
    let targetNumberGenerator = TargetNumberGenerator()
    let symbolRenderer: MilitarySymbolRenderer = SFSymbolRenderer()
}
