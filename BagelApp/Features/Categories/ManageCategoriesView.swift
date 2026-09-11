import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var categoryToEdit: ExpenseCategory?
    @State private var isPresentingNewCategory = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    categoryToEdit = category
                } label: {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewCategory) {
            CategoryEditView(category: nil)
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditView(category: category)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            guard !category.isSystemDefault else { continue }
            modelContext.delete(category)
        }
    }
}

private struct CategoryRow: View {
    let category: ExpenseCategory

    var body: some View {
        HStack {
            Image(systemName: category.iconSystemName)
                .foregroundStyle(Color(hex: category.colorHex))
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(category.name)
            if category.isSystemDefault {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Default category")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
