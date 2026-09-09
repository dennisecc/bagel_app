import Foundation
import BagelCore

enum ReceiptParsingError: LocalizedError {
    case emptyOCRText
    case network(underlying: Error)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .emptyOCRText:
            return "Couldn't read any text from this document. Try rescanning with better lighting."
        case .network:
            return "Couldn't reach the parsing service. Check your connection and try again."
        case .malformedResponse:
            return "The parser returned something we couldn't understand."
        }
    }
}

/// Orchestrates turning raw OCR text into a `ParsedReceipt`: builds the prompt, calls
/// the LLM, and decodes its tool-use response. This is the only place that knows about
/// the wire format of the Anthropic tool response.
struct ReceiptParsingService {
    private let client: AnthropicClient

    init(client: AnthropicClient) {
        self.client = client
    }

    func parse(ocrText: String, knownCategories: [String] = []) async throws -> ParsedReceipt {
        let trimmed = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReceiptParsingError.emptyOCRText }

        let input = try await requestWithRetry(ocrText: trimmed, knownCategories: knownCategories)
        return try Self.decode(input)
    }

    /// Overridable so tests don't have to wait out a real backoff.
    static var retryDelayNanoseconds: UInt64 = 1_500_000_000

    /// One automatic retry with a short backoff for transient network/API errors, per
    /// the plan's error-handling design. A malformed response isn't retried since
    /// retrying the same OCR text against the same model won't fix a decoding problem.
    private func requestWithRetry(ocrText: String, knownCategories: [String]) async throws -> [String: Any] {
        do {
            return try await sendRequest(ocrText: ocrText, knownCategories: knownCategories)
        } catch AnthropicClientError.malformedResponse {
            throw ReceiptParsingError.malformedResponse
        } catch {
            try? await Task.sleep(nanoseconds: Self.retryDelayNanoseconds)
            do {
                return try await sendRequest(ocrText: ocrText, knownCategories: knownCategories)
            } catch AnthropicClientError.malformedResponse {
                throw ReceiptParsingError.malformedResponse
            } catch {
                throw ReceiptParsingError.network(underlying: error)
            }
        }
    }

    private func sendRequest(ocrText: String, knownCategories: [String]) async throws -> [String: Any] {
        try await client.sendToolUseRequest(
            system: ReceiptParsingPrompt.systemPrompt,
            userMessage: ReceiptParsingPrompt.userMessage(ocrText: ocrText, knownCategories: knownCategories),
            tool: ReceiptParsingPrompt.toolSchema,
            toolName: ReceiptParsingPrompt.toolName
        )
    }

    private static func decode(_ input: [String: Any]) throws -> ParsedReceipt {
        guard
            let merchant = input["merchant"] as? String,
            let documentTypeRaw = input["documentType"] as? String,
            let documentType = ParsedDocumentType(rawValue: documentTypeRaw),
            let currencyCode = input["currencyCode"] as? String,
            let totalString = input["total"] as? String,
            let total = Decimal(string: totalString),
            let confidenceRaw = input["confidence"] as? String,
            let confidence = ParsedConfidence(rawValue: confidenceRaw),
            let lineItemsRaw = input["lineItems"] as? [[String: Any]]
        else {
            throw ReceiptParsingError.malformedResponse
        }

        let date = (input["date"] as? String).flatMap { dateFormatter.date(from: $0) }
        let lineItems = try lineItemsRaw.map(decodeLineItem)

        return ParsedReceipt(
            merchant: merchant,
            date: date,
            documentType: documentType,
            currencyCode: currencyCode,
            lineItems: lineItems,
            total: total,
            confidence: confidence
        )
    }

    private static func decodeLineItem(_ raw: [String: Any]) throws -> ParsedLineItem {
        guard
            let description = raw["description"] as? String,
            let unitPriceString = raw["unitPrice"] as? String,
            let unitPrice = Decimal(string: unitPriceString),
            let lineTotalString = raw["lineTotal"] as? String,
            let lineTotal = Decimal(string: lineTotalString),
            let suggestedCategory = raw["suggestedCategory"] as? String
        else {
            throw ReceiptParsingError.malformedResponse
        }
        let quantity = (raw["quantity"] as? NSNumber)?.doubleValue ?? 1
        return ParsedLineItem(
            itemDescription: description,
            quantity: quantity,
            unitPrice: unitPrice,
            lineTotal: lineTotal,
            suggestedCategory: suggestedCategory
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
