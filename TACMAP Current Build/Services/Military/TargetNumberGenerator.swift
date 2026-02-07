import Foundation

@Observable
class TargetNumberGenerator {
    private var currentPrefix: String = "AA"
    private var currentNumber: Int = 0

    private let prefixKey = "targetNumberPrefix"
    private let numberKey = "targetNumberSequence"

    init() {
        currentPrefix = UserDefaults.standard.string(forKey: prefixKey) ?? "AA"
        currentNumber = UserDefaults.standard.integer(forKey: numberKey)
    }

    func next() -> String {
        currentNumber += 1
        save()
        return String(format: "%@%04d", currentPrefix, currentNumber)
    }

    func setPrefix(_ prefix: String) {
        let sanitized = String(prefix.uppercased().prefix(2))
        guard sanitized.count == 2, sanitized.allSatisfy({ $0.isLetter }) else { return }
        currentPrefix = sanitized
        save()
    }

    func reset() {
        currentNumber = 0
        save()
    }

    private func save() {
        UserDefaults.standard.set(currentPrefix, forKey: prefixKey)
        UserDefaults.standard.set(currentNumber, forKey: numberKey)
    }
}
