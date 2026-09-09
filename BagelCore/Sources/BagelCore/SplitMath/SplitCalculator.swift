import Foundation

public enum SplitCalculatorError: Error, Equatable, Sendable {
    case emptyShares
    case mixedShareTypes
    case exactAmountsDoNotReconcile(expected: Decimal, actual: Decimal)
    case invalidPercentageTotal(total: Decimal)
}

/// Resolves a line item's total cost into per-person amounts.
///
/// Dividing a total evenly (or by percentage) in cents almost never comes out exact
/// (e.g. $10.00 / 3 = $3.333...). Rounding each share down independently would lose
/// pennies, so any leftover is distributed one cent at a time across participants —
/// the same approach Splitwise-style apps use to guarantee the parts always sum to
/// the whole.
public enum SplitCalculator {
    private static let cent = Decimal(string: "0.01")!
    private static let centTolerance = Decimal(string: "0.01")!

    public static func computeAmounts(lineTotal: Decimal, shares: [SplitShare]) throws -> [UUID: Decimal] {
        guard let firstType = shares.first?.type else { throw SplitCalculatorError.emptyShares }
        guard shares.allSatisfy({ $0.type == firstType }) else { throw SplitCalculatorError.mixedShareTypes }

        switch firstType {
        case .equal:
            return splitEqually(lineTotal: lineTotal, personIDs: shares.map(\.personID))

        case .percentage:
            let totalPercentage = shares.reduce(Decimal(0)) { $0 + $1.shareValue }
            guard abs(totalPercentage - 100) <= centTolerance else {
                throw SplitCalculatorError.invalidPercentageTotal(total: totalPercentage)
            }
            let raw = shares.map { share in
                (share.personID, (lineTotal * share.shareValue / 100).rounded(scale: 2, .down))
            }
            return reconcileRemainder(lineTotal: lineTotal, amounts: raw)

        case .exactAmount:
            let sum = shares.reduce(Decimal(0)) { $0 + $1.shareValue }
            guard abs(sum - lineTotal) <= centTolerance else {
                throw SplitCalculatorError.exactAmountsDoNotReconcile(expected: lineTotal, actual: sum)
            }
            var result: [UUID: Decimal] = [:]
            for share in shares { result[share.personID] = share.shareValue }
            return result
        }
    }

    private static func splitEqually(lineTotal: Decimal, personIDs: [UUID]) -> [UUID: Decimal] {
        let count = Decimal(personIDs.count)
        let base = (lineTotal / count).rounded(scale: 2, .down)
        return reconcileRemainder(lineTotal: lineTotal, amounts: personIDs.map { ($0, base) })
    }

    /// Distributes leftover pennies (from rounding down) one at a time, in order,
    /// so the sum of resolved amounts always equals `lineTotal` exactly.
    private static func reconcileRemainder(lineTotal: Decimal, amounts: [(UUID, Decimal)]) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        var order: [UUID] = []
        for (id, amount) in amounts {
            result[id] = amount
            order.append(id)
        }

        let assigned = amounts.reduce(Decimal(0)) { $0 + $1.1 }
        var remainder = lineTotal - assigned
        var index = 0
        while remainder >= cent && index < order.count {
            result[order[index], default: 0] += cent
            remainder -= cent
            index += 1
        }
        return result
    }
}
