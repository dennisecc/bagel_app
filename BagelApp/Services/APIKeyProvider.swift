import Foundation

/// Reads secrets injected into Info.plist via `Secrets.xcconfig` at build time
/// (see `Secrets.xcconfig.example`), so no key is ever hardcoded or committed.
enum APIKeyProvider {
    enum APIKeyError: LocalizedError {
        case missing

        var errorDescription: String? {
            "No Anthropic API key is configured. Copy Secrets.xcconfig.example to Secrets.xcconfig, add your key, and rebuild."
        }
    }

    static func anthropicAPIKey() throws -> String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
            !key.isEmpty,
            key != "your-api-key-here"
        else {
            throw APIKeyError.missing
        }
        return key
    }
}
