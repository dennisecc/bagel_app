import Foundation
import SwiftData

enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            Person.self,
            ExpenseCategory.self,
            ExpenseDocument.self,
            LineItem.self,
            ItemAssignment.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // `container.mainContext` is @MainActor-isolated; this function is called from
        // BagelAppApp's stored-property initializer and from test code, neither of which
        // is guaranteed to be on the main actor. A freshly created ModelContext writes to
        // the same persistent store without requiring actor isolation.
        seedDefaultsIfNeeded(in: ModelContext(container))
        return container
    }

    /// Seeds the "Me" owner person and the default category set on first launch.
    /// Safe to call on every launch — it's a no-op once seeding has happened.
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        seedDefaultOwnerIfNeeded(in: context)
        seedDefaultCategoriesIfNeeded(in: context)
    }

    private static func seedDefaultOwnerIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.isDefaultOwner })
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let me = Person(name: "Me", colorHex: "#4A90D9", isDefaultOwner: true)
        context.insert(me)
        try? context.save()
    }

    private static func seedDefaultCategoriesIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isSystemDefault })
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, defaults) in defaultCategories.enumerated() {
            let category = ExpenseCategory(
                name: defaults.name,
                iconSystemName: defaults.icon,
                colorHex: defaults.colorHex,
                isSystemDefault: true,
                sortOrder: index
            )
            context.insert(category)
        }
        try? context.save()
    }

    private static let defaultCategories: [(name: String, icon: String, colorHex: String)] = [
        ("Groceries", "cart.fill", "#5FAD56"),
        ("Dining", "fork.knife", "#F2994A"),
        ("Transport", "car.fill", "#2D9CDB"),
        ("Utilities", "bolt.fill", "#F2C94C"),
        ("Entertainment", "film.fill", "#BB6BD9"),
        ("Shopping", "bag.fill", "#EB5757"),
        ("Bills / Statements", "doc.text.fill", "#828282"),
        ("Other", "questionmark.circle.fill", "#9B9B9B")
    ]
}
