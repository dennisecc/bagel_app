import Foundation

/// Reduces a set of per-person net balances to a minimal-ish set of settling
/// transactions, using the standard greedy min-cash-flow heuristic (the same
/// approach Splitwise uses): repeatedly match the biggest creditor against the
/// biggest debtor until every balance is zero.
public enum DebtSimplifier {
    private static let epsilon = Decimal(string: "0.005")!

    /// Combines what each person paid for and what they were assigned across all
    /// expenses into a single net balance per person (positive = owed money).
    public static func computeNetBalances(
        totalPaidByPerson: [UUID: Decimal],
        totalOwedByPerson: [UUID: Decimal]
    ) -> [Balance] {
        let allPeople = Set(totalPaidByPerson.keys).union(totalOwedByPerson.keys)
        return allPeople.map { personID in
            let paid = totalPaidByPerson[personID] ?? 0
            let owed = totalOwedByPerson[personID] ?? 0
            return Balance(personID: personID, netAmount: paid - owed)
        }
    }

    public static func simplify(balances: [Balance]) -> [SettlementTransaction] {
        var creditors = balances
            .filter { $0.netAmount > epsilon }
            .map { (id: $0.personID, amount: $0.netAmount) }
            .sorted { $0.amount > $1.amount }
        var debtors = balances
            .filter { $0.netAmount < -epsilon }
            .map { (id: $0.personID, amount: -$0.netAmount) }
            .sorted { $0.amount > $1.amount }

        var transactions: [SettlementTransaction] = []
        var i = 0
        var j = 0
        while i < creditors.count && j < debtors.count {
            let amount = min(creditors[i].amount, debtors[j].amount)
            if amount > epsilon {
                transactions.append(SettlementTransaction(from: debtors[j].id, to: creditors[i].id, amount: amount))
            }
            creditors[i].amount -= amount
            debtors[j].amount -= amount
            if creditors[i].amount <= epsilon { i += 1 }
            if debtors[j].amount <= epsilon { j += 1 }
        }
        return transactions
    }
}
