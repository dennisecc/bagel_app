import XCTest
import SwiftData
import BagelCore
@testable import BagelApp

final class ReceiptPersisterTests: XCTestCase {
    func testPersistMatchesCategoryCaseInsensitivelyAndFallsBackToOther() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let categories = try context.fetch(FetchDescriptor<Category>())

        let parsed = ParsedReceipt(
            merchant: "Corner Store",
            date: .now,
            documentType: .receipt,
            currencyCode: "USD",
            lineItems: [
                ParsedLineItem(itemDescription: "Milk", quantity: 1, unitPrice: 3.50, lineTotal: 3.50, suggestedCategory: "groceries"),
                ParsedLineItem(itemDescription: "Mystery Fee", quantity: 1, unitPrice: 1, lineTotal: 1, suggestedCategory: "Nonexistent Category")
            ],
            total: 4.50,
            confidence: .high
        )

        let document = ReceiptPersister.persist(parsed, rawOCRText: "raw", payer: nil, categories: categories, in: context)

        XCTAssertEqual(document.lineItems.count, 2)
        let milk = try XCTUnwrap(document.lineItems.first { $0.itemDescription == "Milk" })
        XCTAssertEqual(milk.category?.name, "Groceries")

        let fee = try XCTUnwrap(document.lineItems.first { $0.itemDescription == "Mystery Fee" })
        XCTAssertEqual(fee.category?.name, "Other")

        XCTAssertEqual(document.parseStatus, .success)
    }

    func testPersistFlagsNeedsReviewWhenTotalsDontReconcile() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let categories = try context.fetch(FetchDescriptor<Category>())

        let parsed = ParsedReceipt(
            merchant: "Corner Store",
            date: .now,
            documentType: .receipt,
            currencyCode: "USD",
            lineItems: [
                ParsedLineItem(itemDescription: "Milk", quantity: 1, unitPrice: 3.50, lineTotal: 3.50, suggestedCategory: "Groceries")
            ],
            total: 10.00,
            confidence: .high
        )

        let document = ReceiptPersister.persist(parsed, rawOCRText: "raw", payer: nil, categories: categories, in: context)
        XCTAssertEqual(document.parseStatus, .needsReview)
    }

    func testPersistFlagsNeedsReviewWhenConfidenceLow() throws {
        let container = ModelContainerFactory.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let categories = try context.fetch(FetchDescriptor<Category>())

        let parsed = ParsedReceipt(
            merchant: "Corner Store",
            date: .now,
            documentType: .receipt,
            currencyCode: "USD",
            lineItems: [
                ParsedLineItem(itemDescription: "Milk", quantity: 1, unitPrice: 3.50, lineTotal: 3.50, suggestedCategory: "Groceries")
            ],
            total: 3.50,
            confidence: .low
        )

        let document = ReceiptPersister.persist(parsed, rawOCRText: "raw", payer: nil, categories: categories, in: context)
        XCTAssertEqual(document.parseStatus, .needsReview)
    }
}
