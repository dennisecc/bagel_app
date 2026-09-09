import Foundation

extension Decimal {
    /// Rounds to `scale` fractional digits using the given rounding mode,
    /// without going through `Double` (which would reintroduce binary float error).
    func rounded(scale: Int, _ mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}
