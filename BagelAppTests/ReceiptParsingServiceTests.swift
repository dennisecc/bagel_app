import XCTest
@testable import BagelApp

final class ReceiptParsingServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ReceiptParsingService.retryDelayNanoseconds = 0
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeService() -> ReceiptParsingService {
        ReceiptParsingService(client: AnthropicClient(apiKey: "test-key", session: MockURLProtocol.makeSession()))
    }

    private static func toolUseResponse(input: [String: Any]) -> Data {
        let json: [String: Any] = [
            "content": [
                ["type": "tool_use", "name": "record_receipt", "input": input]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func testParsesWellFormedToolUseResponse() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = Self.toolUseResponse(input: [
                "merchant": "Corner Store",
                "date": "2026-01-15",
                "documentType": "receipt",
                "currencyCode": "USD",
                "lineItems": [
                    [
                        "description": "Milk",
                        "quantity": 1,
                        "unitPrice": "3.50",
                        "lineTotal": "3.50",
                        "suggestedCategory": "Groceries"
                    ]
                ],
                "total": "3.50",
                "confidence": "high"
            ])
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let parsed = try await makeService().parse(ocrText: "Corner Store\nMilk 3.50\nTotal 3.50")

        XCTAssertEqual(parsed.merchant, "Corner Store")
        XCTAssertEqual(parsed.lineItems.count, 1)
        XCTAssertEqual(parsed.lineItems[0].unitPrice, Decimal(string: "3.50"))
        XCTAssertEqual(parsed.total, Decimal(string: "3.50"))
        XCTAssertTrue(parsed.reconciles)
    }

    func testMalformedToolResponseThrowsWithoutRetrying() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            // Missing required fields (lineItems, total, confidence).
            let data = Self.toolUseResponse(input: ["merchant": "Corner Store"])
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await makeService().parse(ocrText: "some text")
            XCTFail("Expected malformedResponse error")
        } catch ReceiptParsingError.malformedResponse {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
        XCTAssertEqual(callCount, 1, "A semantically malformed (but structurally valid) response shouldn't be retried")
    }

    func testNetworkErrorRetriesOnceThenThrows() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await makeService().parse(ocrText: "some text")
            XCTFail("Expected network error")
        } catch ReceiptParsingError.network {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
        XCTAssertEqual(callCount, 2, "Should retry exactly once on a transient failure")
    }

    func testEmptyOCRTextThrowsWithoutNetworkCall() async {
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not make a network call for empty OCR text")
            throw URLError(.badURL)
        }

        do {
            _ = try await makeService().parse(ocrText: "   \n  ")
            XCTFail("Expected emptyOCRText error")
        } catch ReceiptParsingError.emptyOCRText {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testNonReconcilingResponseIsDecodedButFlaggedByReconciles() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = Self.toolUseResponse(input: [
                "merchant": "Corner Store",
                "documentType": "receipt",
                "currencyCode": "USD",
                "lineItems": [
                    [
                        "description": "Milk",
                        "unitPrice": "3.50",
                        "lineTotal": "3.50",
                        "suggestedCategory": "Groceries"
                    ]
                ],
                "total": "10.00",
                "confidence": "high"
            ])
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let parsed = try await makeService().parse(ocrText: "garbled receipt text")
        XCTAssertFalse(parsed.reconciles)
    }
}
