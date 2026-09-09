import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseDocument.documentDate, order: .reverse) private var documents: [ExpenseDocument]
    @State private var selectedDocument: ExpenseDocument?

    var body: some View {
        NavigationStack {
            List {
                ForEach(documents) { document in
                    Button {
                        selectedDocument = document
                    } label: {
                        row(for: document)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteDocuments)
            }
            .navigationTitle("Expenses")
            .navigationDestination(item: $selectedDocument) { document in
                ItemListView(document: document)
            }
            .overlay {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "receipt",
                        description: Text("Scanned receipts and statements will appear here.")
                    )
                }
            }
        }
    }

    private func row(for document: ExpenseDocument) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(document.merchantName).font(.headline)
                Text(Formatters.shortDate.string(from: document.documentDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.format(document.totalAmount, currencyCode: document.currencyCode))
        }
    }

    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(documents[index])
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
