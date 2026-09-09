import Foundation

enum AnthropicClientError: Error {
    case httpError(statusCode: Int, body: String?)
    case malformedResponse
}

/// The only place in the app touching `URLSession`/the API key directly — views and
/// view models never import networking types, only call through `ReceiptParsingService`.
struct AnthropicClient {
    private let apiKey: String
    private let session: URLSession

    /// Sonnet 5, not Haiku, since statements/receipts vary a lot in layout and this
    /// is a one-shot extraction with no chance for the user to correct a bad guess
    /// before it lands in the review screen. Swap to a cheaper model here if cost
    /// becomes a concern.
    private static let model = "claude-sonnet-5"
    private static let apiVersion = "2023-06-01"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Sends a single-turn request that forces the model to respond via the named
    /// tool, and returns that tool call's `input` payload. Using tool-use (rather
    /// than free-text JSON prompting) guarantees schema-conformant output and avoids
    /// markdown-fencing/prose-wrapping parsing issues.
    func sendToolUseRequest(
        system: String,
        userMessage: String,
        tool: [String: Any],
        toolName: String
    ) async throws -> [String: Any] {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": 4096,
            "system": system,
            "messages": [["role": "user", "content": userMessage]],
            "tools": [tool],
            "tool_choice": ["type": "tool", "name": toolName]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AnthropicClientError.httpError(statusCode: statusCode, body: String(data: data, encoding: .utf8))
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let toolUse = content.first(where: { ($0["type"] as? String) == "tool_use" && ($0["name"] as? String) == toolName }),
            let input = toolUse["input"] as? [String: Any]
        else {
            throw AnthropicClientError.malformedResponse
        }
        return input
    }
}
