import Foundation
import SwiftData
import BagelCore

/// Turns a parsed receipt into a persisted `ExpenseDocument` + `LineItem`s.
enum ReceiptPersister {
    /// Matches each line item's LLM-suggested category to an existing `Category` by
    /// case-insensitive name (falling back to "Other") so free-text suggestions don't
    /// fragment the category list with near-duplicates.
    static func persist(
        _ parsed: ParsedReceipt,
        rawOCRText: String,
        payer: Person?,
        categories: [Category],
        in context: ModelContext
    ) -> ExpenseDocument {
        let document = ExpenseDocument(
            merchantName: parsed.merchant.isEmpty ? "Unknown Merchant" : parsed.merchant,
            documentDate: parsed.date ?? .now,
            documentType: parsed.documentType == .statement ? .statement : .receipt,
            totalAmount: parsed.total,
            currencyCode: parsed.currencyCode,
            rawOCRText: rawOCRText,
            parseStatus: (parsed.reconciles && parsed.confidence != .low) ? .success : .needsReview,
            payer: payer
        )
        context.insert(document)

        let fallbackCategory = categories.first { $0.name.caseInsensitiveCompare("Other") == .orderedSame }

        for (index, item) in parsed.lineItems.enumerated() {
            let matchedCategory = categories.first {
                $0.name.caseInsensitiveCompare(item.suggestedCategory) == .orderedSame
            } ?? fallbackCategory

            let lineItem = LineItem(
                itemDescription: item.itemDescription,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                lineTotal: item.lineTotal,
                sortOrder: index,
                document: document,
                category: matchedCategory
            )
            context.insert(lineItem)
            document.lineItems.append(lineItem)
        }

        try? context.save()
        return document
    }
}
