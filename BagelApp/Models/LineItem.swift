import Foundation
import SwiftData

@Model
final class LineItem {
    @Attribute(.unique) var id: UUID
    var itemDescription: String
    var unitPrice: Decimal
    /// Double rather than Int to support fractional units (e.g. 0.5 lb of produce).
    var quantity: Double
    /// Stored explicitly rather than derived, since the LLM reports the line total
    /// directly and it may not equal unitPrice * quantity exactly (e.g. discounts).
    var lineTotal: Decimal
    var sortOrder: Int

    var document: ExpenseDocument?
    var category: Category?

    @Relationship(deleteRule: .cascade, inverse: \ItemAssignment.lineItem)
    var assignments: [ItemAssignment] = []

    init(
        id: UUID = UUID(),
        itemDescription: String,
        unitPrice: Decimal,
        quantity: Double = 1,
        lineTotal: Decimal,
        sortOrder: Int = 0,
        document: ExpenseDocument? = nil,
        category: Category? = nil
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.lineTotal = lineTotal
        self.sortOrder = sortOrder
        self.document = document
        self.category = category
    }
}
