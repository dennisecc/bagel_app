import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    let lineItem: LineItem

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    lineItem.category = category
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: category.iconSystemName)
                            .foregroundStyle(Color(hex: category.colorHex))
                            .frame(width: 28)
                        Text(category.name)
                        Spacer()
                        if lineItem.category?.id == category.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
