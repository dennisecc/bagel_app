import XCTest
@testable import BagelCore

final class SplitCalculatorTests: XCTestCase {
    func testEqualSplitOddTotalThreeWaysSumsExactly() throws {
        let people = [UUID(), UUID(), UUID()]
        let shares = people.map { SplitShare(personID: $0, type: .equal) }
        let amounts = try SplitCalculator.computeAmounts(lineTotal: Decimal(string: "10.00")!, shares: shares)

        XCTAssertEqual(amounts.values.reduce(0, +), Decimal(string: "10.00")!)
        // $10.00 / 3 = $3.33 base; one person absorbs the extra cent.
        let sorted = amounts.values.sorted()
        XCTAssertEqual(sorted, [Decimal(string: "3.33")!, Decimal(string: "3.33")!, Decimal(string: "3.34")!])
    }

    func testEqualSplitTwoWaysEvenTotal() throws {
        let people = [UUID(), UUID()]
        let shares = people.map { SplitShare(personID: $0, type: .equal) }
        let amounts = try SplitCalculator.computeAmounts(lineTotal: Decimal(string: "20.00")!, shares: shares)

        XCTAssertEqual(Set(amounts.values), [Decimal(string: "10.00")!])
    }

    func testPercentageSplitReconciles() throws {
        let a = UUID(); let b = UUID()
        let shares = [
            SplitShare(personID: a, type: .percentage, shareValue: 70),
            SplitShare(personID: b, type: .percentage, shareValue: 30)
        ]
        let amounts = try SplitCalculator.computeAmounts(lineTotal: Decimal(string: "9.99")!, shares: shares)

        XCTAssertEqual(amounts.values.reduce(0, +), Decimal(string: "9.99")!)
    }

    func testPercentageSplitRejectsNonHundredTotal() {
        let a = UUID(); let b = UUID()
        let shares = [
            SplitShare(personID: a, type: .percentage, shareValue: 70),
            SplitShare(personID: b, type: .percentage, shareValue: 20)
        ]
        XCTAssertThrowsError(try SplitCalculator.computeAmounts(lineTotal: 10, shares: shares)) { error in
            XCTAssertEqual(error as? SplitCalculatorError, .invalidPercentageTotal(total: 90))
        }
    }

    func testExactAmountAcceptsReconcilingShares() throws {
        let a = UUID(); let b = UUID()
        let shares = [
            SplitShare(personID: a, type: .exactAmount, shareValue: Decimal(string: "6.50")!),
            SplitShare(personID: b, type: .exactAmount, shareValue: Decimal(string: "3.50")!)
        ]
        let amounts = try SplitCalculator.computeAmounts(lineTotal: 10, shares: shares)
        XCTAssertEqual(amounts[a], Decimal(string: "6.50")!)
        XCTAssertEqual(amounts[b], Decimal(string: "3.50")!)
    }

    func testExactAmountRejectsNonReconcilingShares() {
        let a = UUID(); let b = UUID()
        let shares = [
            SplitShare(personID: a, type: .exactAmount, shareValue: Decimal(string: "6.00")!),
            SplitShare(personID: b, type: .exactAmount, shareValue: Decimal(string: "3.00")!)
        ]
        XCTAssertThrowsError(try SplitCalculator.computeAmounts(lineTotal: 10, shares: shares))
    }

    func testEmptySharesThrows() {
        XCTAssertThrowsError(try SplitCalculator.computeAmounts(lineTotal: 10, shares: [])) { error in
            XCTAssertEqual(error as? SplitCalculatorError, .emptyShares)
        }
    }

    func testMixedShareTypesThrows() {
        let a = UUID(); let b = UUID()
        let shares = [
            SplitShare(personID: a, type: .equal),
            SplitShare(personID: b, type: .exactAmount, shareValue: 5)
        ]
        XCTAssertThrowsError(try SplitCalculator.computeAmounts(lineTotal: 10, shares: shares)) { error in
            XCTAssertEqual(error as? SplitCalculatorError, .mixedShareTypes)
        }
    }
}
