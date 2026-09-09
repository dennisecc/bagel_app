import Foundation
import SwiftData
import BagelCore

/// Join entity between a `LineItem` and a `Person`, carrying that person's share
/// of the item's cost. This is the finest-grained unit both split math and
/// settlement balances are computed from.
@Model
final class ItemAssignment {
    @Attribute(.unique) var id: UUID
    var shareType: ShareType
    /// Percentage (0-100) or exact amount, depending on `shareType`; unused for `.equal`.
    var shareValue: Decimal
    /// Cached result of `SplitCalculator`, recomputed whenever a line item's
    /// assignments change. Keeps balance/insight queries cheap sums instead of
    /// re-running split math on every read.
    var computedAmount: Decimal

    var lineItem: LineItem?
    var person: Person?

    init(
        id: UUID = UUID(),
        shareType: ShareType,
        shareValue: Decimal = 0,
        computedAmount: Decimal,
        lineItem: LineItem? = nil,
        person: Person? = nil
    ) {
        self.id = id
        self.shareType = shareType
        self.shareValue = shareValue
        self.computedAmount = computedAmount
        self.lineItem = lineItem
        self.person = person
    }
}
