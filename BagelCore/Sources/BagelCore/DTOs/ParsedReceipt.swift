import Foundation

/// Confidence the LLM reports in its own extraction, used to decide whether
/// a parse should be auto-accepted or flagged for user review.
public enum ParsedConfidence: String, Codable, Sendable {
    case high
    case medium
    case low
}

public enum ParsedDocumentType: String, Codable, Sendable {
    case receipt
    case statement
}

/// Decoded directly from the LLM's structured (tool-use) response.
public struct ParsedReceipt: Codable, Sendable, Equatable {
    public var merchant: String
    public var date: Date?
    public var documentType: ParsedDocumentType
    public var currencyCode: String
    public var lineItems: [ParsedLineItem]
    public var total: Decimal
    public var confidence: ParsedConfidence

    public init(
        merchant: String,
        date: Date?,
        documentType: ParsedDocumentType,
        currencyCode: String,
        lineItems: [ParsedLineItem],
        total: Decimal,
        confidence: ParsedConfidence
    ) {
        self.merchant = merchant
        self.date = date
        self.documentType = documentType
        self.currencyCode = currencyCode
        self.lineItems = lineItems
        self.total = total
        self.confidence = confidence
    }

    /// Sum of line-item totals, for reconciling against the reported `total`.
    public var lineItemsSum: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.lineTotal }
    }

    /// True when the reported total and the sum of line items agree within a cent,
    /// and there's at least one line item. Used to decide `.needsReview` vs `.success`.
    public var reconciles: Bool {
        guard !lineItems.isEmpty else { return false }
        return abs(lineItemsSum - total) <= Decimal(string: "0.01")!
    }
}

public struct ParsedLineItem: Codable, Sendable, Equatable {
    public var itemDescription: String
    public var quantity: Double
    public var unitPrice: Decimal
    public var lineTotal: Decimal
    public var suggestedCategory: String

    public init(
        itemDescription: String,
        quantity: Double,
        unitPrice: Decimal,
        lineTotal: Decimal,
        suggestedCategory: String
    ) {
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
        self.suggestedCategory = suggestedCategory
    }
}
