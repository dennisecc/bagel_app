import Foundation

/// Formatting helpers around `Decimal` currency values. All money in this app
/// is stored as `Decimal`, never `Double`, to avoid floating-point cent errors.
enum Money {
    static func format(_ amount: Decimal, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    static let centTolerance = Decimal(string: "0.01")!
}
