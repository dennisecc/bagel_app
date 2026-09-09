import XCTest
import SwiftData
@testable import BagelApp

final class PersistenceTests: XCTestCase {
    func testContainerSeedsDefaultOwnerAndCategories() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext

        let people = try context.fetch(FetchDescriptor<Person>())
        XCTAssertEqual(people.count, 1)
        XCTAssertEqual(people.first?.name, "Me")
        XCTAssertTrue(people.first?.isDefaultOwner ?? false)

        let categories = try context.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(categories.count, 8)
        XCTAssertTrue(categories.allSatisfy(\.isSystemDefault))
    }

    func testSeedingIsIdempotent() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext

        ModelContainerFactory.seedDefaultsIfNeeded(in: context)
        ModelContainerFactory.seedDefaultsIfNeeded(in: context)

        let people = try context.fetch(FetchDescriptor<Person>())
        let categories = try context.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(people.count, 1)
        XCTAssertEqual(categories.count, 8)
    }

    func testLineItemAssignmentPersistsAndComputesBalance() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext

        let me = try XCTUnwrap(try context.fetch(FetchDescriptor<Person>()).first)
        let friend = Person(name: "Friend", colorHex: "#EB5757")
        context.insert(friend)

        let category = try XCTUnwrap(try context.fetch(FetchDescriptor<Category>()).first)

        let document = ExpenseDocument(
            merchantName: "Test Cafe",
            documentDate: .now,
            documentType: .receipt,
            totalAmount: 20,
            rawOCRText: "raw text",
            payer: me
        )
        context.insert(document)

        let item = LineItem(itemDescription: "Coffee", unitPrice: 20, lineTotal: 20, document: document, category: category)
        context.insert(item)

        let assignment = ItemAssignment(shareType: .exactAmount, shareValue: 10, computedAmount: 10, lineItem: item, person: friend)
        context.insert(assignment)

        try context.save()

        let savedItems = try context.fetch(FetchDescriptor<LineItem>())
        XCTAssertEqual(savedItems.first?.assignments.count, 1)
        XCTAssertEqual(savedItems.first?.assignments.first?.computedAmount, 10)
    }
}
