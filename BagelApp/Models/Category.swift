import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconSystemName: String
    var colorHex: String
    /// Seeded categories can be renamed but never deleted; user-created ones can be both.
    var isSystemDefault: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \LineItem.category)
    var lineItems: [LineItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconSystemName: String,
        colorHex: String,
        isSystemDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
        self.isSystemDefault = isSystemDefault
        self.sortOrder = sortOrder
    }
}
