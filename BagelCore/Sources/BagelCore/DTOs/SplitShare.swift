import Foundation

/// How a single line item's cost is divided among the people assigned to it.
public enum ShareType: String, Codable, Sendable {
    /// Split evenly across every assigned person.
    case equal
    /// `shareValue` is a percentage (0-100) of the line total.
    case percentage
    /// `shareValue` is the exact dollar amount owed by this person.
    case exactAmount
}

/// One person's stake in a line item, before amounts are resolved.
/// All shares for a given line item must share the same `type`.
public struct SplitShare: Sendable, Equatable {
    public var personID: UUID
    public var type: ShareType
    /// Meaningful only for `.percentage` and `.exactAmount`; ignored for `.equal`.
    public var shareValue: Decimal

    public init(personID: UUID, type: ShareType, shareValue: Decimal = 0) {
        self.personID = personID
        self.type = type
        self.shareValue = shareValue
    }
}
