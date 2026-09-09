import Foundation

/// The system prompt and tool schema used to structure OCR text into a `ParsedReceipt`.
/// Kept as one static definition rather than building it per-request, since the schema
/// itself never changes — only the OCR text and known-category list are per-request.
enum ReceiptParsingPrompt {
    static let toolName = "record_receipt"

    static let systemPrompt = """
    You extract structured, itemized data from OCR text scanned from a retail receipt \
    or a bank/credit-card statement. The OCR text may contain artifacts: misread \
    characters, dropped line breaks, or extraneous header/footer text (store address, \
    barcodes, "thank you" messages) — ignore anything that isn't merchant info, a \
    date, line items, or a total.

    Rules:
    - Every currency amount (unitPrice, lineTotal, total) MUST be a decimal string \
    like "12.99", never a JSON number, to avoid floating-point rounding errors.
    - For a bank/credit-card statement, treat each transaction as one line item; use \
    the statement issuer or account name as the merchant, and "statement" as the \
    documentType.
    - For a retail receipt, treat each purchased product as one line item and \
    "receipt" as the documentType.
    - suggestedCategory should reuse one of the app's existing category names when an \
    item clearly fits one of them; otherwise propose a short, plain-English category name.
    - If the document's date isn't legible, omit the date field entirely rather than guessing.
    - Set confidence to "low" whenever the OCR text is garbled, the total doesn't clearly \
    match the sum of line items, or you had to guess at more than a couple of fields.
    """

    /// input_schema uses JSON Schema's own "description" keyword for docs on individual
    /// properties — that's unrelated to `ParsedLineItem.itemDescription`, which is
    /// deliberately named "description" here to match plain-English receipt vocabulary.
    static let toolSchema: [String: Any] = [
        "name": toolName,
        "description": "Records the structured, itemized contents of a scanned receipt or statement.",
        "input_schema": [
            "type": "object",
            "properties": [
                "merchant": [
                    "type": "string",
                    "description": "The merchant, store, or statement issuer name."
                ],
                "date": [
                    "type": "string",
                    "description": "Document date as YYYY-MM-DD. Omit this field entirely if illegible."
                ],
                "documentType": [
                    "type": "string",
                    "enum": ["receipt", "statement"]
                ],
                "currencyCode": [
                    "type": "string",
                    "description": "ISO 4217 currency code, e.g. USD."
                ],
                "lineItems": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "description": ["type": "string"],
                            "quantity": [
                                "type": "number",
                                "description": "Defaults to 1 if not itemized separately."
                            ],
                            "unitPrice": [
                                "type": "string",
                                "description": "Decimal string, e.g. \"4.50\"."
                            ],
                            "lineTotal": [
                                "type": "string",
                                "description": "Decimal string, e.g. \"9.00\"."
                            ],
                            "suggestedCategory": ["type": "string"]
                        ],
                        "required": ["description", "unitPrice", "lineTotal", "suggestedCategory"]
                    ]
                ],
                "total": [
                    "type": "string",
                    "description": "Decimal string for the document's grand total."
                ],
                "confidence": [
                    "type": "string",
                    "enum": ["high", "medium", "low"]
                ]
            ],
            "required": ["merchant", "documentType", "currencyCode", "lineItems", "total", "confidence"]
        ]
    ]

    static func userMessage(ocrText: String, knownCategories: [String]) -> String {
        var message = "Raw OCR text scanned from a document:\n\n\(ocrText)"
        if !knownCategories.isEmpty {
            message += "\n\nExisting categories in this app (prefer reusing one of these for suggestedCategory when it fits): \(knownCategories.joined(separator: ", "))."
        }
        return message
    }
}
