import Foundation
import SwiftData

enum DocumentType: String, Codable {
    case receipt
    case statement
}

enum ParseStatus: String, Codable {
    case pending
    case success
    case needsReview
    case failed
}

@Model
final class ExpenseDocument {
    @Attribute(.unique) var id: UUID
    var merchantName: String
    var documentDate: Date
    var documentType: DocumentType
    var totalAmount: Decimal
    var currencyCode: String
    /// Optional thumbnail/original image, kept for user reference.
    @Attribute(.externalStorage) var sourceImageData: Data?
    /// Audit trail of what Vision extracted, so a failed/needs-review parse can be retried
    /// against the LLM without forcing the user to rescan.
    var rawOCRText: String
    /// Audit trail of the LLM's raw response, kept for debugging malformed parses.
    var rawLLMResponse: String?
    var parseStatus: ParseStatus
    var createdAt: Date

    var payer: Person?

    @Relationship(deleteRule: .cascade, inverse: \LineItem.document)
    var lineItems: [LineItem] = []

    init(
        id: UUID = UUID(),
        merchantName: String,
        documentDate: Date,
        documentType: DocumentType,
        totalAmount: Decimal,
        currencyCode: String = "USD",
        sourceImageData: Data? = nil,
        rawOCRText: String,
        rawLLMResponse: String? = nil,
        parseStatus: ParseStatus = .pending,
        payer: Person? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.merchantName = merchantName
        self.documentDate = documentDate
        self.documentType = documentType
        self.totalAmount = totalAmount
        self.currencyCode = currencyCode
        self.sourceImageData = sourceImageData
        self.rawOCRText = rawOCRText
        self.rawLLMResponse = rawLLMResponse
        self.parseStatus = parseStatus
        self.payer = payer
        self.createdAt = createdAt
    }
}
