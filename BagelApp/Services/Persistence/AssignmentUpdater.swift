import Foundation
import SwiftData
import BagelCore

/// Recomputes and replaces a line item's `ItemAssignment`s whenever its split changes,
/// keeping `ItemAssignment.computedAmount` in sync with `SplitCalculator`.
enum AssignmentUpdater {
    /// Deletes the line item's existing assignments and replaces them with fresh ones
    /// computed from `shares`, so people removed from the split don't linger with stale amounts.
    static func apply(shares: [SplitShare], to lineItem: LineItem, people: [Person], in context: ModelContext) throws {
        let amounts = try SplitCalculator.computeAmounts(lineTotal: lineItem.lineTotal, shares: shares)

        for existing in lineItem.assignments {
            context.delete(existing)
        }
        lineItem.assignments.removeAll()

        for share in shares {
            guard let person = people.first(where: { $0.id == share.personID }) else { continue }
            let assignment = ItemAssignment(
                shareType: share.type,
                shareValue: share.shareValue,
                computedAmount: amounts[share.personID] ?? 0,
                lineItem: lineItem,
                person: person
            )
            context.insert(assignment)
            lineItem.assignments.append(assignment)
        }
    }

    /// Convenience for the "assign all to me" / "split evenly" bulk shortcuts.
    static func applyEqualSplit(to lineItem: LineItem, people: [Person], in context: ModelContext) {
        guard !people.isEmpty else { return }
        let shares = people.map { SplitShare(personID: $0.id, type: .equal) }
        try? apply(shares: shares, to: lineItem, people: people, in: context)
    }
}
