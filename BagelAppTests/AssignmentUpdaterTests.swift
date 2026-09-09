import XCTest
import SwiftData
import BagelCore
@testable import BagelApp

final class AssignmentUpdaterTests: XCTestCase {
    func testApplyEqualSplitCreatesAssignmentsSummingToLineTotal() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let alice = Person(name: "Alice", colorHex: "#000000")
        let bob = Person(name: "Bob", colorHex: "#000000")
        context.insert(alice)
        context.insert(bob)

        let document = ExpenseDocument(merchantName: "Test", documentDate: .now, documentType: .receipt, totalAmount: 10, rawOCRText: "")
        context.insert(document)
        let item = LineItem(itemDescription: "Item", unitPrice: 10, lineTotal: 10, document: document)
        context.insert(item)

        AssignmentUpdater.applyEqualSplit(to: item, people: [alice, bob], in: context)

        XCTAssertEqual(item.assignments.count, 2)
        XCTAssertEqual(item.assignments.reduce(Decimal(0)) { $0 + $1.computedAmount }, 10)
    }

    func testApplyReplacesExistingAssignments() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let alice = Person(name: "Alice", colorHex: "#000000")
        let bob = Person(name: "Bob", colorHex: "#000000")
        context.insert(alice)
        context.insert(bob)

        let document = ExpenseDocument(merchantName: "Test", documentDate: .now, documentType: .receipt, totalAmount: 10, rawOCRText: "")
        context.insert(document)
        let item = LineItem(itemDescription: "Item", unitPrice: 10, lineTotal: 10, document: document)
        context.insert(item)

        AssignmentUpdater.applyEqualSplit(to: item, people: [alice, bob], in: context)
        XCTAssertEqual(item.assignments.count, 2)

        try AssignmentUpdater.apply(
            shares: [SplitShare(personID: alice.id, type: .exactAmount, shareValue: 10)],
            to: item,
            people: [alice, bob],
            in: context
        )

        XCTAssertEqual(item.assignments.count, 1)
        XCTAssertEqual(item.assignments.first?.person?.id, alice.id)
        XCTAssertEqual(item.assignments.first?.computedAmount, 10)
    }
}
