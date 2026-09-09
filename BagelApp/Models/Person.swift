import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    /// Marks the single "Me" person seeded at first launch, representing the app's owner.
    var isDefaultOwner: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ExpenseDocument.payer)
    var expensesPaid: [ExpenseDocument] = []

    @Relationship(deleteRule: .cascade, inverse: \ItemAssignment.person)
    var assignments: [ItemAssignment] = []

    init(id: UUID = UUID(), name: String, colorHex: String, isDefaultOwner: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isDefaultOwner = isDefaultOwner
        self.createdAt = createdAt
    }
}
