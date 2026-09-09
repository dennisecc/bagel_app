import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.createdAt) private var people: [Person]
    @Bindable var document: ExpenseDocument

    @State private var lineItemToAssign: LineItem?
    @State private var lineItemForCategory: LineItem?
    @State private var isPresentingAddItem = false
    @State private var isPresentingEditDetails = false

    private var sortedItems: [LineItem] {
        document.lineItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// `Picker(selection:)` needs a `Hashable` selection value; going through `Person.id`
    /// rather than binding to `Person` directly sidesteps relying on `@Model`'s synthesized
    /// conformances for this.
    private var payerBinding: Binding<UUID?> {
        Binding(
            get: { document.payer?.id },
            set: { newID in document.payer = people.first { $0.id == newID } }
        )
    }

    var body: some View {
        List {
            Section {
                if document.parseStatus == .needsReview {
                    Label("Double-check these amounts — they didn't perfectly reconcile with the receipt total.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Picker("Paid by", selection: payerBinding) {
                    Text("Nobody").tag(UUID?.none)
                    ForEach(people) { person in
                        Text(person.name).tag(Optional(person.id))
                    }
                }

                HStack {
                    Text("Total")
                    Spacer()
                    Text(Money.format(document.totalAmount, currencyCode: document.currencyCode))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(document.merchantName)
            } footer: {
                Text(Formatters.shortDate.string(from: document.documentDate))
            }

            Section("Items") {
                ForEach(sortedItems) { item in
                    LineItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture { lineItemToAssign = item }
                        .swipeActions(edge: .trailing) {
                            Button {
                                lineItemForCategory = item
                            } label: {
                                Label("Category", systemImage: "tag")
                            }
                            .tint(.indigo)
                        }
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                if sortedItems.isEmpty {
                    Text("No items yet.")
                        .foregroundStyle(.secondary)
                }
            }

            if !people.isEmpty && !sortedItems.isEmpty {
                Section {
                    Button("Assign All to Me") {
                        assignAll(to: people.filter(\.isDefaultOwner))
                    }
                    Button("Split Everything Evenly") {
                        assignAll(to: people)
                    }
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isPresentingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    Button {
                        isPresentingEditDetails = true
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $lineItemToAssign) { item in
            AssignPeopleSheet(lineItem: item, people: people)
        }
        .sheet(item: $lineItemForCategory) { item in
            CategoryPickerSheet(lineItem: item)
        }
        .sheet(isPresented: $isPresentingAddItem) {
            AddLineItemSheet(document: document)
        }
        .sheet(isPresented: $isPresentingEditDetails) {
            EditExpenseDetailsSheet(document: document)
        }
    }

    private func assignAll(to selectedPeople: [Person]) {
        guard !selectedPeople.isEmpty else { return }
        for item in sortedItems {
            AssignmentUpdater.applyEqualSplit(to: item, people: selectedPeople, in: modelContext)
        }
    }

    private func delete(_ item: LineItem) {
        document.lineItems.removeAll { $0.id == item.id }
        modelContext.delete(item)
    }
}

private struct LineItemRow: View {
    let item: LineItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemDescription)
                if let category = item.category {
                    Label(category.name, systemImage: category.iconSystemName)
                        .font(.caption)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Money.format(item.lineTotal))
                AssigneeStack(assignments: item.assignments)
            }
        }
    }
}

private struct AssigneeStack: View {
    let assignments: [ItemAssignment]

    private var accessibilityText: String {
        let names = assignments.compactMap { $0.person?.name }
        return names.isEmpty ? "Unassigned" : "Assigned to \(names.joined(separator: ", "))"
    }

    var body: some View {
        HStack(spacing: -8) {
            ForEach(assignments.prefix(4)) { assignment in
                Circle()
                    .fill(Color(hex: assignment.person?.colorHex ?? "#9B9B9B"))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(assignment.person?.name.prefix(1) ?? "?")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(.background, lineWidth: 1))
            }
            if assignments.isEmpty {
                Text("Unassigned")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

#Preview {
    let container = ModelContainerFactory.makeContainer(inMemory: true)
    let document = ExpenseDocument(
        merchantName: "Preview Cafe",
        documentDate: .now,
        documentType: .receipt,
        totalAmount: 12.5,
        rawOCRText: ""
    )
    container.mainContext.insert(document)
    return NavigationStack {
        ItemListView(document: document)
    }
    .modelContainer(container)
}
