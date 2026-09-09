import SwiftUI

extension Color {
    /// Parses a "#RRGGBB" string; falls back to gray for malformed input rather
    /// than crashing, since colors are user/LLM-sourced data, not code constants.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized.removeAll { $0 == "#" }

        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            self = .gray
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}
