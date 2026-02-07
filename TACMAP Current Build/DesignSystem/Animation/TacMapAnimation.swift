import SwiftUI

enum TacMapAnimation {
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let panel = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let camera = Animation.easeInOut(duration: 0.5)
    static let fade = Animation.easeInOut(duration: 0.2)
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
}
