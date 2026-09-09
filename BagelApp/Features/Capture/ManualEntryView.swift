import SwiftUI
import SwiftData

/// Fallback entry point when capture fails outright: creates a bare `ExpenseDocument`
/// (no line items yet) that the user can then build out from `ItemListView`'s "Add Item".
struct ManualEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let payer: Person?
    let rawOCRText: String
    let onSave: (ExpenseDocument) -> Void

    @State private var merchantName = ""
    @State private var documentDate = Date.now
    @State private var totalAmountText = ""
    @State private var documentType: DocumentType = .receipt

    init(payer: Person?, rawOCRText: String = "", onSave: @escaping (ExpenseDocument) -> Void) {
        self.payer = payer
        self.rawOCRText = rawOCRText
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Merchant", text: $merchantName)
                DatePicker("Date", selection: $documentDate, displayedComponents: .date)
                Picker("Type", selection: $documentType) {
                    Text("Receipt").tag(DocumentType.receipt)
                    Text("Statement").tag(DocumentType.statement)
                }
                TextField("Total Amount", text: $totalAmountText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(merchantName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let document = ExpenseDocument(
            merchantName: merchantName.trimmingCharacters(in: .whitespaces),
            documentDate: documentDate,
            documentType: documentType,
            totalAmount: Decimal(string: totalAmountText) ?? 0,
            rawOCRText: rawOCRText,
            parseStatus: .success,
            payer: payer
        )
        modelContext.insert(document)
        try? modelContext.save()
        dismiss()
        onSave(document)
    }
}

#Preview {
    ManualEntryView(payer: nil) { _ in }
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
