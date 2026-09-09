import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var existingCategories: [ExpenseCategory]

    let category: ExpenseCategory?

    @State private var name: String
    @State private var iconSystemName: String
    @State private var colorHex: String

    private static let iconChoices = [
        "cart.fill", "fork.knife", "car.fill", "bolt.fill", "film.fill", "bag.fill",
        "doc.text.fill", "questionmark.circle.fill", "airplane", "house.fill",
        "heart.fill", "gift.fill", "pawprint.fill", "book.fill"
    ]
    private static let palette = ["#5FAD56", "#F2994A", "#2D9CDB", "#F2C94C", "#BB6BD9", "#EB5757", "#828282", "#9B9B9B"]

    init(category: ExpenseCategory?) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _iconSystemName = State(initialValue: category?.iconSystemName ?? Self.iconChoices[0])
        _colorHex = State(initialValue: category?.colorHex ?? Self.palette.randomElement()!)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(Self.iconChoices, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(icon == iconSystemName ? Color(hex: colorHex) : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .onTapGesture { iconSystemName = icon }
                        }
                    }
                }

                Section("Color") {
                    Picker("Color", selection: $colorHex) {
                        ForEach(Self.palette, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 24, height: 24).tag(hex)
                        }
                    }
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = trimmedName
            category.iconSystemName = iconSystemName
            category.colorHex = colorHex
        } else {
            let nextSortOrder = (existingCategories.map(\.sortOrder).max() ?? -1) + 1
            modelContext.insert(ExpenseCategory(
                name: trimmedName,
                iconSystemName: iconSystemName,
                colorHex: colorHex,
                isSystemDefault: false,
                sortOrder: nextSortOrder
            ))
        }
        dismiss()
    }
}

#Preview {
    CategoryEditView(category: nil)
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
