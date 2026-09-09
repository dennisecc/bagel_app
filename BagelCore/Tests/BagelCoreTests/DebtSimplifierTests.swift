import XCTest
@testable import BagelCore

final class DebtSimplifierTests: XCTestCase {
    func testSimpleTwoPersonDebt() {
        let alice = UUID(); let bob = UUID()
        let balances = [
            Balance(personID: alice, netAmount: 50),
            Balance(personID: bob, netAmount: -50)
        ]
        let transactions = DebtSimplifier.simplify(balances: balances)

        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].from, bob)
        XCTAssertEqual(transactions[0].to, alice)
        XCTAssertEqual(transactions[0].amount, 50)
    }

    func testThreePersonSettlesInTwoTransactions() {
        // Alice paid for everyone; Bob and Carol each owe a share.
        let alice = UUID(); let bob = UUID(); let carol = UUID()
        let balances = [
            Balance(personID: alice, netAmount: 40),
            Balance(personID: bob, netAmount: -20),
            Balance(personID: carol, netAmount: -20)
        ]
        let transactions = DebtSimplifier.simplify(balances: balances)

        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(transactions.reduce(0) { $0 + $1.amount }, 40)
        XCTAssertTrue(transactions.allSatisfy { $0.to == alice })
    }

    func testZeroBalancesProduceNoTransactions() {
        let alice = UUID(); let bob = UUID()
        let balances = [
            Balance(personID: alice, netAmount: 0),
            Balance(personID: bob, netAmount: 0)
        ]
        XCTAssertEqual(DebtSimplifier.simplify(balances: balances), [])
    }

    func testFourPersonMinimizesTransactionCount() {
        // A owes 30, B owes 10, C is owed 15, D is owed 25 -> net zero-sum, should
        // resolve in at most 3 transactions (n-1 people needing settlement).
        let a = UUID(); let b = UUID(); let c = UUID(); let d = UUID()
        let balances = [
            Balance(personID: a, netAmount: -30),
            Balance(personID: b, netAmount: -10),
            Balance(personID: c, netAmount: 15),
            Balance(personID: d, netAmount: 25)
        ]
        let transactions = DebtSimplifier.simplify(balances: balances)

        let totalMoved = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        XCTAssertEqual(totalMoved, 40)
        XCTAssertLessThanOrEqual(transactions.count, 3)

        // Verify resulting net effect matches the original balances exactly.
        var resultingNet: [UUID: Decimal] = [a: 0, b: 0, c: 0, d: 0]
        for tx in transactions {
            resultingNet[tx.from, default: 0] -= tx.amount
            resultingNet[tx.to, default: 0] += tx.amount
        }
        XCTAssertEqual(resultingNet[a], -30)
        XCTAssertEqual(resultingNet[b], -10)
        XCTAssertEqual(resultingNet[c], 15)
        XCTAssertEqual(resultingNet[d], 25)
    }

    func testComputeNetBalancesCombinesPaidAndOwed() {
        let alice = UUID(); let bob = UUID()
        let balances = DebtSimplifier.computeNetBalances(
            totalPaidByPerson: [alice: 100],
            totalOwedByPerson: [alice: 40, bob: 60]
        )
        let alicesBalance = balances.first { $0.personID == alice }
        let bobsBalance = balances.first { $0.personID == bob }

        XCTAssertEqual(alicesBalance?.netAmount, 60)
        XCTAssertEqual(bobsBalance?.netAmount, -60)
    }
}
