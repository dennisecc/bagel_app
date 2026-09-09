import SwiftUI
import SwiftData

struct AddLineItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    let document: ExpenseDocument

    @State private var itemDescription = ""
    @State private var amountText = ""
    @State private var selectedCategoryID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $itemDescription)
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $selectedCategoryID) {
                    Text("None").tag(UUID?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .disabled(itemDescription.trimmingCharacters(in: .whitespaces).isEmpty || Decimal(string: amountText) == nil)
                }
            }
        }
    }

    private func add() {
        guard let amount = Decimal(string: amountText) else { return }
        let category = categories.first { $0.id == selectedCategoryID }
        let nextSortOrder = (document.lineItems.map(\.sortOrder).max() ?? -1) + 1
        let lineItem = LineItem(
            itemDescription: itemDescription.trimmingCharacters(in: .whitespaces),
            unitPrice: amount,
            quantity: 1,
            lineTotal: amount,
            sortOrder: nextSortOrder,
            document: document,
            category: category
        )
        modelContext.insert(lineItem)
        document.lineItems.append(lineItem)
        dismiss()
    }
}
