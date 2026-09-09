import Foundation

/// Lightweight dependency container passed down via SwiftUI's environment, so
/// views never construct services (especially networking ones) directly and
/// stay mockable in tests. Populated incrementally as each service is built.
@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()

    private init() {}

    /// Constructed lazily (not stored) so a missing/placeholder API key doesn't crash
    /// app launch — the error only surfaces when the user actually tries to parse a receipt.
    func makeReceiptParsingService() throws -> ReceiptParsingService {
        let apiKey = try APIKeyProvider.anthropicAPIKey()
        return ReceiptParsingService(client: AnthropicClient(apiKey: apiKey))
    }
}
